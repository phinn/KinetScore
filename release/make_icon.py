#!/usr/bin/env python3
"""KinetScore App 图标 1024×1024
同族设计语言:暖纸底(#FBF4EB)+ 琥珀金主题元素
主体:五线谱 + 音符 + 节拍器摆针意象,居中克制,不塞小字
"""
from PIL import Image, ImageDraw, ImageFont
import math

S = 1024
im = Image.new("RGB", (S, S), (251, 244, 235))  # 暖纸
d = ImageDraw.Draw(im)

WARM_DARK = (62, 48, 36)      # #3E3024 五线谱/音符
AMBER = (245, 180, 74)        # #F5B44A accent
AMBER_DEEP = (200, 111, 30)   # #C86F1E

# ---- 顶部暖光渐变(极淡,增加质感)----
for y in range(S):
    t = y / S
    # 上亮下微暗
    f = 1.0 - 0.055 * t
    d.line([(0, y), (S, y)], fill=(int(251*f), int(244*f), int(235*f)))

# ---- 五条五线谱(居中偏下,微透视感:上宽下窄变化极小)----
cy = 560
gap = 66
line_w = 14
xs, xe = 150, 874
for i in range(5):
    y = cy - 2*gap + i*gap
    # 微弧(谱面轻弯,像纸面)
    pts = []
    for x in range(xs, xe+1, 20):
        arc = math.sin((x - xs) / (xe - xs) * math.pi) * 14
        pts.append((x, y + 26 - arc))
    d.line(pts, fill=WARM_DARK, width=line_w)

# ---- 全音符(琥珀金,右侧,踩在第四线上)----
nx, ny = 700, cy - 2*gap + 3*gap - 33  # 音符头中心
# 音符头:旋转椭圆
head = Image.new("RGBA", (300, 300), (0, 0, 0, 0))
hd = ImageDraw.Draw(head)
hd.ellipse([40, 70, 260, 230], fill=AMBER)
head = head.rotate(-18, expand=False, resample=Image.BICUBIC)
im.paste(head, (nx-150, ny-150), head)
# 高光
hl = ImageDraw.Draw(im)
hl.ellipse([nx-62, ny-38, nx-18, ny-6], fill=(255, 214, 140))

# ---- 符干(左上,暖深)----
stem_w = 26
stem_h = 330
d.rounded_rectangle([nx-150-8, ny-stem_h, nx-150-8+stem_w, ny+8], radius=10, fill=WARM_DARK)

# ---- 符尾(飘带,琥珀深)----
flag = Image.new("RGBA", (260, 240), (0,0,0,0))
fd = ImageDraw.Draw(flag)
fd.polygon([(0, 0), (200, 60), (230, 170), (120, 120), (40, 150), (0, 80)], fill=AMBER_DEEP)
flag = flag.rotate(12, expand=True, resample=Image.BICUBIC)
im.paste(flag, (nx-150+stem_w-160, ny-stem_h-30), flag)

# ---- 节拍器摆针弧(左上角,细线,表示 tempo)----
# 以左下为圆心的细弧 + 摆锤点
px, py = 235, 800
d.arc([px-210, py-360, px+210, py+60], start=245, end=295, fill=AMBER_DEEP, width=16)
# 摆锤
d.ellipse([px-58, py-298, px+2, py-238], fill=AMBER_DEEP)

# ---- 左下小节线装饰(克制)----
d.line([(150, cy-2*gap-20), (150, cy+2*gap+20)], fill=WARM_DARK, width=12)

im.save("/Users/phinn/Documents/kinet/KinetScore/release/appicon_1024.png")
print("saved", im.size)
