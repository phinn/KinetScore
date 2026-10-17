#!/usr/bin/env python3
"""往生成的 KinetScore.xcscheme 里注入 StoreKitConfigurationFileReference(xcodegen 不写,坑已记)。

幂等:已含 StoreKitConfiguration 则跳过。由 project.yml options.postGenCommand 自动调用,
xcodegen generate 冲掉 scheme 后会自动补回。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # scripts/ → KinetScore/
SCHEME = ROOT / "KinetScore.xcodeproj/xcshareddata/xcschemes/KinetScore.xcscheme"
# scheme 文件位于 KinetScore.xcodeproj/xcshareddata/xcschemes/,相对它到 Products/ 需要 ../../../
IDENTIFIER = "../../../Products/KinetScore.storekit"

REF_BLOCK = f"""      <StoreKitConfigurationFileReference
         identifier = "{IDENTIFIER}">
      </StoreKitConfigurationFileReference>
"""

def main() -> int:
    if not SCHEME.exists():
        print(f"[storekit_scheme_patch] scheme 不存在: {SCHEME}", file=sys.stderr)
        return 1
    text = SCHEME.read_text()
    if "StoreKitConfigurationFileReference" in text:
        return 0
    if "<LaunchAction" not in text:
        print("[storekit_scheme_patch] scheme 里找不到 LaunchAction", file=sys.stderr)
        return 1
    text = text.replace("<LaunchAction", REF_BLOCK + "   <LaunchAction", 1)
    SCHEME.write_text(text)
    print("[storekit_scheme_patch] 已注入 StoreKit 配置引用")
    return 0

if __name__ == "__main__":
    sys.exit(main())
