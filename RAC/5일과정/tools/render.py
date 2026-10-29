# -*- coding: utf-8 -*-
"""그림 렌더러: img_src/*.svg 를 img/*.png 로 만든다 (Chromium, 2배 해상도).

  python3 tools/render.py               바뀐 SVG 만
  python3 tools/render.py 06_rebal.svg  지정한 파일만

SVG 는 viewBox 로 크기를 정하고 글꼴은 Pretendard(본문)·JetBrains Mono(명령)를 쓴다.
"""
import os, sys, glob, re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC, OUT = os.path.join(ROOT, "img_src"), os.path.join(ROOT, "img")


def size(svg):
    m = re.search(r'viewBox="\s*0\s+0\s+([\d.]+)\s+([\d.]+)"', svg)
    if not m:
        raise ValueError("viewBox 없음")
    return int(float(m.group(1))), int(float(m.group(2)))


def main(names):
    files = [os.path.join(SRC, n) for n in names] if names else sorted(glob.glob(os.path.join(SRC, "*.svg")))
    todo = []
    for f in files:
        png = os.path.join(OUT, os.path.basename(f)[:-4] + ".png")
        if names or not os.path.exists(png) or os.path.getmtime(png) < os.path.getmtime(f):
            todo.append((f, png))
    if not todo:
        print("바뀐 SVG 없음")
        return
    args = []
    for f, png in todo:
        args += [f, png]
    subprocess.run(["node", os.path.join(os.path.dirname(os.path.abspath(__file__)), "render.js")] + args, check=True)

if __name__ == "__main__":
    main(sys.argv[1:])
