# Active Data Guard 구축 스크립트 (chicago / boston)

`ADG_Install_Guide_Chicago_Boston.docx` 의 내용을 실행 가능한 형태로 옮긴 것이다.
OMF 방식은 `config.env` 에서 경로를 바꾸고 `dup_standby.rman.tmpl` 의
`db_file_name_convert` / `log_file_name_convert` 대신 `db_create_file_dest` 를 쓰면 된다.

## 구성

```
scripts/
  config.env            모든 값이 여기 모여 있다.
  run_all.py            호스트에서 SSH 로 두 서버의 단계를 순서대로 돌린다.
  node/
    10_primary_prepare.sh   ARCHIVELOG · FORCE LOGGING · Standby Redo Log
    11_net_config.sh        tnsnames.ora / listener.ora 배포, 리스너 재기동, TNS 확인
    12_dg_params.sh         FRA · log_archive_config · dest_2 · fal_* · SFM
    20_standby_build.sh     pwfile | nomount | duplicate | watch | post
    30_verify.sh            primary | standby | gap
    90_startstop.sh         랩 기동·정지, MRP on/off
  templates/
    tnsnames.ora.tmpl
    listener_primary.ora.tmpl
    listener_standby.ora.tmpl
    dup_standby.rman.tmpl   RMAN DUPLICATE ... FROM ACTIVE DATABASE
```

## 비밀번호

| 변수 | 쓰이는 곳 |
|---|---|
| `ADG_OS_PW` | run_all.py 의 SSH 접속(oracle) |
| `ADG_SYS_PW` | RMAN DUPLICATE 의 target / auxiliary 접속 |

## 실행

```
pip install paramiko
set ADG_OS_PW=...
set ADG_SYS_PW=...

python run_all.py list
python run_all.py run 10 11p 11s 11v 12
python run_all.py run 20 21 22        # DUPLICATE 는 백그라운드로 뜬다
python run_all.py run 22w             # 진행 감시
python run_all.py run 23 30p 30s
```

직접 실행할 수도 있다.

```bash
scp -r scripts oracle@chicago-srv:~/adg_scripts
ssh oracle@chicago-srv
cd ~/adg_scripts
bash node/10_primary_prepare.sh
```

## 알아 둘 것

- **Standby 리스너의 정적 등록이 필수다.** RMAN DUPLICATE 는 Standby 가 NOMOUNT 인
  상태에서 접속하는데, 동적 등록은 인스턴스가 열려야 이루어진다. 정적 항목이
  없으면 `ORA-12514` 로 막힌다. `listener_standby.ora.tmpl` 이 이를 담고 있다.
- **패스워드 파일은 같아야 한다.** 이름만 SID 에 맞춰 바꿔 복사한다(`20 pwfile`).
  다르면 리두 전송 인증이 통과하지 못한다.
- **Standby Redo Log 는 온라인 리두 그룹 수 + 1 개**를 같은 크기로 만든다.
  실시간 적용의 조건이고, 역할 전환 뒤 Primary 가 될 때도 쓰인다.
- **`USING CURRENT LOGFILE` 이 실시간 적용을 켠다.** 빼면 아카이브가 완성된
  뒤에야 적용되어 지연이 생긴다.
- **DUPLICATE 는 오래 걸린다(10~25분).** 백그라운드로 띄우고 `watch` 로 본다.
  SSH 세션을 붙들고 기다리면 세션이 끊길 때 죽은 것처럼 보인다.

## 랩 운영

```bash
bash node/90_startstop.sh up      # Primary open → Standby read only + MRP
bash node/90_startstop.sh down    # MRP 정지 → 양쪽 shutdown immediate
bash node/30_verify.sh gap        # 적용 지연만 빠르게
```
