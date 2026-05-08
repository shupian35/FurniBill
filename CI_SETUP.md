# CI/CD 签名配置指南

GitHub Actions 已配置为自动构建 Android APK/AAB 和 iOS IPA。
要启用 Release 签名，需在仓库设置中添加以下 Secrets。

---

## Android 签名（Google Play 上架必需）

### 1. 生成上传密钥

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storetype JKS
```

按提示填写信息，记录好密码和别名。

### 2. 编码并上传到 GitHub Secrets

```bash
# 将 keystore 文件编码为 base64
base64 -i upload-keystore.jks

# Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

在 GitHub 仓库 → Settings → Secrets and variables → Actions，添加：

| Secret 名称 | 值 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | 上一步输出的 base64 字符串 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 密钥别名（如 `upload`） |
| `ANDROID_KEY_PASSWORD` | 密钥密码 |

---

## iOS 签名（App Store 上架必需）

需要 Apple Developer 账号（$99/年）。

### 步骤

1. 在 [Apple Developer](https://developer.apple.com) 创建 App ID 和分发证书
2. 导出证书为 `.p12` 文件（含私钥）
3. 下载 `.mobileprovision` 配置文件

```bash
# 编码证书
base64 -i distribution.p12

# 编码配置文件
base64 -i build.mobileprovision
```

在 GitHub Secrets 中添加：

| Secret 名称 | 值 |
|---|---|
| `IOS_P12_BASE64` | p12 证书的 base64 |
| `IOS_P12_PASSWORD` | p12 证书密码 |
| `IOS_PROVISION_PROFILE_BASE64` | mobileprovision 的 base64 |

### 手动触发签名构建

Actions → iOS Build → Run workflow → 勾选 `codesign` → Run workflow

---

## 默认行为

- **未配置 Secrets 时**：自动使用 debug 签名构建，可用于内部测试
- **push main 分支**：自动触发 Android Release 构建（有 Secret 则签名）
- **手动触发**：Actions 页面选择 build_type（debug/release/both）

## 下载构建产物

Actions → 选择某次运行 → Artifacts → 下载对应文件：
- `app-debug` — 调试 APK（7 天保留）
- `app-release` — 正式 APK（30 天保留）
- `app-release-aab` — Google Play 上架 AAB（90 天保留）
- `ios-release` — iOS IPA（30 天保留）
