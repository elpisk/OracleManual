# -*- coding: utf-8 -*-
"""
ADG 구축 오케스트레이터 — 호스트에서 SSH 로 두 서버의 스크립트를 순서대로 돌린다.

  python run_all.py list          단계 목록
  python run_all.py run 10 11p    한 단계 또는 여러 단계
  python run_all.py all           전체
  python run_all.py shell chicago-srv "명령"

준비:
  pip install paramiko
  set ADG_OS_PW=<oracle OS 비밀번호>   (필수)
  set ADG_SYS_PW=<SYS 비밀번호>        (22 단계)
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
            cfg[m.group(1)] = m.group(2).split("#")[0].strip().strip('"')
    return cfg


CFG = load_cfg()
PRI = (CFG["PRI_HOST"], CFG["PRI_IP"])
STB = (CFG["STB_HOST"], CFG["STB_IP"])

# (단계, 설명, 대상 P=Primary S=Standby, 명령)
STEPS = [
    ("10",  "Primary — ARCHIVELOG · FORCE LOGGING · SRL", "P", "bash {D}/node/10_primary_prepare.sh"),
    ("11p", "Oracle Net — Primary",                       "P", "bash {D}/node/11_net_config.sh primary"),
    ("11s", "Oracle Net — Standby",                       "S", "bash {D}/node/11_net_config.sh standby"),
    ("11v", "TNS 연결 확인",                              "P", "bash {D}/node/11_net_config.sh verify"),
    ("12",  "Primary — Data Guard 파라미터",              "P", "bash {D}/node/12_dg_params.sh"),
    ("20",  "패스워드 파일 복사",                          "P", "bash {D}/node/20_standby_build.sh pwfile"),
    ("21",  "Standby NOMOUNT 기동",                       "S", "bash {D}/node/20_standby_build.sh nomount"),
    ("22",  "RMAN DUPLICATE 기동",                        "P", "bash {D}/node/20_standby_build.sh duplicate"),
    ("22w", "DUPLICATE 진행 감시",                        "P", "bash {D}/node/20_standby_build.sh watch"),
    ("23",  "Standby 후속 설정 · MRP 기동",               "S", "bash {D}/node/20_standby_build.sh post"),
    ("30p", "검증 — Primary",                             "P", "bash {D}/node/30_verify.sh primary"),
    ("30s", "검증 — Standby",                             "S", "bash {D}/node/30_verify.sh standby"),
]

REMOTE_DIR = "/home/oracle/adg_scripts"
PASS_THROUGH = ("ADG_SYS_PW",)


def ssh(ip):
    pw = os.environ.get("ADG_OS_PW")
    if not pw:
        sys.exit("환경 변수 ADG_OS_PW 를 설정한다.")
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(ip, username="oracle", password=pw, timeout=20,
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


def push(c):
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
    _, desc, where, cmd = tgt[0]
    name, ip = PRI if where == "P" else STB
    print("\n" + "=" * 74)
    print("### [%s] %s  —  %s" % (step, desc, name))
    print("=" * 74, flush=True)
    c = ssh(ip)
    push(c)
    exports = "".join("export %s='%s'; " % (k, os.environ[k])
                      for k in PASS_THROUGH if os.environ.get(k))
    t0 = time.time()
    rc = sh(c, exports + cmd.format(D=REMOTE_DIR))
    c.close()
    print("--- rc=%d  소요 %.1f분 ---" % (rc, (time.time() - t0) / 60), flush=True)
    if rc != 0:
        sys.exit("[%s] 실패. 위 출력을 확인한다." % step)


def main():
    a = sys.argv[1:] or ["list"]
    if a[0] == "list":
        print("단계  대상       설명")
        print("-" * 60)
        for s, d, w, _ in STEPS:
            print("%-5s %-10s %s" % (s, "Primary" if w == "P" else "Standby", d))
    elif a[0] == "run":
        for s in a[1:]:
            run_step(s)
    elif a[0] == "all":
        for s, _, _, _ in STEPS:
            run_step(s)
    elif a[0] == "shell":
        ip = dict([PRI, STB])[a[1]]
        c = ssh(ip)
        sh(c, " ".join(a[2:]))
        c.close()
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
