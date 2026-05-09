# CI/CD 构建指南

GitHub Actions 在每次推送 `main` 分支时自动构建 Android APK 和 iOS IPA（Debug），
构建完成后自动发布为 GitHub Release。

---

## 产物

| 文件 | 说明 |
|---|---|
| `app-debug.apk` | Android 调试安装包 |
| `furni_bill-debug.ipa` | iOS 调试安装包（未签名，需自行签名安装） |

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
未签名 IPA 需要通过 AltStore / Sideloadly 等工具签名后安装，
或使用 Apple Developer 账号自行签名。
