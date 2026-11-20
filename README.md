# 潮汐前哨 · Tide Outpost

一款竖屏像素航海动作游戏。拖动舰艇躲避敌人，利用反弹弹球迎击敌潮，在港口收集资源并升级装备。

## 运行游戏

用 Godot 4.7.2 导入根目录的 `project.godot`，按 `F5` 启动。在战斗区任意位置按住拖动即可操控舰艇（相对拖动，手指不会挡住舰艇），桌面端可用鼠标或 WASD。瞄准和弹球回收自动进行，右下角圆形按钮闪避（桌面端空格）。升级时战斗放慢，点一张卡立即生效（桌面端 1/2/3）。

Android 试玩包和 Windows x86-64 版在 [GitHub Releases](https://github.com/GCUSMS-AI-ProJect/goto_game_pixel/releases) 下载。

## 工程目录

| 路径 | 内容 |
| --- | --- |
| `scenes/` | 游戏入口场景 |
| `scripts/game/` | 航行、战斗、强化和港口逻辑 |
| `scripts/ui/`、`scripts/visuals/` | 战斗布局、像素绘制与特效 |
| `scripts/audio/` | 音乐切换与音效管理 |
| `assets/backgrounds/` | 航海图、港口与战斗海域背景 |
| `assets/sprites/` | 舰艇、敌人、资源、港口设施、装备和界面图标 |
| `assets/audio/music/`、`assets/audio/sfx/` | 背景音乐和音效 |
| `assets/branding/`、`assets/fonts/` | 应用图标、字体及字体授权 |
| `docs/screenshots/` | 游戏界面截图 |
| `tools/` | 原声音频生成脚本 |

像素图使用原始分辨率的 PNG，文件名采用小写英文和下划线。字体采用 [SIL Open Font License 1.1](assets/fonts/OFL.txt)。

## 导出

安装与编辑器版本一致的 Godot 导出模板。Android 导出还需要在 Godot 编辑器设置里配置 Android SDK 和 JDK。创建 `dist/` 目录，然后在项目目录运行对应命令。

```text
godot --headless --path . --export-release Windows dist/tide-outpost-windows-x86_64.exe
godot --headless --path . --export-debug Android dist/tide-outpost-android-preview.apk
```

Android 试玩包使用调试签名。正式上架时需配置发布签名，并根据目标商店选择 APK 或 AAB。

重新生成原声音频可在安装 `numpy`、`scipy` 和 `imageio-ffmpeg` 后运行 `python tools/compose_tide.py`。

## 界面预览

<img src="docs/screenshots/home.png" alt="主页" width="225"> <img src="docs/screenshots/battle.png" alt="战斗" width="225"> <img src="docs/screenshots/harbor.png" alt="港口" width="225">
