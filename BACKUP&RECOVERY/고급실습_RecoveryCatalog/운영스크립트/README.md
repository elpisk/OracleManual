# 운영 스크립트 모음

Recovery Catalog 고급 과정(고급 실습 01~10)에서 만든 산출물을 현업 반입용으로 분리한 것이다.
각 파일은 해당 실습의 맥락을 모르는 사람도 쓸 수 있도록 헤더에 용도·사용법·전제를 담았다.

---

## 파일 목록

| 파일 | 출처 | 용도 | 실행 주기 |
|---|---|---|---|
| `rc_daily_report.sql` | 실습 02 | 일일 백업 점검 리포트 | 매일 08시 |
| `rc_backup_framework.sh` | 실습 03 | 글로벌 스크립트 기반 백업 실행기 | 매일/주간 |
| `rc_global_scripts.rman` | 실습 03 | 표준 글로벌 스토어드 스크립트 정의 | 최초 1회·변경 시 |
| `rc_maint_crosscheck.sh` | 실습 04 | 정합성 점검과 공간 회수 | 매일 05시 |
| `rc_catalog_backup.sh` | 실습 05 | 카탈로그 3중 보호 | 매일 03:30 |
| `rc_keep_audit.sql` | 실습 06 | 장기 보관 백업 감사 | 분기 |
| `dr_collect_info.sql` | 실습 07 | 재해 시 복구 정보 수집 | 재해 시 · 주 1회 평시 |
| `dr_rebuild.sh` | 실습 07 | 타 서버 재구축 준비·구문 생성 | 재해 시 |
| `rc_perf_analysis.sql` | 실습 08 | 백업 성능 분석 | 주간 |
| `rc_secure_export.sh` | 실습 09 | 외부 반출용 암호화 백업 | 요청 시 |
| `rc_restore_validate.sh` | 실습 10 | 복구 가능성 검증 L1~L3 | 매일(L2)·주간(L3) |
| `dr_drill_runbook.md` | 실습 10 | 장애 대응·훈련 런북 | 상시 참조 |

---

## 반입 전 반드시 고칠 것

모든 스크립트 상단의 `# ---- 환경에 맞게 수정할 값 ----` 블록을 확인한다.

| 항목 | 예시 값 | 비고 |
|---|---|---|
| `ORACLE_HOME` | `/u01/app/oracle/product/19.3.0/dbhome_1` | |
| `CATALOG` | `rcatowner/oracle_4U@rcat` | **평문 비밀번호. 아래 참조** |
| `MAILTO` | `dba-team@example.com` | |
| `BKROOT` | `/backup` | 백업 경로 |
| 임계값 | 보존일·경고 기준 | 조직 정책에 맞춘다 |

### 비밀번호 처리

예제는 가독성을 위해 접속 문자열에 비밀번호를 넣었다. 운영에서는 다음 중 하나를 쓴다.

- **외부 비밀번호 저장소(Secure External Password Store)** — 권장
  ```bash
  mkstore -wrl /home/oracle/wallet -create
  mkstore -wrl /home/oracle/wallet -createCredential rcat rcatowner <pw>
  # sqlnet.ora 에 WALLET_LOCATION 과 SQLNET.WALLET_OVERRIDE=TRUE 설정
  # 이후 접속 : rman target / catalog /@rcat
  ```
- OS 인증이 가능한 구성
- 파일 권한 600 의 별도 설정 파일에서 읽기

---

## 배치 순서

새 환경에 적용할 때는 아래 순서를 따른다. 뒤 항목이 앞 항목을 전제로 한다.

1. **카탈로그 구성** — 계정, `CREATE CATALOG`, 대상 DB `REGISTER`
2. **읽기 전용 리포팅 계정** — `rc_report` 생성과 `RC_*` 뷰 SELECT 권한
   - 리포트를 VPC 계정으로 돌리면 **조용히 일부만 점검**하고 정상으로 보고한다
3. **표준 CONFIGURE 적용** — `rc_global_scripts.rman` 하단 참조
   - `ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES` 를 반드시 포함한다
4. **글로벌 스크립트 등록** — `rc_global_scripts.rman`
5. **실행기 배포** — `rc_backup_framework.sh` (서버에 배포하는 유일한 파일)
6. **정리 작업 등록** — `rc_maint_crosscheck.sh`
7. **카탈로그 보호** — `rc_catalog_backup.sh`
8. **검증 체계** — `rc_restore_validate.sh`
9. **리포팅** — `rc_daily_report.sql`, `rc_perf_analysis.sql`
10. **훈련 시작** — `dr_drill_runbook.md`

---

## 크론 등록 예시

**운영계 서버**
```cron
# 백업
0  2 * * 1-6 /home/oracle/rcadm/rc_nightly.sh
0  1 * * 0   /home/oracle/rcadm/rc_backup_framework.sh orcl  gs_weekly_full ORCL
30 1 * * 0   /home/oracle/rcadm/rc_backup_framework.sh sales gs_weekly_full SALES
0 */4 * * *  /home/oracle/rcadm/rc_backup_framework.sh orcl  gs_archive_only ORCL

# 정리
0  5 * * *   /home/oracle/rcadm/rc_maint_crosscheck.sh orcl
20 5 * * *   /home/oracle/rcadm/rc_maint_crosscheck.sh sales

# 검증
0  6 * * *   /home/oracle/rcadm/rc_restore_validate.sh orcl  2
20 6 * * *   /home/oracle/rcadm/rc_restore_validate.sh sales 2
0 22 * * 6   /home/oracle/rcadm/rc_restore_validate.sh orcl  3
0 23 * * 6   /home/oracle/rcadm/rc_restore_validate.sh sales 3

# 지갑 (암호화 적용 DB)
10 3 * * *   /home/oracle/rcadm/rc_wallet_check.sh sales
```

**관리계 서버 (카탈로그)**
```cron
30 3 * * *   /home/oracle/rcadm/rc_catalog_backup.sh
0  8 * * *   /home/oracle/rcadm/rc_daily_report.sh
0  7 * * 1   sqlplus -s rc_report/<pw>@rcat @rc_perf_analysis.sql \
               | mailx -s "백업 성능 주간 분석" dba-team@example.com
0  9 1 */3 * sqlplus -s rc_report/<pw>@rcat @rc_keep_audit.sql \
               | mailx -s "장기 보관 분기 감사" dba-team@example.com
```

---

## 설계에 담긴 원칙

스크립트를 고칠 때 아래 원칙을 깨지 않는지 확인한다.

1. **판정은 종료 코드가 아니라 로그 내용으로 한다.** RMAN 은 일부 실패에도 0으로 끝나는 경우가 있다.
2. **CROSSCHECK 전에 마운트를 확인한다.** RMAN 은 접근 불가와 파일 부재를 구분하지 못한다. NFS 가 잠깐 끊긴 상태에서 정기 작업이 돌면 전량이 EXPIRED 가 되고, `DELETE EXPIRED` 는 되돌릴 수 없다.
3. **정리 작업은 두 단계로 나눈다.** 대조·목록화 후 이상 여부를 판정하고 나서 지운다.
4. **정리 후 `RESTORE PREVIEW` 로 복구 경로를 확인한다.** 정책상 맞는 삭제여도 실제 복원 가능성은 별개다.
5. **카탈로그의 백업은 `nocatalog` 로 받는다.** 자기 자신을 저장소로 쓰면 그것이 사라졌을 때 복구할 수 없다.
6. **장기 보관은 처음부터 `KEEP` 으로 받는다.** 사후에 `CHANGE ... KEEP` 을 걸면 필요한 아카이브가 이미 없을 수 있다.
7. **훈련은 정리까지가 한 작업이다.** 복제본을 남기면 다음 훈련을 막고 운영 파일 시스템까지 압박한다.
8. **리포트는 전체를 볼 수 있는 계정으로 돌린다.** 조회 가능 DB 수를 리포트 첫 줄에 찍어 안전장치로 삼는다.

---

## 주의

- `dr_rebuild.sh` 는 **준비와 구문 생성까지만** 한다. 실제 `RESTORE`/`RECOVER` 는 사람이 확인 후 실행한다. 재해 상황에서 자동 실행은 위험하다.
- `DROP DATABASE` 는 복제본에만 쓴다. 실행 전 `ORACLE_SID` 를 반드시 확인한다.
- `rc_secure_export.sh` 가 출력하는 반출 비밀번호는 로그에 남지 않는다. 화면에서 확보해 별도 경로로 전달한다.
- 스크립트의 평문 예시 데이터 패턴(`@example.com`, 전화번호 형식)은 각 조직의 민감 데이터 형태에 맞게 고친다.
