# OL7ADMIN 실습 스크립트

실습 VM(`ol7a` 172.16.225.61, `ol7b` 172.16.225.62)을 준비하고, 디스크 실습 전에 상태를 점검하고, 18장·최종실습시험의 부하를 만드는 스크립트다. 내용은 제작 때 `_ol7_scratch/labs/` 의 `.lab` 에서 실제로 친 준비 명령을 모은 것이다. 계정 암호는 스크립트에 넣지 않았다.

| 폴더 | 파일 | 어디서 | 하는 일 | 쓰는 장 |
|---|---|---|---|---|
| `host/` | `add-lab-disks.ps1` | Windows 호스트 | 꺼진 VM 의 .vmx 에 10GB 디스크 4개(scsi0:1~4), 두 번째 NIC, 직렬 콘솔 파이프를 붙임 | 2장 VM 준비 |
| | `lab-snapshot.ps1` | Windows 호스트 | `vmrun` 으로 스냅샷 목록·되돌리기·만들기. 되돌리기 전에 D: 여유 15GB 를 확인 | 전체 |
| `vm/` | `prepare-base.sh` | ol7a·ol7b root | os-installed → 기준 상태: `/etc/hosts`, chronyd, `yum update`, 직렬 콘솔·`scsi_mod.scan=sync` | 2장 끝 |
| | `make-ks-ol7b.sh` | ol7a root | `anaconda-ks.cfg` 를 고쳐 ol7b kickstart 를 만들고 `ksvalidator` 검사 뒤 8000 포트로 내보냄 | 2장 04 |
| | `check-lab-disks.sh` | ol7a root | OS 디스크가 sda(HCTL 2:0:0:0)인지, sdb~sde 가 비었는지 점검. 어긋나면 종료 코드 1 | 9~12·20장 |
| | `wipe-lab-disks.sh` | ol7a root | 마운트·스왑·md·LVM·서명을 차례로 걷어 내고 다시 점검 | 9~12장 |
| `load/` | `cpu-load.sh` | ol7a root | 셸 루프로 CPU 부하 | 18장 01·04, 시험 05 |
| | `mem-load.sh`, `memhog.py` | ol7a root | 이름이 다른 세 프로세스(dbsim·batch·runaway)로 메모리 압박·스왑·OOM | 18장 02 |
| | `io-load.sh` | ol7a root | `dd` 직접 I/O 쓰기·읽기 | 18장 03·04, 시험 05 |
| | `lock-wait.sh` | ol7a root | `flock` 으로 잠금을 쥔 프로세스와 기다리는 프로세스 | 18장 05, 시험 05 |
| | `stop-load.sh` | ol7a root | 위 부하를 모두 멈추고 파일 정리 | — |

## 처음 준비하는 순서

1. VMware 에서 ol7a(4GB/2vCPU, 40GB), ol7b(2GB/1vCPU, 30GB) VM 을 만들고 끈 채로 `host\add-lab-disks.ps1 -Vmx D:\OL7LAB\ol7a\ol7a.vmx` (ol7b 는 `-Count 0 -NoNic`).
2. ol7a 를 ISO 로 설치(2장 실습 02) → 끄고 `lab-snapshot.ps1 take ol7a os-installed`.
3. ol7a 에서 `vm/make-ks-ol7b.sh` → ol7b 를 kickstart 로 설치(2장 실습 04).
4. 두 노드에서 `vm/prepare-base.sh` → 재부팅 → `vm/check-lab-disks.sh`(ol7a) 통과 확인.
5. 끄고 스냅샷: ol7a `ol7-base`·`storage-clean`·`pre-break`, ol7b `ol7b-base`.

## 쓸 때 주의

- 부하 스크립트는 `nohup ... &` 를 한 줄에 따로 둔다. 원격 실행기에서 `cd ... && nohup ...` 처럼 앞에 명령을 붙이면 서브셸이 출력 채널을 잡아 세션이 멈춘다.
- `dd`·`fallocate` 로 쓰는 파일은 1~2GB 이내로 잡는다. VM 의 델타 디스크가 그만큼 커지고, 호스트 D: 가 차면 VM 이 디스크 부족 질문에서 멈춘다.
- 디스크를 건드리는 실습은 `check-lab-disks.sh` 부터 돌린다. UEK 의 비동기 SCSI 스캔 때문에 OS 디스크가 `sdb` 로 잡힌 적이 있다.
- SELinux 는 enforcing 그대로 둔다. 스크립트도 `setenforce` 를 쓰지 않는다.
