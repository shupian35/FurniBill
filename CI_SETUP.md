# CI/CD 构建指南

GitHub Actions 在每次推送 `main` 分支时自动运行：测试 → 构建 → 发布。

---

## 流程

```
push main → 测试（analyze + test）→ 并行构建 → 发布 Release
                              ↓           ↓
                        Android APK   iOS IPA
```

---

## 产物

| 文件 | 说明 |
|---|---|
| `furni_bill.apk` | Android 调试安装包 |
| `furni_bill.ipa` | iOS 模拟器构建（需 macOS + Xcode 运行） |

---

## 自动发布

每次 push `main` 分支后：

1. 运行 `flutter analyze` 和 `flutter test`
2. 并行构建 Android APK + iOS IPA
3. 自动创建 GitHub Release（标记为 pre-release）
4. Release 命名格式：`v{版本}-beta.{日期}.{运行号}`

在仓库的 **Releases** 页面即可下载。

---

## 手动触发

Actions → Build & Release → Run workflow → Run workflow

---

## 安装说明

### Android
直接安装 `furni_bill.apk`，需允许「未知来源」安装。

### iOS
模拟器构建解压后拖入 Xcode 的 Simulator 即可运行。
真机安装需使用 Xcode 配置 Apple ID 签名后重新构建。
