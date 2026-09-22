# B&R 실습 환경 설치 가이드

Oracle Database 19c Backup & Recovery 과정(1~19장 · 실기평가 · 종합실습과제)과
Recovery Catalog 고급 실습(01~10)을 그대로 따라갈 수 있는 실습 환경을 만드는 절차다.

교안의 화면은 `BR_실습랩_기준배치.md` 의 배치를 전제한다. 이 가이드는 그 배치를 **설치 직후 상태**로
만들고, 교안이 스스로 만드는 것(아카이브 대상, 컨트롤파일 3번, 리두 b 멤버, FRA, 로컬 카탈로그)은
건드리지 않는다. 무엇을 설치 때 만들고 무엇을 교안이 만드는지는 [7절 대조표](#7-교안이-만드는-것과-설치-때-만드는-것)에 있다.

| 구분 | 서버 | 인스턴스 | 언제 필요한가 |
|---|---|---|---|
| 기본 과정 (1~19장, 실기평가, 종합실습과제) | oel7v9 (운영계) | orcl | 처음부터 |
| 고급 실습 01~10 | oel7v9 | orcl + **sales** | 고급 실습 시작 전 (8절) |
| | **oel7v9r2** (관리계/DR) | **rcat + hrdb** | 고급 실습 시작 전 (8절) |

기본 과정만 할 것이면 1~7절까지만 하면 된다. 서버 두 대는 고급 실습에서만 필요하다.

> 이 가이드의 dbca 파일 배치(`<대상 디렉터리>/<DB이름 대문자>/`, 컨트롤파일 2개 같은 디렉터리,
> 리두 200M×3, TEMP 20M)는 2026-09-22 에 19.3 랩에서 `dbca -generateScripts` 로 확인한 값이다.
> 나머지 명령은 Oracle Linux 7.9 + 19.3 표준 절차다.

---

## 1. 하드웨어와 디스크

VMware Workstation 기준. 두 서버 모두 같은 규격으로 만들면 07·10 의 재해복구 훈련이 편하다.

| 항목 | oel7v9 | oel7v9r2 (고급 실습만) |
|---|---|---|
| CPU | 4 코어 | 4 코어 |
| 메모리 | 8 GB (기본 과정) / 16 GB (고급 실습, orcl 2G + sales 1.5G) | 16 GB 권장, 최소 12 GB (rcat 1G + hrdb 1.5G + 복구용 2G) |
| OS | Oracle Linux 7.9 (Server with GUI 또는 Minimal + X 불필요) | 동일 |
| 네트워크 | 고정 IP, 두 서버 간 1521·22 개방 | 동일 |

디스크는 **역할별로 나눈다.** `/u02` 가 `/u01` 과 같은 디스크면 컨트롤파일·리두 다중화 실습(2장)의
의미가 없어진다. 마운트 포인트 이름은 교안 화면에 그대로 나오므로 바꾸지 않는다.

| 마운트 | 크기 | 용도 (교안에서 쓰는 곳) | oel7v9 | oel7v9r2 |
|---|---|---|---|---|
| `/` + swap | 40 GB + 8 GB | OS, `/home/oracle` (백업·아카이브·rmanbk·exam 이 여기 생긴다 — 넉넉히) | ○ | ○ |
| `/u01` | 60 GB | ORACLE_HOME, `oradata/orcl` 데이터파일, FRA(2장) | ○ | ○ |
| `/u02` | 30 GB | 컨트롤파일 3번·리두 b 멤버(2장), 새 위치 복구(8·9·15장), 로컬 rcat(13장) | ○ | **60 GB** (07 의 DR 복구 대상 `/u02/oradata/sales`) |
| `/u03` | 30 GB | Data Pump(`/u03/dpdump`, 19장), 보조 인스턴스(`/u03/aux`, 16장), 2번 아카이브 대상(`/u03/arch2`, 9장) | ○ | — |
| `/fra` | 30 GB | 9·13·18장이 FRA 로 쓰는 위치 | ○ | — |
| `/archive_keep` | 30 GB | KEEP 장기 보관 (고급 06) | ○ | — |
| `/export` | 20 GB | 암호화 반출 (고급 09) | ○ | — |
| `/backup` | 100 GB | RMAN 백업 (고급 03~10). **oel7v9r2 가 원본, oel7v9 는 NFS 마운트** | (NFS) | ○ (export) |

기본 과정만 할 것이면 `/archive_keep` `/export` `/backup` 은 만들지 않아도 된다.
디스크를 나누기 어려우면 `/` 를 200 GB 로 잡고 디렉터리로 만들어도 실습은 된다(다중화의 의미만 잃는다).

xfs 로 만들고 `/etc/fstab` 에 UUID 로 등록한다.

```bash
# 예 : /dev/sdb 를 /u01 로
parted -s /dev/sdb mklabel gpt mkpart primary xfs 1MiB 100%
mkfs.xfs /dev/sdb1
mkdir -p /u01
echo "UUID=$(blkid -s UUID -o value /dev/sdb1) /u01 xfs defaults 0 2" >> /etc/fstab
mount -a && df -h /u01
```

---

## 2. OS 준비 (두 서버 공통)

### 2-1. 호스트 이름과 hosts

교안의 프롬프트는 `[oracle@oel7v9 ~]$` 와 `[oracle@oel7v9r2 ~]$` 다. 종합실습과제·고급실습 과정안내의
`oel7v9r1` 은 `oel7v9` 와 같은 서버를 가리킨다.

```bash
hostnamectl set-hostname oel7v9          # 두 번째 서버는 oel7v9r2
cat >> /etc/hosts <<'EOF'
192.168.56.101   oel7v9   oel7v9r1
192.168.56.102   oel7v9r2
EOF
```

IP 는 자기 환경에 맞춘다. 두 서버가 서로 이름으로 ping 되어야 한다.

### 2-2. 시간대와 시각

두 서버를 **같은 시간대**로 맞춘다. 서로 다르면 카탈로그의 시각 비교(고급 02·08)가 어긋난다.

```bash
timedatectl set-timezone Asia/Seoul
systemctl enable --now chronyd
```

### 2-3. 패키지, 커널 파라미터, oracle 사용자

`oracle-database-preinstall-19c` 가 커널 파라미터·limits·oracle 사용자(그룹 oinstall, dba, oper,
backupdba, dgdba, kmdba, racdba)를 만든다.

```bash
yum install -y oracle-database-preinstall-19c unzip bc nfs-utils
passwd oracle                              # 비밀번호 oracle (교안은 su - oracle 로만 쓴다)
systemctl disable --now firewalld          # 또는 1521/2049(NFS) 개방
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config && setenforce 0
```

### 2-4. 디렉터리

```bash
mkdir -p /u01/app/oracle/product/19.3.0/dbhome_1 /u01/app/oraInventory
mkdir -p /u01/app/oracle/oradata /u02/oradata /u03/dpdump /u03/arch2 /u03/aux /fra
chown -R oracle:oinstall /u01 /u02 /u03 /fra
chmod -R 775 /u01 /u02 /u03 /fra
```

`/u01/app/oracle/oradata` 는 **oracle 소유**여야 한다. root 소유면 dbca 가 `DBT-06006 Unable to create directory` 로 멈춘다.

### 2-5. oracle 사용자 환경

`/home/oracle/.bash_profile` 끝에 추가한다. 두 번째 서버는 `ORACLE_SID=rcat` 으로 둔다.

```bash
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
umask 022
```

`NLS_DATE_FORMAT` 은 교안의 RMAN 화면(`2025-05-12 13:05:00` 형식)과 `SET UNTIL TIME` 입력에 필요하다.

---

## 3. 19c 소프트웨어 설치 (두 서버 공통)

`LINUX.X64_193000_db_home.zip` 을 oracle 사용자로 ORACLE_HOME 에 푼다 (19c 는 zip 이 곧 홈이다).

```bash
su - oracle
unzip -q /stage/LINUX.X64_193000_db_home.zip -d $ORACLE_HOME
cd $ORACLE_HOME
./runInstaller -silent -waitForCompletion \
  oracle.install.option=INSTALL_DB_SWONLY \
  ORACLE_HOSTNAME=$(hostname) \
  UNIX_GROUP_NAME=oinstall \
  INVENTORY_LOCATION=/u01/app/oraInventory \
  ORACLE_HOME=$ORACLE_HOME \
  ORACLE_BASE=$ORACLE_BASE \
  oracle.install.db.InstallEdition=EE \
  oracle.install.db.OSDBA_GROUP=dba \
  oracle.install.db.OSOPER_GROUP=oper \
  oracle.install.db.OSBACKUPDBA_GROUP=backupdba \
  oracle.install.db.OSDGDBA_GROUP=dgdba \
  oracle.install.db.OSKMDBA_GROUP=kmdba \
  oracle.install.db.OSRACDBA_GROUP=racdba \
  DECLINE_SECURITY_UPDATES=true
```

끝에 안내하는 두 스크립트를 root 로 실행한다.

```bash
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/19.3.0/dbhome_1/root.sh
```

### 3-1. SQL*Plus 프롬프트

교안의 `SYS@orcl>` 프롬프트를 만든다. `$ORACLE_HOME/sqlplus/admin/glogin.sql` 에 추가한다.

```sql
SET SQLPROMPT "_USER'@'_CONNECT_IDENTIFIER> "
SET LINESIZE 200 PAGESIZE 100
```

### 3-2. 리스너

`$ORACLE_HOME/network/admin/listener.ora` 를 직접 만든다. **정적 등록(SID_LIST)** 을 넣어 둔다 —
13장(로컬 rcat), 17장(DUPLICATE 의 NOMOUNT 보조 인스턴스), 고급 07·10(DR) 이 NOMOUNT 인스턴스에
접속하므로 동적 등록만으로는 `ORA-12514` 가 난다.

```
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = oel7v9)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = orcl)
      (ORACLE_HOME = /u01/app/oracle/product/19.3.0/dbhome_1)
      (SID_NAME = orcl)
    )
  )
```

oel7v9r2 는 HOST 를 `oel7v9r2`, SID_DESC 를 `rcat` 과 `hrdb` 로 둔다. 13장 실습 2 에서 로컬 rcat 의
SID_DESC 를 추가하는 절차가 교안에 있으므로 oel7v9 에는 orcl 만 넣는다.

```bash
lsnrctl start
```

`tnsnames.ora` 는 dbca 가 orcl 항목을 만든다. 고급 실습용 항목은 8-6 에서 넣는다.

---

## 4. orcl 생성 (oel7v9)

### 4-1. dbca

```bash
dbca -silent -createDatabase \
  -templateName General_Purpose.dbc \
  -gdbName orcl -sid orcl \
  -createAsContainerDatabase false \
  -sysPassword oracle_4U -systemPassword oracle_4U \
  -characterSet AL32UTF8 \
  -datafileDestination /u01/app/oracle/oradata \
  -storageType FS \
  -recoveryAreaDestination NONE \
  -enableArchive false \
  -sampleSchema true \
  -totalMemory 2048 \
  -emConfiguration NONE
```

- `-datafileDestination /u01/app/oracle/oradata` 를 주면 dbca 는 그 아래에 **대문자** `ORCL/` 을 만들고
  `system01.dbf sysaux01.dbf undotbs01.dbf users01.dbf temp01.dbf control01.ctl control02.ctl redo01~03.log` 를 둔다.
  컨트롤파일 두 개가 같은 디렉터리에 있고 FRA 는 없다 — 2장 실습 3·4 가 그 상태에서 시작한다.
- `-sampleSchema true` 로 HR 스키마가 들어온다. 교안 전체가 hr.employees 를 쓴다.
- 비밀번호 `oracle_4U` 는 교안 19장(expdp system/oracle_4U)과 종합실습과제의 값이다.
- `-enableArchive false` : 1~2장 실습 1 이 NOARCHIVELOG 에서 시작한다.

### 4-2. 디렉터리 이름을 소문자 `orcl` 로

교안의 경로는 `/u01/app/oracle/oradata/orcl/` (소문자)다. Linux 는 대소문자를 구분하므로 그대로 두면
교안의 `!rm -f /u01/app/oracle/oradata/orcl/users01.dbf` 같은 명령이 파일을 찾지 못한다.
dbca 가 만든 `ORCL` 을 `orcl` 로 바꾼다.

```sql
SYS@orcl> SHUTDOWN IMMEDIATE
SYS@orcl> !mv /u01/app/oracle/oradata/ORCL /u01/app/oracle/oradata/orcl
SYS@orcl> STARTUP NOMOUNT
SYS@orcl> ALTER SYSTEM SET control_files =
  2    '/u01/app/oracle/oradata/orcl/control01.ctl',
  3    '/u01/app/oracle/oradata/orcl/control02.ctl' SCOPE=spfile;
SYS@orcl> STARTUP FORCE MOUNT
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/system01.dbf'  TO '/u01/app/oracle/oradata/orcl/system01.dbf';
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/sysaux01.dbf'  TO '/u01/app/oracle/oradata/orcl/sysaux01.dbf';
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/undotbs01.dbf' TO '/u01/app/oracle/oradata/orcl/undotbs01.dbf';
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/users01.dbf'   TO '/u01/app/oracle/oradata/orcl/users01.dbf';
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/temp01.dbf'    TO '/u01/app/oracle/oradata/orcl/temp01.dbf';
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/redo01.log'    TO '/u01/app/oracle/oradata/orcl/redo01.log';
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/redo02.log'    TO '/u01/app/oracle/oradata/orcl/redo02.log';
SYS@orcl> ALTER DATABASE RENAME FILE '/u01/app/oracle/oradata/ORCL/redo03.log'    TO '/u01/app/oracle/oradata/orcl/redo03.log';
SYS@orcl> ALTER DATABASE OPEN;
SYS@orcl> SELECT name FROM v$datafile UNION ALL SELECT name FROM v$tempfile
  2  UNION ALL SELECT member FROM v$logfile UNION ALL SELECT name FROM v$controlfile;
```

열 줄 모두 `/u01/app/oracle/oradata/orcl/` 로 시작해야 한다. `ORCL` 이 하나라도 남으면 RENAME 을 빠뜨린 것이다.

### 4-3. 리두 로그를 교안 크기(10M × 3)로

dbca 의 리두는 200M 이다. 교안의 2장 실습 5(그룹 크기 조정)와 3장 이후 화면은 그룹 1·2·3 이 각 10M 인
상태를 전제한다. 크기가 달라도 실습은 되지만 로그 스위치가 일어나는 빈도와 화면의 SIZE 열이 달라진다.
맞추려면 임시 그룹을 거쳐 다시 만든다.

```sql
SYS@orcl> ALTER DATABASE ADD LOGFILE GROUP 4 ('/u01/app/oracle/oradata/orcl/redo04.log') SIZE 10M;
SYS@orcl> ALTER DATABASE ADD LOGFILE GROUP 5 ('/u01/app/oracle/oradata/orcl/redo05.log') SIZE 10M;
SYS@orcl> ALTER SYSTEM SWITCH LOGFILE;   -- CURRENT 가 4 또는 5 가 될 때까지 두세 번
SYS@orcl> ALTER SYSTEM CHECKPOINT;
SYS@orcl> SELECT group#, sequence#, bytes/1024/1024 mb, status FROM v$log ORDER BY 1;
-- 1·2·3 이 모두 INACTIVE 가 된 뒤
SYS@orcl> ALTER DATABASE DROP LOGFILE GROUP 1;
SYS@orcl> ALTER DATABASE DROP LOGFILE GROUP 2;
SYS@orcl> ALTER DATABASE DROP LOGFILE GROUP 3;
SYS@orcl> !rm -f /u01/app/oracle/oradata/orcl/redo01.log /u01/app/oracle/oradata/orcl/redo02.log /u01/app/oracle/oradata/orcl/redo03.log
SYS@orcl> ALTER DATABASE ADD LOGFILE GROUP 1 ('/u01/app/oracle/oradata/orcl/redo01.log') SIZE 10M;
SYS@orcl> ALTER DATABASE ADD LOGFILE GROUP 2 ('/u01/app/oracle/oradata/orcl/redo02.log') SIZE 10M;
SYS@orcl> ALTER DATABASE ADD LOGFILE GROUP 3 ('/u01/app/oracle/oradata/orcl/redo03.log') SIZE 10M;
SYS@orcl> ALTER SYSTEM SWITCH LOGFILE;   -- CURRENT 가 1·2·3 중 하나가 될 때까지
SYS@orcl> ALTER SYSTEM CHECKPOINT;
SYS@orcl> ALTER DATABASE DROP LOGFILE GROUP 4;
SYS@orcl> ALTER DATABASE DROP LOGFILE GROUP 5;
SYS@orcl> !rm -f /u01/app/oracle/oradata/orcl/redo04.log /u01/app/oracle/oradata/orcl/redo05.log
```

`ORA-01623`(CURRENT 는 못 지운다) 이나 `ORA-01624`(ACTIVE 도 못 지운다) 가 나면 스위치와 체크포인트를
더 하고 다시 시도한다. 2장 실습 5 가 바로 이 오류를 학습 내용으로 다룬다.

### 4-4. SCOTT 스키마와 실습 계정

```sql
SYS@orcl> @?/rdbms/admin/utlsampl.sql              -- scott/tiger (emp, dept)
SYS@orcl> CREATE USER itwill IDENTIFIED BY oracle_4U
  2    DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
SYS@orcl> GRANT CREATE SESSION, RESOURCE, CREATE VIEW TO itwill;   -- 종합실습과제·고급실습
SYS@orcl> ALTER USER hr IDENTIFIED BY hr ACCOUNT UNLOCK;
SYS@orcl> ALTER PROFILE default LIMIT PASSWORD_LIFE_TIME UNLIMITED;  -- 실습 중 비밀번호 만료 방지
```

`utlsampl.sql` 은 끝에서 SQL*Plus 를 종료한다. 다시 접속한다.

### 4-5. 작업 디렉터리

교안이 쓰는 디렉터리를 미리 만들어 둔다 (교안이 `mkdir` 하는 것도 있지만 권한 문제를 없앤다).

```bash
mkdir -p /home/oracle/backup /home/oracle/rmanbk /home/oracle/rman/log /home/oracle/dp /home/oracle/exam /home/oracle/lab
mkdir -p /u03/dpdump /u03/arch2 /u03/aux
```

`/home/oracle/arch1`(2장), `/u02/oradata/orcl`(2장), `/home/oracle/rmancopy`(14장) 는 교안이 만든다.

### 4-6. 자동 기동

```bash
# /etc/oratab
orcl:/u01/app/oracle/product/19.3.0/dbhome_1:Y
```

`dbstart $ORACLE_HOME` 을 rc.local 이나 systemd 에 걸어도 되지만, 이 과정은 인스턴스를 수시로
내리고 올리므로 **자동 기동을 걸지 않는 편이 낫다.** 부팅 뒤 `lsnrctl start` 와 `STARTUP` 을 손으로 한다.

---

## 5. 설치 결과 검증 — 교안 기준 배치와 대조

`BR_실습랩_기준배치.md` 1절과 같아야 한다.

```sql
SYS@orcl> SELECT name, dbid, log_mode, open_mode FROM v$database;
NAME      LOG_MODE      OPEN_MODE
ORCL      NOARCHIVELOG  READ WRITE

SYS@orcl> SELECT file#, name FROM v$datafile ORDER BY 1;
         1 /u01/app/oracle/oradata/orcl/system01.dbf
         3 /u01/app/oracle/oradata/orcl/sysaux01.dbf
         4 /u01/app/oracle/oradata/orcl/undotbs01.dbf
         7 /u01/app/oracle/oradata/orcl/users01.dbf
SYS@orcl> SELECT name FROM v$tempfile;
           /u01/app/oracle/oradata/orcl/temp01.dbf
SYS@orcl> SELECT name FROM v$controlfile;
           /u01/app/oracle/oradata/orcl/control01.ctl
           /u01/app/oracle/oradata/orcl/control02.ctl
SYS@orcl> SELECT l.group#, l.bytes/1024/1024 mb, f.member FROM v$log l JOIN v$logfile f USING (group#) ORDER BY 1;
         1  10 /u01/app/oracle/oradata/orcl/redo01.log
         2  10 /u01/app/oracle/oradata/orcl/redo02.log
         3  10 /u01/app/oracle/oradata/orcl/redo03.log
SYS@orcl> SHOW PARAMETER db_recovery_file_dest          -- 비어 있다 (2장 실습 3 이 설정)
SYS@orcl> SHOW PARAMETER log_archive_dest_1             -- 비어 있다 (2장 실습 1 이 설정)
SYS@orcl> SELECT username FROM dba_users WHERE username IN ('HR','SCOTT','ITWILL');
SYS@orcl> SELECT COUNT(*) FROM hr.employees;            -- 107
```

파일 번호가 1·3·4·7 인 것은 General_Purpose 템플릿의 시드 DB 가 그렇게 만들어져 있기 때문이다.
교안의 데이터파일 대장(기준배치 2절)이 이 번호를 전제한다.

---

## 6. 스냅숏

이 상태에서 VM 스냅숏 `BR_BASE` 를 뜬다. 장 실습이 꼬였을 때, 실기평가 전에, 고급 실습을 새로 시작할 때
여기로 돌아온다. 스냅숏은 정지 상태에서 뜬다 (기동 중 스냅숏은 컨트롤파일과 리두가 불일치할 수 있다).

---

## 7. 교안이 만드는 것과 설치 때 만드는 것

| 항목 | 값 | 만드는 곳 |
|---|---|---|
| 데이터파일·TEMP·컨트롤파일 1·2·리두 a 멤버 | `/u01/app/oracle/oradata/orcl/` | **설치 (4절)** |
| 리두 그룹 1·2·3 각 10M | | **설치 (4-3)** |
| HR, SCOTT, itwill | | **설치 (4-4)** |
| ARCHIVELOG, `LOG_ARCHIVE_DEST_1=/home/oracle/arch1`, 형식 `arch_%t_%s_%r.arc` | | 2장 실습 1 |
| 아카이브 2번 대상 `/home/oracle/arch2` (실습 끝에 해제) | | 2장 실습 2, 9장 실습 5 (`/u03/arch2`) |
| FRA `db_recovery_file_dest` | `/u01/app/oracle/fast_recovery_area` 4G | 2장 실습 3 |
| 컨트롤파일 3번 | `/u02/oradata/orcl/control03.ctl` | 2장 실습 4 |
| 리두 b 멤버, 그룹 4(50M) 추가·그룹 2 삭제 → **그룹 1·3·4** | `/u02/oradata/orcl/redoNNb.log` | 2장 실습 5 (이후 모든 장의 전제) |
| Cold/Hot 백업 | `/home/oracle/backup/...` | 3장 이후 각 장 |
| RMAN 백업 위치와 CONFIGURE | `/home/oracle/rmanbk/`, `cf_%F`, `%d_%T_%s_%p.bkp` | 13장 실습 4 |
| 로컬 Recovery Catalog 인스턴스 `rcat` | dbca, `/u02/oradata/RCAT`, rcatowner/oracle_4U, tnsnames `RCAT` | 13장 실습 2·3 |
| Data Pump 디렉터리 `DP_DIR` | `/u03/dpdump` | 19장 실습 1 |
| 실기평가 스크립트 | `/home/oracle/exam/` | 각 실기평가 운영가이드 |

### 교안 표기가 서로 다른 곳

교안을 읽을 때 아래를 자기 환경으로 바꿔 읽는다. 설치 가이드는 첫 열의 값을 만든다.

| 이 가이드 | 교안의 다른 표기 | 어디에 |
|---|---|---|
| `/u01/app/oracle/oradata/orcl/` | `/u03/oradata/ORCL/` | 15~19장 트랜스크립트 (실측 랩의 표기). 파일 이름은 같으므로 디렉터리만 바꿔 읽는다 |
| FRA `/u01/app/oracle/fast_recovery_area` (2장) | `/fra/ORCL/...` (9·13장), `/u03/fra` (18장) | FRA 를 어디에 두든 실습은 같다. `/fra` 마운트를 만들어 두었으므로 18장 Flashback Database 는 `/fra` 를 써도 된다 |
| 호스트 `oel7v9` | `oel7v9r1` | 종합실습과제, 고급실습 과정안내 |
| `/u02/oradata/RCAT` (13장 로컬 카탈로그) | `/u01/app/oracle/oradata/rcat` | 고급 05 (관리계 rcat 의 경로) |

---

## 8. 고급 실습 환경 (서버 2대)

고급 실습 01 의 `[3] 환경 준비` 는 아래를 **이미 끝난 것**으로 전제한다.
19장까지 마친 oel7v9 에 sales 를 더하고, oel7v9r2 를 새로 만든다.

```
oel7v9   (운영계)  : orcl (기존) + sales
oel7v9r2 (관리계)  : rcat (카탈로그 전용) + hrdb + /backup NFS 원본 + DR 복구 대상 /u02
```

### 8-1. oel7v9r2 준비

1~3절을 그대로 반복한다 (`ORACLE_SID=rcat`, 리스너 HOST `oel7v9r2`, SID_DESC 는 `rcat`·`hrdb`).
`/u02` 를 60 GB 로 잡는다 — 07 이 sales 전체(약 2 GB)를 `/u02/oradata/sales` 에 재구축하고,
10 이 복제본을 만든다.

```bash
mkdir -p /u02/oradata /u02/admin /u02/arch_sales /exports/backup
chown -R oracle:oinstall /u02 /exports
```

> 고급 07·10 의 트랜스크립트에는 oel7v9r2 에 ASM(`+FRA`, `asm_pmon_+ASM`)이 보인다. 실측 서버가
> Oracle Restart 였기 때문이다. 이 가이드는 파일 시스템으로 만든다. 10 의 L4(DUPLICATE) 에서
> `db_create_file_dest='+FRA'` 는 `'/u02/oradata'` 로 바꿔 읽는다. 07 은 원래 `/u02/oradata/sales` 다.

### 8-2. /backup 공유 (NFS, 원본 oel7v9r2)

고급 03 의 글로벌 스크립트가 `/backup/%d/%U` 에 쓰고, 07 이 oel7v9 의 백업을 oel7v9r2 에서 읽는다.
두 서버에서 같은 경로로 보여야 한다.

```bash
# oel7v9r2 (root)
echo '/exports/backup oel7v9(rw,sync,no_root_squash)' >> /etc/exports
systemctl enable --now nfs-server && exportfs -ra
mkdir -p /backup && mount --bind /exports/backup /backup
echo '/exports/backup /backup none bind 0 0' >> /etc/fstab
mkdir -p /backup/HRDB /backup/RCAT && chown -R oracle:oinstall /exports/backup

# oel7v9 (root)
mkdir -p /backup
echo 'oel7v9r2:/exports/backup /backup nfs defaults,_netdev 0 0' >> /etc/fstab
mount /backup
su - oracle -c 'mkdir -p /backup/ORCL /backup/SALES'
```

두 서버의 oracle uid/gid 가 같아야 한다 (`id oracle` 로 확인. preinstall 은 보통 54321/54321 을 준다).

### 8-3. oel7v9 의 나머지 디렉터리와 계정

```bash
# root
mkdir -p /archive_keep /export /backup_wallet && chown oracle:oinstall /archive_keep /export /backup_wallet
# oracle
mkdir -p /home/oracle/rcadm/{log,scripts,fallback,verify,bench} /home/oracle/arch_sales /u03/dpdump_rcat
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa && ssh-copy-id oracle@oel7v9r2      # 07 의 파일 전송, 09 의 반출
```

oel7v9r2 에도 `/home/oracle/rcadm/{log,scripts,fallback,verify,bench}` 를 만든다.
운영 스크립트(`고급실습_RecoveryCatalog/운영스크립트/`)는 각 실습이 만들라고 하는 시점에 `/home/oracle/rcadm/` 에 둔다.

### 8-4. sales 생성 (oel7v9)

고급 실습의 sales 경로는 dbca 기본값 그대로 **대문자** `/u01/app/oracle/oradata/SALES/` 다 (07 의 경로 매핑표).
소문자로 바꾸지 않는다.

```bash
dbca -silent -createDatabase -templateName General_Purpose.dbc \
  -gdbName sales -sid sales -createAsContainerDatabase false \
  -sysPassword oracle_4U -systemPassword oracle_4U -characterSet AL32UTF8 \
  -datafileDestination /u01/app/oracle/oradata -storageType FS \
  -recoveryAreaDestination NONE -enableArchive false -sampleSchema true \
  -totalMemory 1536 -emConfiguration NONE
```

```sql
SYS@sales> SHUTDOWN IMMEDIATE
SYS@sales> STARTUP MOUNT
SYS@sales> ALTER DATABASE ARCHIVELOG;
SYS@sales> ALTER DATABASE OPEN;
SYS@sales> ALTER SYSTEM SET log_archive_dest_1 = 'location=/home/oracle/arch_sales mandatory' SCOPE=both;
SYS@sales> ALTER SYSTEM SET control_file_record_keep_time = 30 SCOPE=both;
SYS@sales> CREATE USER itwill IDENTIFIED BY oracle_4U DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
SYS@sales> GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO itwill;
SYS@sales> CREATE TABLE itwill.customer TABLESPACE users AS
  2  SELECT ROWNUM AS cust_id, '고객'||ROWNUM AS cust_name,
  3         '010-'||LPAD(MOD(ROWNUM,10000),4,'0')||'-'||LPAD(MOD(ROWNUM*7,10000),4,'0') AS phone,
  4         'cust'||ROWNUM||'@example.com' AS email
  5  FROM dual CONNECT BY LEVEL <= 50000;
SYS@sales> SELECT COUNT(*) FROM itwill.customer;      -- 50000 : 고급 07 이 이 값을 전제한다
```

orcl 도 ARCHIVELOG(2장) 이고 `control_file_record_keep_time` 은 고급 04 에서 30 으로 올린다.

### 8-5. rcat 과 hrdb 생성 (oel7v9r2)

```bash
dbca -silent -createDatabase -templateName General_Purpose.dbc \
  -gdbName rcat -sid rcat -createAsContainerDatabase false \
  -sysPassword oracle_4U -systemPassword oracle_4U -characterSet AL32UTF8 \
  -datafileDestination /u01/app/oracle/oradata -storageType FS \
  -recoveryAreaDestination NONE -enableArchive true -sampleSchema false \
  -totalMemory 1024 -emConfiguration NONE

dbca -silent -createDatabase -templateName General_Purpose.dbc \
  -gdbName hrdb -sid hrdb -createAsContainerDatabase false \
  -sysPassword oracle_4U -systemPassword oracle_4U -characterSet AL32UTF8 \
  -datafileDestination /u01/app/oracle/oradata -storageType FS \
  -recoveryAreaDestination /u01/app/oracle/fast_recovery_area -recoveryAreaSize 10240 \
  -enableArchive true -sampleSchema true \
  -totalMemory 1536 -emConfiguration NONE
```

- rcat 의 `-totalMemory` 는 **1024 이상**이어야 한다. 600 으로 만들면 `CREATE CATALOG` 가 `ORA-04031` 로 실패한다 (실측).
- rcat 도 ARCHIVELOG 로 만든다. 고급 05 가 rcat 자체를 RMAN 으로 백업·복구한다.
- hrdb 는 FRA 에 아카이브를 쓴다 (`log_archive_dest_1` 을 두지 않는다). 05·10 의 화면이 그 전제다.

카탈로그 스키마 (고급 01 의 `[3]` 이 rcatowner / RCAT_DATA / rcver 19.03 을 확인한다) :

```sql
SYS@rcat> CREATE TABLESPACE rcat_data DATAFILE '/u01/app/oracle/oradata/RCAT/rcat_data01.dbf'
  2    SIZE 2G AUTOEXTEND ON NEXT 200M;
SYS@rcat> CREATE USER rcatowner IDENTIFIED BY oracle_4U
  2    DEFAULT TABLESPACE rcat_data TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON rcat_data;
SYS@rcat> GRANT RECOVERY_CATALOG_OWNER TO rcatowner;
SYS@rcat> ALTER PROFILE default LIMIT PASSWORD_LIFE_TIME UNLIMITED;
```

```bash
rman catalog rcatowner/oracle_4U@rcat
RMAN> CREATE CATALOG;
```

VPD 모델 전환(`dbmsrmanvpc.sql -vpd`)은 하지 않는다. 고급 01 의 4-2 가 그것을 학습 내용으로 다룬다.

### 8-6. 네트워크

두 서버의 `tnsnames.ora` 에 같은 네 항목을 둔다.

```
ORCL  = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = oel7v9)(PORT = 1521))   (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = orcl)))
SALES = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = oel7v9)(PORT = 1521))   (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = sales)))
RCAT  = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = oel7v9r2)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = rcat)))
HRDB  = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = oel7v9r2)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED)(SERVICE_NAME = hrdb)))
```

13장에서 만든 **oel7v9 의 로컬 rcat** 도 `RCAT` 이라는 이름으로 tnsnames 에 있다. 고급 실습의 `RCAT` 은
oel7v9r2 의 것이므로 로컬 항목은 `RCAT_LOCAL` 로 이름을 바꾼다 (13장 실습을 다시 볼 때만 쓴다).
oel7v9 의 리스너에 `sales` SID_DESC 를, oel7v9r2 의 리스너에 `rcat`·`hrdb` SID_DESC 를 넣고 `lsnrctl reload`.

```bash
# 두 서버에서
tnsping RCAT | tail -1 ; tnsping SALES | tail -1 ; tnsping HRDB | tail -1 ; tnsping ORCL | tail -1
```

### 8-7. 등록과 첫 백업

고급 01 의 `[3]` 은 세 DB 가 등록되어 있고 **각 DB 에 백업 이력이 있는 것**을 전제한다.
CONFIGURE 는 고급 03 이 표준으로 다시 잡지만, 그 전까지 쓸 최소값을 둔다.

```bash
# oel7v9
export ORACLE_SID=orcl;  rman target / catalog rcatowner/oracle_4U@rcat
RMAN> REGISTER DATABASE;
RMAN> CONFIGURE CONTROLFILE AUTOBACKUP ON;
RMAN> CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/backup/%d/%F';
RMAN> CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/backup/%d/%U';
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 21 DAYS;
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;
RMAN> EXIT
export ORACLE_SID=sales;  # 같은 순서
# oel7v9r2
export ORACLE_SID=hrdb;   # 같은 순서 (FORMAT 은 /backup/%d/%U 그대로)
```

```bash
rman catalog rcatowner/oracle_4U@rcat
RMAN> LIST DB_UNIQUE_NAME ALL;       # ORCL, SALES, HRDB 세 줄
```

> 13장에서 orcl 의 CONFIGURE 를 `/home/oracle/rmanbk` 로 잡아 둔 것을 여기서 `/backup/ORCL` 로 바꾼다.
> 14~16장을 다시 볼 일이 있으면 그때 되돌린다 (13장 실습 4 의 값).

### 8-8. 검증

```bash
# oel7v9
ps -ef | grep pmon | grep -v grep          # ora_pmon_orcl, ora_pmon_sales
df -h /backup /archive_keep /export        # /backup 은 oel7v9r2:/exports/backup
ssh oel7v9r2 hostname                      # 비밀번호 없이
# oel7v9r2
ps -ef | grep pmon | grep -v grep          # ora_pmon_rcat, ora_pmon_hrdb
sqlplus -s rcatowner/oracle_4U@rcat <<< "SELECT name, dbid FROM rc_database ORDER BY 1;"
```

여기서 VM 스냅숏 `BR_ADV_BASE` 를 두 서버 모두 뜬다. 고급 07(sales 소실)과 10(복제·삭제)은 이 스냅숏이
있어야 마음 놓고 진행한다. 실습 순서는 01→10 이며 건너뛰지 않는다 (03 의 스크립트, 07 의 실측치, 09 의
암호화 설정을 뒤 실습이 쓴다).

---

## 9. 자주 막히는 곳

| 증상 | 원인 | 조치 |
|---|---|---|
| dbca `DBT-06006 Unable to create directory` | `-datafileDestination` 디렉터리가 root 소유 | `chown oracle:oinstall` (2-4) |
| dbca 뒤 데이터파일이 `oradata/ORCL/` | dbca 는 DB 이름을 대문자로 붙인다 | 4-2 의 RENAME 절차 (orcl 만. sales·rcat·hrdb 는 대문자 그대로) |
| 교안 15~19장의 `/u03/oradata/ORCL/` | 실측 랩 표기 | `/u01/app/oracle/oradata/orcl/` 로 바꿔 읽는다 (7절 대조표) |
| 17장 DUPLICATE, 고급 07·10 에서 `ORA-12514` | NOMOUNT 인스턴스는 동적 등록이 안 된다 | listener.ora 의 SID_LIST 정적 등록 (3-2) |
| `CREATE CATALOG` 가 `ORA-04031` | rcat SGA 부족 | `-totalMemory 1024` 이상으로 다시 만든다 |
| 고급 03 에서 `ORA-19504` | `/backup/<DB이름>` 디렉터리가 없다 | 8-2 의 `mkdir -p /backup/{ORCL,SALES,HRDB,RCAT}` |
| 고급 실습에서 rcat 접속이 oel7v9 의 로컬 rcat 으로 감 | 13장의 tnsnames `RCAT` 항목 | `RCAT_LOCAL` 로 이름 변경 (8-6) |
| 카탈로그 리포트의 시각이 서버마다 다름 | 시간대 불일치 | 두 서버 `Asia/Seoul` (2-2) |
| `expdp system/oracle_4U` 가 `ORA-01017` | system 비밀번호가 다르다 | 교안은 oracle_4U 다. 4-1 의 dbca 값을 따른다 |
| 실기평가 exam_prep.sh 가 공간 부족 | 백업 사본 두세 벌 | `/home/oracle` 이 있는 `/` 를 40 GB 이상으로 (1절) |
