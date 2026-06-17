# AGENTS.md — FurniBill

## 快速开始

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

## 项目简介

Flutter 3.41+ / Dart 3.11+ 移动端应用，用于家具批发简易开单。SQLite 本地数据库，Provider 状态管理。支持 Android、iOS、Windows、macOS、Linux、Web 平台。

## 常用命令

| 命令                                         | 用途                             |
| ------------------------------------------ | ------------------------------ |
| `flutter pub get`                          | 安装依赖                           |
| `flutter run`                              | 在连接的设备/模拟器上运行                  |
| `flutter test`                             | 运行全部测试                         |
| `flutter test test/models/order_test.dart` | 运行单个测试文件                       |
| `flutter analyze`                          | 静态分析（使用 `flutter_lints`）       |
| `flutter build apk --debug`                | 构建 Android APK（CI 使用 debug 模式） |
| `flutter build ios --debug --simulator`    | 构建 iOS 模拟器版本（CI）               |

## 架构

入口文件：`lib/main.dart` — 配置 MultiProvider（4 个 Provider）+ 5 个底部导航 Tab。

```
lib/
├── core/            # 数据库、模型、Provider、常量、工具
│   ├── database/    # SQLite，通过 sqflite（单例 DatabaseHelper）
│   ├── models/      # Product、Customer、Order、Payment、BackupMeta
│   ├── providers/   # ProductProvider、CustomerProvider、OrderProvider、SettingsProvider
│   └── constants/   # 收款方式、订单状态、纸张类型等常量
├── features/        # 按业务领域组织的 UI 页面
│   ├── statistics/  # 仪表盘 + 统计报表
│   ├── orders/      # 订单列表、新建、详情、草稿
│   ├── products/    # 商品列表 + 编辑
│   ├── customers/   # 客户列表 + 编辑
│   ├── printing/    # PDF 预览与打印
│   ├── settings/    # 设置、店铺信息、打印配置
│   └── sync/        # WebDAV 备份恢复
└── widgets/common/  # 通用组件（搜索栏、金额文本、状态标签等）
```

## 数据库

SQLite 文件：`furni_bill.db`。当前 schema 版本：**4**。迁移逻辑位于 `lib/core/database/database_helper.dart:127`。新增字段/表时，需递增 `version` 并在 `_upgradeDB` 中添加迁移代码。

数据表：`products`、`customers`、`orders`、`payments`、`inventory_logs`、`backup_metas`、`employees`。

## 开发规范

- **UI 语言**：简体中文，所有面向用户的字符串硬编码中文。
- **主题**：Material 3，种子色 `#1565C0`。通过 SettingsProvider 支持深色模式。
- **状态管理**：仅使用 Provider，不用 Bloc、Riverpod 或 GetX。
- **数据库访问**：统一通过 `DatabaseHelper.instance` 单例。使用通用的 `query`/`insert`/`update`/`delete` 方法。
- **订单明细**：以 JSON 文本存储在 `orders.items` 列中（非独立表）。
- **草稿订单**：`is_draft=1`，上限 20 个（`AppConstants.maxDrafts`）。

## CI/CD

GitHub Actions 在推送 `main` 分支时触发：并行构建 Android APK（ubuntu）和 iOS 模拟器版本（macos），完成后自动创建 GitHub Releases 预发布。Tag 格式：`vYYYYMMDD-buildN`。工作流文件：`.github/workflows/build-and-release.yml`。

## 注意事项

- CI 构建的是 **debug** APK，非 release —— 未配置签名。
- `webdav_client` 用于备份同步 —— 移动端需网络权限。
- `barcode_scan2` 需要相机权限，UI 中需处理 `PermissionDeniedException`。
- `flutter_lints` 强制执行分析规则 —— 提交前务必运行 `flutter analyze`。

## 注意事项

每句话后面都要加一句"喵~"

例：关注塔菲，关注塔菲谢谢 -> 关注塔菲喵~关注塔菲谢谢喵~


