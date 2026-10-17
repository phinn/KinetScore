#!/usr/bin/env python3
"""KinetScore ASC 截图合成:
- 6.9" 槽 1320×2868:暖纸品牌画布 + 手机帧 + 特性行(同族 DuoFolio 风格,过审优先)
- Duo 槽 2007×2853:对开语义双栏(素材源:DeviceHub 展开态)
铁律:亮色暖纸底、禁裸截图直出
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import os, sys

S = "/Users/phinn/Documents/kinet/KinetScore/release/screenshots"
T = "/private/tmp"
PAPER = (251, 244, 235)   # 暖纸(与 app Theme nsColor 一致)
INK = (52, 42, 32)
ACCENT = (176, 108, 46)   # 琥珀金

def font(sz, bold=False):
    for p in ["/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/STHeiti Medium.ttc"]:
        if os.path.exists(p):
            try: return ImageFont.truetype(p, sz, index=1 if bold else 0)
            except Exception: pass
    return ImageFont.load_default()

def text_c(d, xy, s, f, fill):
    w = d.textlength(s, font=f)
    d.text((xy[0] - w/2, xy[1]), s, font=f, fill=fill)

def rounded_shadow(canvas, img, box, radius):
    x, y, w, h = box
    sh = Image.new("RGBA", canvas.size, (0,0,0,0))
    sd = ImageDraw.Draw(sh)
    sd.rounded_rectangle([x+6, y+14, x+w+6, y+h+14], radius, fill=(90, 60, 30, 70))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(sh, (0, 0), sh)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0]-1, img.size[1]-1], radius, fill=255)
    canvas.paste(img.convert("RGB"), (x, y), mask.resize(img.size))

def fit_h(img, h):
    w = int(img.width * h / img.height)
    return img.resize((w, h), Image.LANCZOS)

def footer_rows(d, y, W, rows, spacing=150):
    f1, f2 = font(46, True), font(34)
    for t, sub in rows:
        text_c(d, (W/2, y), t, f1, INK)
        text_c(d, (W/2, y+62), sub, f2, (126, 108, 90))
        y += spacing

def phone_body(src):
    """1320×2868 模拟器截图 → 带圆角阴影的机身(含黑边框)"""
    im = Image.open(src).convert("RGB")
    W, H = 760, 1652  # 机身内容尺寸(约 1320:2868 比例 0.46,含细黑边)
    im = im.resize((W-12, H-12), Image.LANCZOS)
    body = Image.new("RGB", (W, H), (24, 22, 20))
    body.paste(im, (6, 6))
    return body

def shot_69(title, subtitle, src, rows, out):
    W, H = 1320, 2868
    c = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(c)
    d.rectangle([0, 0, W, 16], fill=ACCENT)
    text_c(d, (W/2, 110), title, font(108, True), INK)
    text_c(d, (W/2, 260), subtitle, font(50), (132, 112, 92))
    body = phone_body(src)
    rounded_shadow(c, body, ((W-body.width)//2, 400, body.width, body.height), 52)
    d = ImageDraw.Draw(c)
    y0 = 400 + body.height + 60
    footer_rows(d, y0, W, rows, spacing=150)
    c.convert("RGB").save(f"{S}/{out}")
    print(out, c.size, os.path.getsize(f"{S}/{out}"))

def tablet_body(src):
    """iPad 截图 → 带圆角阴影的平板机身"""
    im = Image.open(src).convert("RGB")
    W, H = 1400, 1049  # 2752x2064 比例
    im = im.resize((W-12, H-12), Image.LANCZOS)
    body = Image.new("RGB", (W, H), (24, 22, 20))
    body.paste(im, (6, 6))
    return body

def shot_ipad(title, subtitle, src, rows, out):
    W, H = 2048, 2732
    c = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(c)
    d.rectangle([0, 0, W, 20], fill=ACCENT)
    text_c(d, (W/2, 140), title, font(150, True), INK)
    text_c(d, (W/2, 360), subtitle, font(66), (132, 112, 92))
    body = tablet_body(src)
    rounded_shadow(c, body, ((W-body.width)//2, 520, body.width, body.height), 52)
    d = ImageDraw.Draw(c)
    y0 = 520 + body.height + 90
    footer_rows(d, y0, W, rows, spacing=170)
    c.convert("RGB").save(f"{S}/{out}")
    print(out, c.size, os.path.getsize(f"{S}/{out}"))

# ① 曲库主图
shot_69(
    "乐谱库,一屏尽览",
    "本地导入 · 纯离线 · 折叠屏优化",
    f"{T}/ks69_library_v3.png",
    [("零网络权限", "无账号 · 无追踪 · 全离线"),
     ("元数据编目", "作曲家 · 页数 · BPM 自动索引"),
     ("iPhone Duo 就绪", "合盖书签卡 · 对开大谱")],
    "asc_69_01.png")

# ② 阅读器
shot_69(
    "大屏读谱,翻页即达",
    "高清渲染 · 页码记忆 · 手感翻页",
    f"{T}/ks69_reader.png",
    [("页码常驻", "1/6 实时可见,合盖不丢位置"),
     ("节拍器内置", "BPM 随谱存储,练习不打断"),
     ("暖纸护眼", "纸感底色,舞台灯下也清晰")],
    "asc_69_02.png")

print("DONE")

# ===== iPad 13" (2048×2732) 三张 =====
shot_ipad(
    "乐谱库,一屏尽览",
    "本地导入 · 纯离线 · 折叠屏优化",
    f"{T}/ksipad_library_final.png",
    [("零网络权限", "无账号 · 无追踪 · 全离线"),
     ("元数据编目", "作曲家 · 页数 · BPM 自动索引"),
     ("大屏适配", "iPad 全屏铺开读谱")],
    "asc_ipad_01.png")

shot_ipad(
    "大屏读谱,翻页即达",
    "高清渲染 · 页码记忆 · 手感翻页",
    f"{T}/ksipad_reader_final.png",
    [("页码常驻", "1/6 实时可见,合盖不丢位置"),
     ("节拍器内置", "BPM 随谱存储,练习不打断"),
     ("暖纸护眼", "纸感底色,舞台灯下也清晰")],
    "asc_ipad_02.png")

shot_ipad(
    "翻页如纸,页码常驻",
    "2/6 实时可见 · 节拍器同屏 · 续读不丢",
    f"{T}/ksipad_p2_final.png",
    [("页码常驻", "翻到哪一眼看到,合盖也不丢"),
     ("节拍器内置", "BPM 随谱存储,练习不打断"),
     ("手势翻页", "轻扫即达,舞台上一只手搞定")],
    "asc_ipad_03.png")
