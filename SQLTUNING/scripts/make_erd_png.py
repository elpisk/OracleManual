# -*- coding: utf-8 -*-
"""진료비청구심사_ERD.md 의 mermaid erDiagram 을 읽어 PNG 로 그린다.
.md 가 단일 출처이므로 다이어그램을 고치면 이미지도 다시 만들면 된다."""
import sys, io, os, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(HERE, "..", "진료비청구심사_ERD.md")
OUT  = os.path.join(HERE, "..", "진료비청구심사_ERD.png")

# ── 색 (저장소 PPT 팔레트와 맞춘다)
DARK   = (0x17, 0x20, 0x2A)
RED    = (0xC0, 0x39, 0x2B)
BLUE   = (0x1F, 0x5C, 0xA8)
BODY   = (0x20, 0x28, 0x30)
MUTED  = (0x6B, 0x76, 0x80)
LINE   = (0x8A, 0x95, 0xA0)
BG     = (0xFF, 0xFF, 0xFF)
ROWBG  = (0xF7, 0xF9, 0xFA)
BORDER = (0xB9, 0xC2, 0xCA)
GOLD   = (0xB8, 0x86, 0x00)

S = 2                                     # 2배로 그려 선명하게
def F(path, size):
    return ImageFont.truetype(path, int(size * S))
MAL   = "C:/Windows/Fonts/malgun.ttf"
MALB  = "C:/Windows/Fonts/malgunbd.ttf"
MONO  = "C:/Windows/Fonts/consola.ttf"
MONOB = "C:/Windows/Fonts/consolab.ttf"

f_title  = F(MALB, 20)
f_sub    = F(MAL, 10.5)
f_ent    = F(MONOB, 12)
f_col    = F(MONO, 10)
f_colb   = F(MONOB, 10)
f_type   = F(MONO, 8.5)
f_note   = F(MAL, 8.5)
f_rel    = F(MAL, 9)
f_key    = F(MONOB, 8)
f_legend = F(MAL, 9)
f_cnt    = F(MAL, 8)


# ─────────────────────────────────────────── mermaid 파싱
def parse(md):
    m = re.search(r"```mermaid\s*\n(.*?)\n```", md, re.S)
    body = m.group(1)
    ents, rels, cur = {}, [], None
    for raw in body.split("\n"):
        line = raw.strip()
        if not line or line.startswith("erDiagram"):
            continue
        if cur is not None:
            if line == "}":
                cur = None
                continue
            mm = re.match(r'^(\S+)\s+(\S+)(?:\s+(PK|FK|UK))?\s*(?:"([^"]*)")?\s*$', line)
            if mm:
                ents[cur].append({"type": mm.group(1), "name": mm.group(2),
                                  "key": mm.group(3) or "", "note": mm.group(4) or ""})
            continue
        mo = re.match(r"^(\w+)\s*\{$", line)
        if mo:
            cur = mo.group(1); ents[cur] = []; continue
        mr = re.match(r'^(\w+)\s+([|}o][|o{-]*[|o{])\s*(\w+)\s*:\s*"?([^"]*)"?\s*$', line)
        if mr:
            rels.append({"left": mr.group(1), "card": mr.group(2),
                         "right": mr.group(3), "label": mr.group(4).strip()})
    return ents, rels


md = io.open(SRC, encoding="utf-8").read()
ENT, REL = parse(md)
print("엔티티", len(ENT), list(ENT.keys()))
print("관계  ", len(REL))
for r in REL:
    print("   ", r["left"], r["card"], r["right"], r["label"])

# ─────────────────────────────────────────── 배치 (손으로 잡는다)
POS = {
    "HOSPITALS":      (40,  120),
    "PATIENTS":       (40,  400),
    "MEDICAL_CLAIMS": (450, 250),
    "CLAIM_DETAILS":  (880,  70),
    "DRUG_MASTER":    (1290, 70),
    "DISEASES":       (880, 400),
    "REVIEW_LOG":     (880, 590),
}
HUB = "MEDICAL_CLAIMS"

ROW_H   = 20
HEAD_H  = 28
PAD_X   = 10
W_TYPE  = 58
W_NAME  = 132
W_KEY   = 26


def box_w(cols):
    note_w = 0
    img = Image.new("RGB", (10, 10))
    d = ImageDraw.Draw(img)
    for c in cols:
        if c["note"]:
            note_w = max(note_w, d.textlength(c["note"], font=f_note) / S)
    return int(PAD_X * 2 + W_TYPE + W_NAME + W_KEY + (note_w + 12 if note_w else 0))


W = {n: box_w(c) for n, c in ENT.items()}
GAP = 170
right_x = POS[HUB][0] + W[HUB] + GAP
for n in ("CLAIM_DETAILS", "DISEASES", "REVIEW_LOG"):
    POS[n] = (right_x, POS[n][1])
POS["DRUG_MASTER"] = (right_x + W["CLAIM_DETAILS"] + 120, POS["DRUG_MASTER"][1])

BOX = {}
for name, cols in ENT.items():
    x, y = POS[name]
    BOX[name] = {"x": x, "y": y, "w": W[name], "h": HEAD_H + ROW_H * len(cols) + 6}

CW = max(b["x"] + b["w"] for b in BOX.values()) + 40
CH = max(b["y"] + b["h"] for b in BOX.values()) + 120
TOP = 78                                   # 제목 영역
CH += TOP

img = Image.new("RGB", (CW * S, CH * S), BG)
dr = ImageDraw.Draw(img)


def rect(x, y, w, h, fill=None, outline=None, width=1, r=0):
    xy = [x * S, y * S, (x + w) * S, (y + h) * S]
    if r:
        dr.rounded_rectangle(xy, radius=r * S, fill=fill, outline=outline, width=int(width * S))
    else:
        dr.rectangle(xy, fill=fill, outline=outline, width=int(width * S))


def text(x, y, s, font, fill=BODY, anchor="la"):
    dr.text((x * S, y * S), s, font=font, fill=fill, anchor=anchor)


def line(pts, fill=LINE, width=1.4):
    dr.line([(p[0] * S, p[1] * S) for p in pts], fill=fill, width=int(width * S), joint="curve")


# ── 제목
text(40, 26, "진료비 청구 및 심사 시스템 — ERD", f_title, DARK)
text(40, 54, "7 테이블 · 전체 컬럼 · PK/FK 관계   |   출처 : 진료비청구심사_ERD.md (mermaid erDiagram)",
     f_sub, MUTED)
rect(40, 72, CW - 80, 1.6, fill=RED)


# ─────────────────────────────────────────── 관계선
def anchors(b):
    x, y, w, h = b["x"], b["y"] + TOP, b["w"], b["h"]
    return {"L": (x, y + h / 2), "R": (x + w, y + h / 2),
            "T": (x + w / 2, y), "B": (x + w / 2, y + h),
            "cx": x + w / 2, "cy": y + h / 2, "x": x, "y": y, "w": w, "h": h}


def crow(px, py, direction, fill=LINE):
    """N 쪽 표시 (까마귀발)"""
    d = 10
    if direction == "L":      # 대상 박스의 왼쪽 면으로 들어간다
        line([(px - d, py), (px, py - 6)], fill, 1.3)
        line([(px - d, py), (px, py)], fill, 1.3)
        line([(px - d, py), (px, py + 6)], fill, 1.3)
    elif direction == "R":    # 대상 박스의 오른쪽 면으로 들어간다
        line([(px + d, py), (px, py - 6)], fill, 1.3)
        line([(px + d, py), (px, py)], fill, 1.3)
        line([(px + d, py), (px, py + 6)], fill, 1.3)
    elif direction == "T":
        line([(px, py), (px - 6, py - d)], fill, 1.3)
        line([(px, py), (px, py - d)], fill, 1.3)
        line([(px, py), (px + 6, py - d)], fill, 1.3)
    else:
        line([(px, py), (px - 6, py + d)], fill, 1.3)
        line([(px, py), (px, py + d)], fill, 1.3)
        line([(px, py), (px + 6, py + d)], fill, 1.3)


def opt(px, py, direction, card, fill=LINE):
    """N 쪽 앞의 표시 — o{ 는 0건 가능(원), |{ 는 최소 1건(막대)"""
    k = -18 if direction == "L" else 18
    cx = px + k
    if card.endswith("o{"):
        rr = 4
        dr.ellipse([(cx - rr) * S, (py - rr) * S, (cx + rr) * S, (py + rr) * S],
                   fill=BG, outline=fill, width=int(1.4 * S))
    else:
        line([(cx, py - 6), (cx, py + 6)], fill, 1.6)


def one(px, py, direction, fill=LINE):
    """1 쪽 표시 (짧은 직교 눈금)"""
    if direction in ("L", "R"):
        k = 8 if direction == "R" else -8
        line([(px + k, py - 6), (px + k, py + 6)], fill, 1.6)
    else:
        k = 8 if direction == "B" else -8
        line([(px - 6, py + k), (px + 6, py + k)], fill, 1.6)


# 관계별 경로를 손으로 지정한다 (좌/우 어느 면에서 나가고 들어오는지)
ROUTE = {
    ("HOSPITALS", "MEDICAL_CLAIMS"):      ("R", "L"),
    ("PATIENTS", "MEDICAL_CLAIMS"):       ("R", "L"),
    ("MEDICAL_CLAIMS", "CLAIM_DETAILS"):  ("R", "L"),
    ("DRUG_MASTER", "CLAIM_DETAILS"):     ("L", "R"),
    ("MEDICAL_CLAIMS", "DISEASES"):       ("R", "L"),
    ("MEDICAL_CLAIMS", "REVIEW_LOG"):     ("R", "L"),
}
# 겹치지 않게 세로 오프셋을 조금씩 준다
YOFF = {
    ("HOSPITALS", "MEDICAL_CLAIMS"):     (0, -34),
    ("PATIENTS", "MEDICAL_CLAIMS"):      (0, 34),
    ("MEDICAL_CLAIMS", "CLAIM_DETAILS"): (-46, 0),
    ("DRUG_MASTER", "CLAIM_DETAILS"):    (0, 0),
    ("MEDICAL_CLAIMS", "DISEASES"):      (6, 0),
    ("MEDICAL_CLAIMS", "REVIEW_LOG"):    (52, 0),
}

for r in REL:
    a, b = BOX[r["left"]], BOX[r["right"]]
    A, B = anchors(a), anchors(b)
    sd, ed = ROUTE[(r["left"], r["right"])]
    so, eo = YOFF[(r["left"], r["right"])]
    sx, sy = A[sd]; sy += so
    ex, ey = B[ed]; ey += eo
    mid = (sx + ex) / 2
    col = RED if HUB in (r["left"], r["right"]) else BLUE
    if sd in ("L", "R") and ed in ("L", "R"):
        if sd == "R" and ed == "L":
            line([(sx, sy), (mid, sy), (mid, ey), (ex, ey)], col)
        else:                                      # DRUG_MASTER -> CLAIM_DETAILS (오른쪽에서 왼쪽으로)
            line([(sx, sy), (sx - 26, sy), (sx - 26, ey), (ex, ey)], col)
    one(sx, sy, sd, col)
    # N 쪽 (두 번째 엔티티) 에 까마귀발 + 선택/필수 표시
    crow(ex, ey, "L" if ed == "L" else "R", col)
    opt(ex, ey, "L" if ed == "L" else "R", r["card"], col)
    # 관계 라벨
    lx = mid if (sd == "R" and ed == "L") else (sx + ex) / 2
    ly = (sy + ey) / 2
    if r["right"] == "DISEASES":
        ly = sy + 2
    lab = r["label"]
    tw = dr.textlength(lab, font=f_rel) / S
    rect(lx - tw / 2 - 5, ly - 9, tw + 10, 17, fill=BG)
    text(lx, ly - 7, lab, f_rel, col, anchor="ma")


# ─────────────────────────────────────────── 엔티티 박스
for name, cols in ENT.items():
    b = BOX[name]
    x, y, w, h = b["x"], b["y"] + TOP, b["w"], b["h"]
    head = RED if name == HUB else DARK
    # 본체
    rect(x, y, w, h, fill=BG, outline=BORDER, width=1.2, r=5)
    rect(x, y, w, HEAD_H, fill=head, r=5)
    rect(x, y + HEAD_H - 6, w, 6, fill=head)
    text(x + PAD_X, y + 7, name, f_ent, BG)
    text(x + w - PAD_X, y + 9, "%d 컬럼" % len(cols), f_cnt,
         (0xD8, 0xE2, 0xEA), anchor="ra")
    # 컬럼
    cy = y + HEAD_H + 3
    for i, c in enumerate(cols):
        if i % 2 == 1:
            rect(x + 1, cy, w - 2, ROW_H, fill=ROWBG)
        kx = x + PAD_X
        if c["key"] == "PK":
            rect(kx, cy + 4, 20, 12, fill=GOLD, r=2)
            text(kx + 10, cy + 5.5, "PK", f_key, BG, anchor="ma")
        elif c["key"] == "FK":
            rect(kx, cy + 4, 20, 12, fill=BLUE, r=2)
            text(kx + 10, cy + 5.5, "FK", f_key, BG, anchor="ma")
        nx = kx + W_KEY
        text(nx, cy + 4, c["name"], f_colb if c["key"] else f_col,
             DARK if c["key"] else BODY)
        tx = nx + W_NAME
        text(tx, cy + 5.5, c["type"], f_type, MUTED)
        if c["note"]:
            text(tx + W_TYPE, cy + 5, c["note"], f_note, MUTED)
        cy += ROW_H

# ─────────────────────────────────────────── 범례
ly = CH - 42
text(40, ly, "범례", f_legend, DARK)
rect(78, ly + 2, 20, 12, fill=GOLD, r=2); text(88, ly + 3.5, "PK", f_key, BG, anchor="ma")
text(103, ly + 1, "기본키", f_legend, BODY)
rect(146, ly + 2, 20, 12, fill=BLUE, r=2); text(156, ly + 3.5, "FK", f_key, BG, anchor="ma")
text(171, ly + 1, "외래키", f_legend, BODY)
line([(222, ly + 8), (268, ly + 8)], LINE, 1.6)
one(222, ly + 8, "R", LINE)
crow(268, ly + 8, "L", LINE)
opt(268, ly + 8, "L", "||--o{", LINE)
text(284, ly + 1, "1 : N  (0건 가능)", f_legend, BODY)
line([(400, ly + 8), (446, ly + 8)], LINE, 1.6)
one(400, ly + 8, "R", LINE)
crow(446, ly + 8, "L", LINE)
opt(446, ly + 8, "L", "||--|{", LINE)
text(462, ly + 1, "1 : N  (최소 1건)", f_legend, BODY)
text(580, ly + 1, "붉은 선 = MEDICAL_CLAIMS 중심 관계   ·   파란 선 = 그 외", f_legend, MUTED)
text(CW - 40, ly + 1, "CLAIM_DETAILS · DISEASES 는 업무상 최소 1건이지만 FK 로는 강제되지 않는다",
     f_legend, MUTED, anchor="ra")

img.save(OUT)
print("saved", OUT, img.size, os.path.getsize(OUT), "bytes")
