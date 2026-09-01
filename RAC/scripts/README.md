# Oracle 19c RAC 2노드 구축 스크립트

`RAC_Install_Guide_rac1_rac2.docx` 의 내용을 그대로 실행 가능한 형태로 옮긴 것이다.
가이드를 읽으며 손으로 따라 해도 되고, 이 스크립트로 돌려도 결과가 같다.

## 구성

```
scripts/
  config.env            모든 값이 여기 모여 있다. 바꾸려면 여기만 고친다.
  run_all.py            호스트에서 SSH 로 노드 단계를 순서대로 돌리는 오케스트레이터
  host/                 Windows 호스트에서 실행 (VMware)
    01_create_shared_disks.ps1   공유 vmdk 8개 생성 (96GB)
    02_clone_vms.ps1             기준 이미지에서 링크드 클론 2대
    03_patch_vmx.ps1             사설 NIC + 공유 SCSI 버스 설정
    90_snapshot.ps1              기준 스냅샷 (-BackupShared 로 공유 디스크도 백업)
  node/                 노드에서 실행 (Oracle Linux)
    10_os_setup.sh               호스트명·IP·hosts·그룹·커널·limits·디렉터리
    11_ssh_equivalence.sh        grid/oracle SSH 등가성
    12_udev_asmdisk.sh           WWN 기준 /dev/asmdisk/* 이름 고정
    13_prereq_fix.sh             cluvfy 가 잡는 항목 5종 + 인벤토리 그룹
    14_cluvfy.sh                 설치 전 점검
    20_gi_install.sh             Grid Infrastructure 무인 설치
    21_root_sh.sh                root.sh (노드 순서 강제)
    30_db_software.sh            DB 소프트웨어 SWONLY 설치
    40_diskgroups.sh             +DATA / +FRA 생성·마운트
    41_dbca.sh                   RAC 데이터베이스 생성, PDB 상태 저장
    50_postcheck.sh              최종 구성 체크리스트 자동 검사
  templates/
    gridsetup.rsp.tmpl           GI 응답 파일 (변수 치환)
    db.rsp.tmpl                  DB 응답 파일
```

## 비밀번호

스크립트에 비밀번호를 적지 않는다. 환경 변수로 넘긴다.

| 변수 | 쓰이는 곳 |
|---|---|
| `RAC_OS_PW` | run_all.py 의 SSH 접속(root) |
| `RAC_ASM_PW` | GI 설치의 SYSASM / ASMSNMP |
| `RAC_SYS_PW` | DBCA 의 SYS / SYSTEM / PDBADMIN, SCAN 접속 확인 |

`20_gi_install.sh` 는 응답 파일을 `600` 권한으로 만들고 설치가 끝나면 `shred` 로 지운다.

## 실행 순서

### 1) 호스트 (PowerShell)

```powershell
cd RAC\scripts\host
powershell -ExecutionPolicy Bypass -File 01_create_shared_disks.ps1
powershell -ExecutionPolicy Bypass -File 02_clone_vms.ps1
powershell -ExecutionPolicy Bypass -File 03_patch_vmx.ps1
# 두 VM 을 기동한다
```

### 2) 노드 — 오케스트레이터로 한 번에

```
pip install paramiko
set RAC_OS_PW=...
set RAC_ASM_PW=...
set RAC_SYS_PW=...

python run_all.py list          단계 확인
python run_all.py run 10        한 단계씩 (권장)
python run_all.py all           전체
```

`10` 단계 뒤에는 IP 적용을 위해 재부팅이 필요하다. **두 노드를 동시에 만지지 않는다** —
링크드 클론은 DHCP 임대를 물려받아 같은 주소를 잡는 일이 있다.

### 3) 노드 — 직접 실행

`run_all.py` 없이 노드에 올려 직접 돌려도 된다. 각 스크립트는 `config.env` 를
상대 경로로 읽으므로 폴더 구조만 유지하면 된다.

```bash
scp -r scripts oracle@rac1:/tmp/rac_scripts
ssh root@rac1
cd /tmp/rac_scripts
bash node/10_os_setup.sh 1
```

### 4) 마무리

```powershell
# 데이터베이스·CRS 정지 후 전원을 내린 다음
powershell -ExecutionPolicy Bypass -File host\90_snapshot.ps1 -Name rac-base
```

## 알아 둘 것

- **root.sh 는 순서가 있다.** 첫 노드가 끝난 뒤 두 번째 노드에서 실행한다.
  첫 노드의 root.sh 가 OCR 과 보팅 파일을 초기화하므로 동시에 돌리면 충돌한다.
  `21_root_sh.sh` 가 두 번째 노드에서 확인을 요구한다.
- **스냅샷은 OS 디스크만 덮는다.** 공유 디스크는 `independent-persistent` 라
  스냅샷 대상에서 빠진다. OCR·보팅 파일·ASM·데이터베이스까지 되돌리려면
  `90_snapshot.ps1 -BackupShared` 로 `D:\RAC\SHARED` 를 함께 복사한다.
- **cluvfy 실패를 남긴 채 진행하지 않는다.** 설치 중간 실패를 되돌리는 비용이
  훨씬 크다. `13_prereq_fix.sh` 가 실제로 걸렸던 다섯 항목을 처리한다.
- **재실행 안전.** 각 스크립트는 이미 되어 있는 항목을 건너뛴다.
