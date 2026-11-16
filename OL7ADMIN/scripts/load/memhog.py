# -*- coding: utf-8 -*-
"""메모리 압박용 프로그램 (18장 실습 02). OL 7.9 기본 python 2.7 로 돈다.

    python memhog.py MB 초 [1]

MB 만큼 50MB 씩 0.1초 간격으로 잡고, 초 동안 들고 있다가 끝난다.
세 번째 인자 1 을 주면 잡은 페이지를 계속 건드려(4KB 마다 1바이트 쓰기) 스왑에서 다시 읽게 만든다.
프로세스 이름을 다르게 보이려면 python 에 심볼릭 링크를 걸어 그 이름으로 부른다(mem-load.sh).
"""
import sys
import time

mb, secs = int(sys.argv[1]), int(sys.argv[2])
touch = len(sys.argv) > 3 and sys.argv[3] == "1"
blk = []
for i in range(mb // 50):
    blk.append(bytearray(50 << 20))
    time.sleep(0.1)
end = time.time() + secs
while time.time() < end:
    if touch:
        for b in blk:
            for off in range(0, len(b), 4096):
                b[off] = 1
    else:
        time.sleep(1)
