# LOB 실습용 파일 3종

실습 03(BLOB 파일 적재와 변환) · 04(BFILE) · 08(Data Pump) 이 쓰는 파일이다.
`LOB_실습_00_환경설정.txt` 의 `[6]` 에 있는 명령으로 만든 것을 그대로 담았다.

| 파일 | 크기 | 비고 |
|---|---|---|
| `manual.txt` | **7,566 바이트 / 5,154 문자 / 102 줄** | UTF-8. 한글 1,206자 + ASCII 3,948자 |
| `photo.bin` | **12,288 바이트** | `/dev/urandom` 난수 (내용은 의미 없다) |
| `big.dat` | **2,097,152 바이트 (2MB)** | `/dev/zero` (내용은 의미 없다) |

sha256

```
827a0c1656578a13628a519c0506ee50f6b012f6c5b085f6cbd4734fdb44f82c  manual.txt
e71c9a2c6721b455d8db46ad714c3cec4d2830e1fe85589f6a3b7ccb180b7697  photo.bin
5647f05ec18958947d32874eeb788fa396a05d0bab7c1b71f112ceb7e9b31eee  big.dat
```

`photo.bin` 과 `big.dat` 은 내용이 아니라 **크기만** 쓰인다. 해시가 달라도 무방하다.
`manual.txt` 는 실습 03 이 "5,154 문자 / 7,566 바이트" 를 그대로 설명에 쓰므로 이 파일을 쓰는 편이 안전하다.

---

## 서버에 올리는 법

디렉터리 객체는 **DB 서버의 경로**를 가리킨다. 클라이언트 PC 가 아니다.

```bash
# 클라이언트에서 서버로
scp manual.txt photo.bin big.dat oracle@<서버>:/home/oracle/lobfiles/

# 서버에서 확인
[oracle@oel7v9 ~]$ ls -l /home/oracle/lobfiles
[oracle@oel7v9 ~]$ LC_ALL=en_US.UTF-8 wc -c -m /home/oracle/lobfiles/manual.txt
5154 7566 /home/oracle/lobfiles/manual.txt
```

## 직접 만드는 법

내려받지 않고 서버에서 바로 만들어도 된다. 결과는 같다(`photo.bin` 의 난수 내용만 다르다).

```bash
[oracle@oel7v9 ~]$ mkdir -p /home/oracle/lobfiles
[oracle@oel7v9 ~]$ cd /home/oracle/lobfiles
[oracle@oel7v9 lobfiles]$ { echo 'LOB 실습 안내 문서'
>   printf '=%.0s' $(seq 40); echo
>   for i in $(seq 1 100); do
>     printf '%03d 행: 한글과 ASCII 가 섞인 본문입니다. abcdefghij 0123456789\n' "$i"
>   done
> } > manual.txt
[oracle@oel7v9 lobfiles]$ dd if=/dev/urandom of=photo.bin bs=1024 count=12 2>/dev/null
[oracle@oel7v9 lobfiles]$ dd if=/dev/zero    of=big.dat   bs=1M   count=2  2>/dev/null
```

`wc -m` 은 로케일에 의존한다. `LANG` 이 `C` 이면 문자 수 대신 바이트 수가 나오므로
`LC_ALL=en_US.UTF-8` 을 붙여야 5,154 를 볼 수 있다.

## 디렉터리 객체

```sql
SYS@orcl> CREATE OR REPLACE DIRECTORY lob_dir AS '/home/oracle/lobfiles';
SYS@orcl> GRANT READ, WRITE ON DIRECTORY lob_dir TO loblab;
```

READ 는 실습 03·04 의 BFILE 조회와 `LOADBLOBFROMFILE`/`LOADCLOBFROMFILE` 에,
WRITE 는 실습 08 의 Data Pump 덤프 생성에 쓴다.
