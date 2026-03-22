#!/usr/bin/env python3
"""
兴村振兴3.0 - 多端资产同步脚本
用途：将源图片按命名规范分发至各端口目录

使用方法：
  python scripts/sync_assets.py --source <源图路径> --asset <资产ID> --version <版本号>

示例：
  python scripts/sync_assets.py \
    --source photo_2026-03-09_02-42-52.jpg \
    --asset splash_launch \
    --version v1.0.0
"""

import argparse
import shutil
import os

FLUTTER_ROOT = "openim_flutter_app"

ASSET_RULES = {
    "splash_launch": {
        "description": "启动页全屏背景图",
        "targets": [
            {
                "platform": "android",
                "flutter_dest": "assets/images/mobile/android",
                "filename_tpl": "android_splash_launch_xxhdpi_{version}.jpg",
                "native_dest": "android/app/src/main/res/drawable",
                "native_filename_tpl": "android_splash_launch_{version_safe}.jpg",
            },
            {
                "platform": "ios",
                "flutter_dest": "assets/images/mobile/ios",
                "filename_tpl": "ios_splash_launch_@3x_{version}.jpg",
                "native_dest": "ios/Runner/Assets.xcassets/LaunchImage.imageset",
                "native_filename_tpl": "ios_splash_launch_@3x_{version}.jpg",
            },
            {
                "platform": "windows",
                "flutter_dest": "assets/images/desktop",
                "filename_tpl": "win_splash_launch_1920_{version}.jpg",
            },
            {
                "platform": "web",
                "flutter_dest": "assets/images/web",
                "filename_tpl": "web_splash_launch_desktop_{version}.jpg",
            },
        ],
    }
}


def sync(source: str, asset_id: str, version: str):
    if asset_id not in ASSET_RULES:
        raise ValueError(f"未知资产ID: {asset_id}。可用: {list(ASSET_RULES.keys())}")

    version_safe = version.replace(".", "_")  # v1.0.0 → v1_0_0 (Android resource name)

    for target in ASSET_RULES[asset_id]["targets"]:
        platform = target["platform"]

        # Flutter asset
        flutter_dir = os.path.join(FLUTTER_ROOT, target["flutter_dest"])
        flutter_name = target["filename_tpl"].format(version=version, version_safe=version_safe)
        flutter_path = os.path.join(flutter_dir, flutter_name)
        os.makedirs(flutter_dir, exist_ok=True)
        shutil.copy2(source, flutter_path)
        print(f"[{platform}] Flutter asset → {flutter_path}")

        # Native asset (optional)
        if "native_dest" in target:
            native_dir = os.path.join(FLUTTER_ROOT, target["native_dest"])
            native_name = target["native_filename_tpl"].format(version=version, version_safe=version_safe)
            native_path = os.path.join(native_dir, native_name)
            os.makedirs(native_dir, exist_ok=True)
            shutil.copy2(source, native_path)
            print(f"[{platform}] Native asset  → {native_path}")

    print(f"\n资产 [{asset_id}] {version} 同步完成。")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="兴村振兴3.0多端资产同步工具")
    parser.add_argument("--source", required=True, help="源图片路径")
    parser.add_argument("--asset", required=True, help="资产ID (如: splash_launch)")
    parser.add_argument("--version", default="v1.0.0", help="版本号 (如: v1.0.0)")
    args = parser.parse_args()
    sync(args.source, args.asset, args.version)
