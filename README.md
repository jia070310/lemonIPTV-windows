# lemonIPTV-windows（柠檬 TV · Windows 桌面版）

基于 Flutter 的 Windows IPTV 直播客户端，支持 M3U / TXT 订阅、EPG、自定义 User-Agent 等。本仓库为 **Windows 桌面端源码**；发布包与版本信息见 [Releases](https://github.com/jia070310/lemonIPTV-windows/releases)。

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](README-en.md)

## 功能概览（Windows）

- **双播放内核**：默认 **mpv（media_kit）**，可选 **VLC（dart_vlc）**；在 **设置 → 播放器设置** 中手动切换。
- **解码异常自动切换**：检测到疑似解码相关错误时，自动尝试切换到另一内核并重试播放。
- **优先软解**：在播放器设置中开启（mpv / VLC 均会尽量遵循）；修改后建议 **换台或重新打开当前频道** 生效。
- **订阅与解析**：支持 `.m3u`、`.txt`、本地文件与远程订阅；频道合并、分组、换台快捷键等与其他端一致。
- **自动更新**：应用通过仓库根目录的 [`versions.json`](versions.json) 获取 Windows 端版本与下载地址（发布新版本时请同步更新该文件与 [Releases](https://github.com/jia070310/lemonIPTV-windows/releases)）。

> 说明：**TV / Android 大屏** 等场景在本分支中仍以 mpv 为主；VLC 内核主要面向 **Windows / Linux 桌面**（以工程内 `isVlcPlaybackSupported` 为准）。

## 环境要求

- Windows 10/11 x64
- [Flutter](https://docs.flutter.dev/get-started/install/windows)（SDK 与 `pubspec.yaml` 中 `environment.sdk` 一致，当前为 **^3.8.1**）
- 已安装 **Visual Studio** 并勾选 **使用 C++ 的桌面开发**（含 MSVC、Windows SDK），用于编译 Windows 与原生插件

## 克隆与依赖

```bash
git clone https://github.com/jia070310/lemonIPTV-windows.git
cd lemonIPTV-windows
flutter pub get
```

> `dart_vlc` 会拉取较旧的 `audio_video_progress_bar` 约束；本仓库在 `pubspec.yaml` 中使用 **`dependency_overrides`** 固定到 `audio_video_progress_bar ^2.0.3`，以兼容当前 Flutter 的 `TextTheme` API，无需额外操作。

## 构建

调试运行：

```bash
flutter run -d windows
```

发布构建（产物在 `build\windows\x64\runner\Release\`，需整目录分发）：

```bash
flutter build windows --release
```

可选指定版本号：

```bash
flutter build windows --release --build-name=1.1.5 --build-number=10105
```

## 版本与更新配置

根目录 **`versions.json`** 字段说明：

| 字段 | 含义 |
|------|------|
| `latest_version` | 最新版本号（字符串，与应用一致） |
| `download_url` | Windows 安装包或压缩包直链（通常指向 GitHub Release 资源） |
| `update_log` | 更新说明列表（展示给用户） |
| `min_version` | 最低可用版本 |
| `force_update` | 是否强制更新 |

发布新版本时：在 [Releases](https://github.com/jia070310/lemonIPTV-windows/releases) 上传构建产物 → 更新 `download_url` 与上述字段 → 提交到默认分支。

## 相关链接

- 本仓库：<https://github.com/jia070310/lemonIPTV-windows>
- 节目源参考：[IPTV-ORG](https://github.com/iptv-org/iptv)

## 许可与致谢

若上游有单独许可证文件，以仓库内 **LICENSE** 为准。感谢 [media-kit](https://github.com/media-kit/media-kit)、[dart_vlc](https://pub.dev/packages/dart_vlc) 等开源项目。
