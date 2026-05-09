# CI/CD 构建指南

GitHub Actions 在每次推送 `main` 分支时自动构建 Android APK 和 iOS IPA（Debug），
构建完成后自动发布为 GitHub Release。

---

## 产物

| 文件 | 说明 |
|---|---|
| `app-debug.apk` | Android 调试安装包 |
| `furni_bill-ios-simulator.zip` | iOS 模拟器构建（需 macOS + Xcode 运行） |

---

## 自动发布

每次 push `main` 分支后：

1. GitHub Actions 自动并行构建 Android + iOS
2. 构建成功后自动创建 GitHub Release（标记为 pre-release）
3. Release 命名格式：`v20260509-build1`（日期 + 运行编号）

在仓库的 **Releases** 页面即可下载。

---

## 手动触发

Actions → Build & Release → Run workflow → Run workflow

---

## 安装说明

### Android
直接安装 `app-debug.apk`，需允许「未知来源」安装。

### iOS
模拟器构建解压后拖入 Xcode 的 Simulator 即可运行。
真机安装需使用 Xcode 配置 Apple ID 签名后重新构建。
