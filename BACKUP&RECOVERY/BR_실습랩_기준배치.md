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

## 3. 계정과 소유권

`oracle` 의 주 그룹은 **`dba`** 다(`uid=1000(oracle) gid=54322(dba) groups=54322(dba),54321(oinstall)`).
따라서 데이터베이스가 만든 파일은 `ls -l` 에서 `oracle dba` 로 보인다.
`oracle oinstall` 로 보이는 것은 root 가 그렇게 바꿔 둔 디렉터리뿐이다
(`/archsmall`, `/u03/dpdump`, `/u03/dpdump_bad`, `/archive_keep`).

## 4. 감독자 사전 준비 (root)

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

## 5. 장별 아카이브 모드 전제

| 장 | 모드 | 비고 |
|---|---|---|
| 1장 | 해당 없음 | 개요 |
| 2장 | NOARCHIVELOG → ARCHIVELOG | 전환 실습. 여기서 위 2번 구성을 잡는다 |
| 3~7장 | NOARCHIVELOG | 4~7장 시나리오를 위해 잠시 되돌린다 |
| 8장 이후 | ARCHIVELOG | 2장의 구성을 그대로 쓴다 |

## 6. 점검 도구

트랜스크립트는 기계 검사를 통과한 상태로 유지한다. 검사기는 `_rac_scratch/` 에 있다.

| 스크립트 | 잡는 것 |
|---|---|
| `_br_verify.py` | A~F : SCN 역전, 시각 모순, errno 모순, 날짜 표기 뒤집힘 등 |
| `_br_proc.py` | G : 상태(DOWN/NOMOUNT/MOUNT/OPEN)에서 실행할 수 없는 명령<br>H : `RENAME FILE` · `RECOVER TABLESPACE/DATAFILE` 앞의 OFFLINE 누락 |
| `_br_base.py` | L : 기준 배치와 다른 경로<br>M : 없는 아카이브 경로, 실측과 다른 아카이브 파일명 |
| `_br_align.py` | N : SQL*Plus 출력 표의 열 정렬 |

```
python _br_verify.py "*/*.txt"
python _br_proc.py   "*/*.txt"
python _br_base.py   "*/*.txt"
```
