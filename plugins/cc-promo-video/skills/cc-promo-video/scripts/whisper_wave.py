# 속삭임 장면용 물결 자막 프레임 만들기
# 사용: python3 whisper_wave.py 6.5  (장면 길이 초)
# 필요: pip install pillow, 같은 폴더에 a2z-8.ttf(에이투지체 ExtraBold, ttf 파일. woff2는 Pillow가 못 읽을 수 있어요)
# 결과: shk/s_000.png ... 투명 PNG를 ffmpeg overlay로 영상 위에 얹어요.
# 문장은 아래 lines 를 바꿔요.
import math, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1440, 1080
FPS = 30
L = float(sys.argv[1]) if len(sys.argv) > 1 else 6.54
T_IN, T_OUT = 0.55, L - 0.55
N = round(L * FPS)
AMP = 7.0       # px, gentle
PERIOD = 1.8    # seconds per wave pass
PHASE = 0.32    # radians between neighbouring letters
os.makedirs('shk', exist_ok=True)

font = ImageFont.truetype('a2z-8.ttf', 76)
lines = [[("사실, 이 영상도 이 목소리도", (255, 255, 255))],
         [("전부 ", (255, 255, 255)), ("AI", (255, 181, 71)), ("가 만들었어요", (255, 255, 255))]]
meas = ImageDraw.Draw(Image.new('RGBA', (10, 10)))
lh = 108
top = 540 - lh

# per-glyph layout: (char, x, y, color, index)
glyphs = []
idx = 0
for li, segs in enumerate(lines):
    full = "".join(s for s, _ in segs)
    tw = meas.textlength(full, font=font)
    x0 = (W - tw) / 2
    y = top + li * lh
    pos = 0
    for s, c in segs:
        for ch in s:
            x = x0 + meas.textlength(full[:pos], font=font)
            glyphs.append((ch, x, y, c, idx))
            pos += 1
            idx += 1

for n in range(N):
    t = n / FPS
    a = 0 if t < T_IN else min(1, (t - T_IN) / 0.35)
    if t > T_OUT:
        a = max(0, 1 - (t - T_OUT) / 0.35)
    txt = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    if a > 0:
        d = ImageDraw.Draw(txt)
        for ch, x, y, c, i in glyphs:
            if ch == ' ':
                continue
            dy = -AMP * math.sin(2 * math.pi * t / PERIOD - PHASE * i)
            d.text((x, y + dy), ch, font=font, fill=c + (255,))
        al = txt.split()[3]
        sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        sh.putalpha(al.point(lambda v: int(v * .75)))
        sh = sh.filter(ImageFilter.GaussianBlur(10))
        sh = sh.transform((W, H), Image.AFFINE, (1, 0, 0, 0, 1, -3))
        fr = Image.alpha_composite(sh, txt)
        if a < 1:
            r, g, b, al2 = fr.split()
            fr = Image.merge('RGBA', (r, g, b, al2.point(lambda v: int(v * a))))
    else:
        fr = txt
    fr.save(f'shk/s_{n:03d}.png')
print(N)
