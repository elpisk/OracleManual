# -*- coding: utf-8 -*-
"""교안 pptx 빌더 — 기존 챕터 pptx 의 서식(다크 타이틀/붉은 헤더 C0392B)을 실측해 재현한다.

마크업
  @TITLE 과정명|주제|부제|제N장
  @SEC 번호|제목            섹션 구분 슬라이드 (이후 '- ' 불릿)
  @SLIDE 제목|캡션          콘텐츠 슬라이드 (캡션 생략 가능, 이후 '- ' 불릿)
  @PLAIN 제목               노트 없는 콘텐츠 슬라이드 (목표/Agenda/퀴즈/요약/실습개요)
  @IMG 파일|제목|캡션        그림 슬라이드 (img/ 의 PNG 를 제목 아래 가운데에 맞춘다)
  @NOTE 텍스트              직전 슬라이드의 발표자 노트
  - 불릿
"""
import io, re, sys, os
from pptx import Presentation
from pptx.util import Emu, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

W, H = 12191695, 6858000
RED = RGBColor(0xC0, 0x39, 0x2B)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
GRAY = RGBColor(0x5A, 0x66, 0x72)
DARK = RGBColor(0x22, 0x22, 0x22)
LGRAY = RGBColor(0xF2, 0xF2, 0xF2)
IMGDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "img")


def clean(t):
    """PPT 에는 마크다운 강조 표시를 남기지 않는다."""
    return t.replace("**", "").replace("`", "")


def _rect(sl, x, y, w, h, color):
    from pptx.enum.shapes import MSO_SHAPE
    s = sl.shapes.add_shape(MSO_SHAPE.RECTANGLE, Emu(x), Emu(y), Emu(w), Emu(h))
    s.fill.solid()
    s.fill.fore_color.rgb = color
    s.line.fill.background()
    s.shadow.inherit = False
    return s


def _tb(sl, x, y, w, h, lines, size, color, bold=False, space=6):
    box = sl.shapes.add_textbox(Emu(x), Emu(y), Emu(w), Emu(h))
    tf = box.text_frame
    tf.word_wrap = True
    for i, ln in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = PP_ALIGN.LEFT
        p.space_after = Pt(space)
        r = p.add_run()
        r.text = clean(ln)
        r.font.name = "맑은 고딕"
        r.font.size = Pt(size)
        r.font.color.rgb = color
        r.font.bold = bold
    return box


class Deck(object):
    def __init__(self):
        self.p = Presentation()
        self.p.slide_width = Emu(W)
        self.p.slide_height = Emu(H)
        self.blank = self.p.slide_layouts[6]

    def _new(self):
        return self.p.slides.add_slide(self.blank)

    def title(self, course, subject, sub, chap):
        s = self._new()
        _rect(s, 0, 0, W, H, WHITE)
        _rect(s, 0, 0, W, 2194560, RED)
        _rect(s, 0, 5394960, W, 1463040, LGRAY)
        _tb(s, 731520, 457200, 10698480, 548640, [course], 16, WHITE, True)
        _tb(s, 731520, 2377440, 10698480, 1554480, subject.split("|"), 34, RED, True)
        _tb(s, 731520, 4114800, 10698480, 1097280, [sub], 15, GRAY)
        _tb(s, 731520, 5577840, 10698480, 914400, [chap], 20, RED, True)
        return s

    def section(self, num, title, bullets):
        s = self._new()
        _rect(s, 0, 0, W, H, RED)
        _tb(s, 822960, 2011680, 10515600, 1097280, [num], 40, WHITE, True)
        _tb(s, 822960, 3017520, 10515600, 914400, [title], 28, WHITE, True)
        _rect(s, 822960, 4114800, 5486400, 54864, WHITE)
        _tb(s, 822960, 4297680, 10058400, 2011680,
            ["•  " + b for b in bullets], 16, WHITE, space=8)
        return s

    def content(self, title, caption, bullets):
        s = self._new()
        _rect(s, 0, 0, W, 1005840, RED)
        _tb(s, 548640, 91440, 10972800, 777240, [title], 26, WHITE, True)
        if caption:
            _tb(s, 640080, 1078992, 10881360, 457200, [caption], 15, GRAY)
            _tb(s, 640080, 1737360, 10881360, 4754880,
                ["•  " + b for b in bullets], 17, DARK, space=10)
        else:
            _tb(s, 640080, 1371600, 10881360, 5120640,
                ["•  " + b for b in bullets], 16, DARK, space=10)
        return s

    def picture(self, fname, title, caption):
        from PIL import Image
        s = self._new()
        _rect(s, 0, 0, W, 1005840, RED)
        _tb(s, 548640, 91440, 10972800, 777240, [title], 26, WHITE, True)
        path = os.path.join(IMGDIR, fname)
        iw, ih = Image.open(path).size
        top, bottom = 1143000, 6217920 if caption else 6583680
        maxw, maxh = W - 2 * 457200, bottom - top
        w = maxw
        h = int(w * ih / iw)
        if h > maxh:
            h = maxh
            w = int(h * iw / ih)
        s.shapes.add_picture(path, Emu((W - w) // 2), Emu(top), Emu(w), Emu(h))
        if caption:
            _tb(s, 640080, 6263640, 10881360, 457200, [caption], 13, GRAY)
        return s

    def note(self, slide, text):
        slide.notes_slide.notes_text_frame.text = clean(text)

    def save(self, path):
        self.p.save(path)


def build(markup, out):
    src = io.open(markup, encoding="utf-8").read().split("\n")
    d = Deck()
    cur, pend, kind, hdr = None, [], None, None

    def flush():
        nonlocal cur, pend, kind, hdr
        if kind is None:
            return
        if kind == "SEC":
            cur = d.section(hdr[0], hdr[1], pend)
        elif kind in ("SLIDE", "PLAIN"):
            cur = d.content(hdr[0], hdr[1], pend)
        pend = []
        kind = None

    for ln in src:
        s = ln.rstrip()
        if not s.strip():
            continue
        if s.startswith("@TITLE "):
            flush()
            a = s[7:].split("|")
            cur = d.title(a[0], a[1], a[2], a[3])
            continue
        if s.startswith("@SEC "):
            flush()
            a = s[5:].split("|")
            kind, hdr = "SEC", (a[0], a[1])
            continue
        if s.startswith("@SLIDE "):
            flush()
            a = s[7:].split("|")
            kind, hdr = "SLIDE", (a[0], a[1] if len(a) > 1 and a[1] else None)
            continue
        if s.startswith("@PLAIN "):
            flush()
            kind, hdr = "PLAIN", (s[7:], None)
            continue
        if s.startswith("@IMG "):
            flush()
            a = s[5:].split("|")
            cur = d.picture(a[0].strip(), a[1].strip(), a[2].strip() if len(a) > 2 else "")
            continue
        if s.startswith("@NOTE "):
            flush()
            d.note(cur, s[6:])
            continue
        if s.startswith("- "):
            pend.append(s[2:])
            continue
        raise ValueError("알 수 없는 줄: %r" % s[:60])
    flush()
    d.save(out)

    p = Presentation(out)
    notes = [len(sl.notes_slide.notes_text_frame.text)
             for sl in p.slides if sl.has_notes_slide
             and sl.notes_slide.notes_text_frame.text.strip()]
    return len(p.slides), len(notes), (min(notes) if notes else 0), (max(notes) if notes else 0)


if __name__ == "__main__":
    n, cnt, lo, hi = build(sys.argv[1], sys.argv[2])
    print("%s  →  슬라이드 %d / 노트 %d개 (%d~%d자)" % (sys.argv[2], n, cnt, lo, hi))
