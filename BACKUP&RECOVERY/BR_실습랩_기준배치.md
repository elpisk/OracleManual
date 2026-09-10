# B&R 실습 랩 기준 배치

이 문서는 트랜스크립트가 전제하는 랩의 상태를 적어 둔 것이다.
값은 모두 실제 랩(oel7v9)에서 측정한 것이며, 트랜스크립트의 화면은 이 배치를 따른다.

측정일 2026-09-09 · Oracle 19.3.0 / Oracle Linux 7 / non-CDB `ORCL` / DBID 1767674490

---

## 1. 파일 배치

| 구분 | 경로 |
|---|---|
| 데이터파일 · 템프파일 | `/u01/app/oracle/oradata/orcl/` |
| 컨트롤파일 1, 2번 사본 | `/u01/app/oracle/oradata/orcl/control01.ctl`, `control02.ctl` |
| 컨트롤파일 3번 사본 | `/u02/oradata/orcl/control03.ctl` |
| 온라인 리두 a 멤버 | `/u01/app/oracle/oradata/orcl/redoNN.log` |
| 온라인 리두 b 멤버 | `/u02/oradata/orcl/redoNNb.log` |
| 파라미터 · 패스워드 파일 | `$ORACLE_HOME/dbs/` |
| 백업 보관 | `/home/oracle/backup/...` |

`/u02` 에 두는 것은 **컨트롤파일 3번 사본과 리두 b 멤버뿐**이다.
데이터파일을 `/u02` 에 적어 두면 다중화의 의미가 사라진다.
`/u02` 를 새 위치로 쓰는 실습(8-5, 8-6, 9-2)만 예외이며, 그때도 시작 배치는 `/u01` 이다.

### 온라인 리두 그룹

| 시점 | 그룹 | 크기 |
|---|---|---|
| 초기 | 1, 2, 3 | 각 10M |
| **실습 2-5 이후** | **1, 3, 4** | 1·3 은 10M, 4 는 50M |

실습 2-5 는 그룹 크기를 키우는 절차를 다루면서 그룹 4를 추가하고 **그룹 2를 지운다**.
`ORA-01623`(CURRENT 는 못 지운다)과 `ORA-01624`(ACTIVE 도 못 지운다)를 보이는 것이
그 실습의 핵심이므로, 지운 그룹 2를 다시 만들지 않는다.
`redo02.log`·`redo02b.log` 는 OS 파일까지 삭제한다.

따라서 **3장 이후 모든 시나리오의 전제는 그룹 1, 3, 4** 이며 랩도 그 상태로 둔다.
그룹 번호가 연속하지 않는 것은 정상이다. 34개 트랜스크립트가 `redo04` 를 참조한다.

## 2. 아카이브 구성

| 항목 | 값 |
|---|---|
| `LOG_ARCHIVE_DEST_1` | `location=/home/oracle/arch1 mandatory` |
| `LOG_ARCHIVE_FORMAT` | `arch_%t_%s_%r.arc` |
| 실제 생성되는 파일명 | `arch_1_245_1239893756.arc` |

**대상은 하나다.** 실습 2-2(다중 구성)와 9-5(다중 대상 결손)에서 2·3번 대상을
잠시 쓰지만 실습 끝에서 지운다. 그렇게 하는 이유가 있다.

> `ORA-00289: suggestion :` 은 설정된 아카이브 대상 중 **번호가 가장 큰 것**을 제안한다.
> `ARCHIVE LOG LIST` 의 `Archive destination` 도 같은 값을 보여 준다.
> 대상을 둘로 둔 채 넘어가면 10장 이후의 복구 화면이 전부 어긋난다.

측정으로 확인한 값은 다음과 같다.

```
-- 대상이 하나일 때
ORA-00289: suggestion : /home/oracle/arch1/arch_1_261_1239893756.arc

-- dest_1=/home/oracle/arch1, dest_2=/home/oracle/arch2 일 때
ORA-00289: suggestion : /home/oracle/arch2/arch_1_256_1239893756.arc
```

`ORA-00308` 로 멈추면 그 `RECOVER` 세션은 끝난다. 프롬프트가 이어지지 않으므로
`RECOVER` 를 다시 실행해야 하며, 다시 실행하면 실패했던 시퀀스부터 시작한다.

### 인카네이션과 아카이브 파일명

`OPEN RESETLOGS` 를 지나면 인카네이션이 바뀐다. 그때 **로그 시퀀스는 1부터 다시
시작하고, 아카이브 파일명의 리셋 스탬프(`%r`)도 새 값이 된다.** 트랜스크립트의
아카이브 이름은 이 사슬을 따른다.

| 구간 | `%r` | 시퀀스 |
|---|---|---|
| 2~3장 | 1200525254 | 이어짐 |
| 7·9장·10-1 | 1200533800 | 1부터 |
| 10-3 / 10-4 / 10-6·10-7 | 1200548120 / 1200553402 / 1200562204 | 각 1부터 |
| 11-2 / 11-3·11-5·11-7 / 11-8 | 1200574102 / 1200576220 / 1200580210 | 각 1부터 |
| 12장 | 1200584500 | 1부터 |
| 13장 ~ 15-8 앞 | 1200592300 | 이어짐 |
| 15-8 ① / ② 뒤 | 1200596400 / 1200597900 | 각 1부터 |
| 15-9 뒤 | 1200601800 | 1부터 |
| 15-10 ① / ② 뒤 | 1200604500 / 1200606000 | 각 1부터 |
| 17장 복제본 | 1200621700 | 1부터 |
| 고급실습 | 1200705400 / 1200712900 | — |

값은 시간을 따라 커진다. 랩 실측(`%r` 1239893756 = `RESETLOGS_TIME` 2026-07-29
14:55:56)으로 역산해 뒤로 가는 값이 없도록 맞춘 것이다.

`%r` 은 **DBID 와 다른 값**이다. ORCL 의 DBID 는 `1200530011` 이며 바뀌지 않는다.
`LIST INCARNATION` 의 `DB ID` 열에는 DBID 가, 아카이브 파일명에는 `%r` 이 들어간다.

예외가 둘 있다. `RESET DATABASE TO INCARNATION` 으로 옛 인카네이션에 되돌아간 뒤에는
그 인카네이션의 `%r` 을 쓴다(15-10). `DELETE EXPIRED ARCHIVELOG` 나 `CROSSCHECK` 가
찍는 이름은 적용이 아니라 남아 있는 기록이므로 옛 `%r` 일 수 있다(10-4).

### 데이터파일 대장

장을 순서대로 진행하면 대장은 이렇게 변한다. 각 장의 목록·개수 출력은 이 표를 따른다.

| 시점 | 파일 | 개수 |
|---|---|---|
| 4~7장 | 1 system01, 3 sysaux01, 4 undotbs01, 7 users01 | 4 |
| 8-2 뒤 | + 10 hist01 | 5 |
| 8-4 뒤 | + 11 tbs01 | 6 |
| 8-5 뒤 | + 12 tbs02 | 7 |
| **9장 마친 뒤 ~ 11-8 앞** | 1, 3, 4, 7, 10, 11, 12 | **7** |
| 11-8 뒤 | 12 tbs02 빠지고 13 tbs11 들어옴 | 7 |
| **12장** | 1, 3, 4, 7, 10, 11, 13 | **7** |

앞 장이 남긴 것을 뒷 장이 전제하므로, 각 실습은 자기가 바꾼 것을 되돌린다.

* 5-5 는 `hist` 를 지운다. 남기면 8-2 의 `CREATE TABLESPACE hist` 가
  `ORA-01543: tablespace 'HIST' already exists` 로 막힌다.
* 8-5·8-6 은 `/u02` 로 옮긴 파일을 `MOVE DATAFILE` 로 되돌린다.
* 9-2 는 7개를 `/u02` 로 옮겼다가 모두 되돌린다.
* 9-4 는 UNDO 를 `UNDOTBS2` 로 전환했다가 `UNDOTBS1` 로 되돌리고 `UNDOTBS2` 를 지운다.
  Oracle 은 비어 있는 가장 낮은 파일 번호를 다시 쓰므로 새 `undotbs01` 이 4번을 되받는다(실측).

## 3. 파일을 지울 때의 순서

데이터파일을 지우는 장애 유발에는 **순서가 있다.**

```
ALTER SYSTEM FLUSH BUFFER_CACHE;     -- 먼저 비운다
!rm -f <데이터파일>                    -- 그 다음에 지운다
SELECT ... ;                          -- ORA-01116 이 난다
```

거꾸로 하면 인스턴스가 죽는다. 랩에서 실측한 결과다.

```
-- 더티 버퍼가 남은 채 파일을 지우고 쓰기를 시도했을 때 (alert log)
ORA-63999: data file suffered media failure
ORA-01116: error in opening database file 10
ORA-01110: data file 10: '/u01/app/oracle/oradata/orcl/tbs01.dbf'
ORA-27041: unable to open file
Linux-x86_64 Error: 2: No such file or directory
Additional information: 3
...
USER (ospid: ): terminating the instance due to ORA error
Instance terminated by USER, pid = 10440        ← CKPT
```

`FLUSH BUFFER_CACHE` 뿐 아니라 평범한 `ALTER SYSTEM CHECKPOINT` 로도 같다.
19c 는 `_datafile_write_errors_crash_instance` 가 기본 TRUE 라서, 데이터파일
쓰기 실패를 만나면 손상을 넓히지 않으려고 인스턴스를 내린다.

더티 버퍼를 먼저 없애 두면 남는 것은 읽기 실패뿐이라 인스턴스가 버틴다.

```
SYS@orcl> SELECT COUNT(*) FROM hr.emp85;
ERROR at line 1:
ORA-01116: error in opening database file 10
ORA-01110: data file 10: '/u01/app/oracle/oradata/orcl/tbs01.dbf'
ORA-27041: unable to open file
Linux-x86_64 Error: 2: No such file or directory
Additional information: 3
```

`ORA-27041`(열기 실패)에는 `Additional information: 3`,
`ORA-27037`(상태 조회 실패)에는 `Additional information: 7` 이 붙는다.

## 4. 복구 실습의 명령 순서

랩에서 실측해 확정한 규칙이다.

**내린 것은 명시적으로 올린다.**
`RECOVER DATABASE` 는 OFFLINE 데이터파일을 건너뛴다. 내려간 파일만 남으면
`ORA-00264: no recovery required` 로 끝난다. MOUNT 에서
`ALTER DATABASE DATAFILE n ONLINE` 을 먼저 해야 복구 대상에 들어온다.
그리고 파일이 ONLINE 이 되어도 테이블스페이스는 그대로 OFFLINE 이다.

```
SYS@orcl> SELECT COUNT(*) FROM hr.t10;
ORA-00376: file 10 cannot be read at this time
ORA-01110: data file 10: '/u01/app/oracle/oradata/orcl/t10_01.dbf'
```

`ALTER TABLESPACE x ONLINE` 까지 해야 읽힌다. READ ONLY 로 연 상태에서는
그 명령이 `ORA-16000: database or pluggable database open for read-only access`
로 거부되므로, 데이터 확인은 RESETLOGS 로 연 뒤에 한다.

**템프파일은 함부로 다시 만들지 않는다.**
`OPEN RESETLOGS` 는 템프파일 기록을 지우지 않는다. 이미 있는 파일을 다시 추가하면

```
ORA-01537: cannot add file '...temp01.dbf' - file already part of database
```

`CREATE CONTROLFILE` 로 컨트롤파일을 다시 만든 경우에만 템프파일이 사라진다.
그때만 `ALTER TABLESPACE temp ADD TEMPFILE` 이 성립한다.

**AUTORECOVERY 를 켜지 않으면 프롬프트가 뜬다.**
SQL*Plus 기본값은 OFF 다. `UNTIL TIME` · `UNTIL CHANGE` · `UNTIL SEQUENCE` 모두
로그마다 `Specify log:` 를 묻는다. 프롬프트 없이 `Media recovery complete.` 로
끝나려면 앞에 `SET AUTORECOVERY ON` 이 있어야 한다.

## 5. 계정과 소유권

`oracle` 의 주 그룹은 **`dba`** 다(`uid=1000(oracle) gid=54322(dba) groups=54322(dba),54321(oinstall)`).
따라서 데이터베이스가 만든 파일은 `ls -l` 에서 `oracle dba` 로 보인다.
`oracle oinstall` 로 보이는 것은 root 가 그렇게 바꿔 둔 디렉터리뿐이다
(`/archsmall`, `/u03/dpdump`, `/u03/dpdump_bad`, `/archive_keep`).

## 6. 감독자 사전 준비 (root)

`/` 는 `dr-xr-xr-x root root` 이므로 **oracle 계정은 최상위 디렉터리를 만들 수 없다.**
아래는 랩을 배포하기 전에 root 로 한 번 해 두어야 한다.

```bash
# 실습이 새 위치로 쓰는 마운트 포인트
mkdir -p /u03 /u04
chown oracle:dba /u03 /u04
chmod 755 /u03 /u04

# 아카이브와 FRA 는 별도 볼륨을 쓴다
ls -ld /arch /fra          # 이미 마련되어 있어야 한다
```

이 아래의 하위 디렉터리(`/u03/arch2`, `/u03/oradata/ORCL`, `/u04/clone/arch` 등)는
각 실습이 oracle 계정으로 직접 만든다.

### 리스너

13장부터 `@rcat`, `@NEWDB` 같은 네트워크 접속을 쓴다. 리스너가 떠 있어야 한다.

```bash
lsnrctl start          # oracle 계정
```

12장까지는 리스너를 쓰지 않는다. 그 장들의 두 번째 세션은 `sqlplus hr/hr` 로
로컬 접속한다. 리스너가 내려간 상태에서 `sqlplus hr/hr@orcl` 을 쓰면
`ORA-12541: TNS:no listener` 로 막힌다(실측).

## 7. 장별 아카이브 모드 전제

| 장 | 모드 | 비고 |
|---|---|---|
| 1장 | 해당 없음 | 개요 |
| 2장 | NOARCHIVELOG → ARCHIVELOG | 전환 실습. 여기서 위 2번 구성을 잡는다 |
| 3~7장 | NOARCHIVELOG | 4~7장 시나리오를 위해 잠시 되돌린다 |
| 8장 이후 | ARCHIVELOG | 2장의 구성을 그대로 쓴다 |

## 8. 점검 도구

트랜스크립트는 기계 검사를 통과한 상태로 유지한다. 검사기는 `_rac_scratch/` 에 있다.

| 스크립트 | 잡는 것 |
|---|---|
| `_br_verify.py` | A~F : SCN 역전, 시각 모순, errno 모순, 날짜 표기 뒤집힘(`13/05` 는 `05/13`) 등 |
| `_br_proc.py` | G : 상태(DOWN/NOMOUNT/MOUNT/OPEN)에서 실행할 수 없는 명령<br>H : `RENAME FILE` · `RECOVER TABLESPACE/DATAFILE` 앞의 OFFLINE 누락<br>P : 데이터파일을 지운 뒤 쓰기 시도 |
| `_br_base.py` | L : 기준 배치와 다른 경로<br>M : 없는 아카이브 경로, 실측과 다른 아카이브 파일명<br>O : OPEN RESETLOGS 를 지나고도 그대로인 `%r` |
| `_br_align.py` | N : SQL*Plus 출력 표의 열 정렬 |
| `_br_seq.py` | Q : OFFLINE 뒤 ONLINE 누락<br>R : 컨트롤파일을 그대로 둔 채 ADD TEMPFILE<br>S : AUTORECOVERY OFF 인데 프롬프트 없이 끝나는 복구 |

```
python _br_verify.py "*/*.txt"
python _br_proc.py   "*/*.txt"
python _br_base.py   "*/*.txt"
```
