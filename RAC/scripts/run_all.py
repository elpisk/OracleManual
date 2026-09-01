# -*- coding: utf-8 -*-
"""
RAC 구축 오케스트레이터 — 호스트(Windows)에서 SSH 로 노드 스크립트를 순서대로 돌린다.

  python run_all.py list                 단계 목록
  python run_all.py run <단계>           한 단계만
  python run_all.py run 10 12 13         여러 단계
  python run_all.py all                  노드 단계 전체 (host/ 는 별도)
  python run_all.py shell <노드> <명령>  임시 확인용

준비:
  pip install paramiko
  set RAC_OS_PW=<root 비밀번호>       (필수)
  set RAC_ASM_PW=<SYSASM 비밀번호>    (20 단계)
  set RAC_SYS_PW=<SYS 비밀번호>       (41 단계)

호스트 쪽 단계(VM 클론·디스크 생성·vmx 편집·스냅샷)는 host/*.ps1 로 따로 실행한다.
"""
import io, os, re, sys, time

try:
    import paramiko
except ImportError:
    sys.exit("paramiko 가 필요하다:  pip install paramiko")

HERE = os.path.dirname(os.path.abspath(__file__))


def load_cfg():
    cfg = {}
    for ln in io.open(os.path.join(HERE, "config.env"), encoding="utf-8"):
        m = re.match(r'^([A-Z_0-9]+)=(.*)$', ln.strip())
        if m:
            cfg[m.group(1)] = m.group(2).strip().strip('"')
    return cfg


CFG = load_cfg()
NODES = [(CFG["NODE1_NAME"], CFG["NODE1_PUB"]), (CFG["NODE2_NAME"], CFG["NODE2_PUB"])]

# (단계, 설명, 대상노드, 계정, 명령)  대상: 1=첫노드 2=둘째 A=양쪽(순차)
STEPS = [
    ("10", "노드 OS 설정",                 "A", "root",   "bash {D}/node/10_os_setup.sh {N}"),
    ("11a", "SSH 키 생성",                 "A", "root",   "bash {D}/node/11_ssh_equivalence.sh keygen"),
    ("11b", "SSH 키 배포",                 "1", "root",   "bash {D}/node/11_ssh_equivalence.sh distribute"),
    ("11c", "SSH 등가성 검증",             "A", "root",   "bash {D}/node/11_ssh_equivalence.sh verify"),
    ("12", "udev — ASM 디스크 이름 고정",  "A", "root",   "bash {D}/node/12_udev_asmdisk.sh"),
    ("20u", "Grid 미디어 압축 해제",       "1", "grid",   "bash {D}/node/20_gi_install.sh unzip"),
    ("13", "사전 요구 사항 해소",          "A", "root",   "bash {D}/node/13_prereq_fix.sh"),
    ("14", "runcluvfy 사전 점검",          "1", "grid",   "bash {D}/node/14_cluvfy.sh"),
    ("20", "Grid Infrastructure 설치",     "1", "grid",   "bash {D}/node/20_gi_install.sh rsp && bash {D}/node/20_gi_install.sh install"),
    ("21a", "root.sh — 첫 노드",           "1", "root",   "bash {D}/node/21_root_sh.sh"),
    ("21b", "root.sh — 둘째 노드",         "2", "root",   "echo yes | bash {D}/node/21_root_sh.sh"),
    ("30", "DB 소프트웨어 설치",           "1", "oracle", "bash {D}/node/30_db_software.sh all"),
    ("30r", "DB 홈 root.sh",               "A", "root",   "{OH}/root.sh"),
    ("30p", "oracle .bash_profile",        "A", "root",   "bash {D}/node/30_db_software.sh profile {N}"),
    ("40c", "+DATA/+FRA 생성",             "1", "grid",   "bash {D}/node/40_diskgroups.sh create"),
    ("40m", "+DATA/+FRA 둘째 노드 마운트", "2", "grid",   "bash {D}/node/40_diskgroups.sh mount"),
    ("41", "DBCA — RAC DB 생성",           "1", "oracle", "bash {D}/node/41_dbca.sh create"),
    ("41p", "PDB 전 인스턴스 오픈·저장",   "1", "oracle", "bash {D}/node/41_dbca.sh pdbstate"),
    ("50", "최종 확인",                    "1", "root",   "bash {D}/node/50_postcheck.sh"),
]

REMOTE_DIR = "/tmp/rac_scripts"
PW_ENV = {"root": "RAC_OS_PW", "grid": "RAC_OS_PW", "oracle": "RAC_OS_PW"}
PASS_THROUGH = ("RAC_ASM_PW", "RAC_SYS_PW")


def ssh(ip, user="root"):
    pw = os.environ.get(PW_ENV.get(user, "RAC_OS_PW"))
    if not pw:
        sys.exit("환경 변수 RAC_OS_PW 를 설정한다.")
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(ip, username="root", password=pw, timeout=20,
              look_for_keys=False, allow_agent=False, banner_timeout=30)
    return c


def sh(c, cmd, timeout=14400):
    _, out, err = c.exec_command(cmd, timeout=timeout, get_pty=True)
    for line in iter(out.readline, ""):
        sys.stdout.write(line)
        sys.stdout.flush()
    rc = out.channel.recv_exit_status()
    e = err.read().decode("utf-8", "replace")
    if e.strip():
        print("[stderr]", e.rstrip())
    return rc


def push_scripts(c):
    """스크립트 묶음을 노드로 올린다. 노드에서 직접 실행할 수도 있다."""
    sf = c.open_sftp()
    for d in (REMOTE_DIR, REMOTE_DIR + "/node", REMOTE_DIR + "/templates"):
        try:
            sf.mkdir(d)
        except IOError:
            pass
    sf.put(os.path.join(HERE, "config.env"), REMOTE_DIR + "/config.env")
    for sub in ("node", "templates"):
        for f in sorted(os.listdir(os.path.join(HERE, sub))):
            sf.put(os.path.join(HERE, sub, f), "%s/%s/%s" % (REMOTE_DIR, sub, f))
    sf.close()
    sh(c, "chmod -R 755 %s" % REMOTE_DIR)


def run_step(step):
    tgt = [s for s in STEPS if s[0] == step]
    if not tgt:
        sys.exit("알 수 없는 단계: %s" % step)
    _, desc, where, user, cmd = tgt[0]
    idxs = {"1": [0], "2": [1], "A": [0, 1]}[where]
    for i in idxs:
        name, ip = NODES[i]
        print("\n" + "=" * 74)
        print("### [%s] %s  —  %s (%s)" % (step, desc, name, user))
        print("=" * 74, flush=True)
        c = ssh(ip)
        push_scripts(c)
        body = cmd.format(D=REMOTE_DIR, N=i + 1, OH=CFG["ORA_HOME"])
        # 비밀번호는 환경 변수로만 전달한다. 스크립트에 적지 않는다.
        exports = "".join("export %s='%s'; " % (k, os.environ[k])
                          for k in PASS_THROUGH if os.environ.get(k))
        if user == "root":
            full = exports + body
        else:
            full = "su - %s -c \"%s%s\"" % (user, exports, body.replace('"', '\\"'))
        t0 = time.time()
        rc = sh(c, full)
        c.close()
        print("--- rc=%d  소요 %.1f분 ---" % (rc, (time.time() - t0) / 60), flush=True)
        if rc != 0:
            sys.exit("[%s] %s 에서 실패했다. 위 출력을 확인한다." % (step, name))


def main():
    a = sys.argv[1:] or ["list"]
    if a[0] == "list":
        print("단계  대상  계정      설명")
        print("-" * 62)
        for s, d, w, u, _ in STEPS:
            print("%-5s %-5s %-9s %s" % (s, {"1": "노드1", "2": "노드2", "A": "양쪽"}[w], u, d))
        print("\n호스트 쪽(VM 클론·디스크·vmx·스냅샷)은 host/*.ps1 로 실행한다.")
    elif a[0] == "run":
        for s in a[1:]:
            run_step(s)
    elif a[0] == "all":
        for s, _, _, _, _ in STEPS:
            run_step(s)
    elif a[0] == "shell":
        name = a[1]
        ip = dict(NODES)[name]
        c = ssh(ip)
        sh(c, " ".join(a[2:]))
        c.close()
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
