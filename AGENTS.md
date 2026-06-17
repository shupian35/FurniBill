# AGENTS.md — FurniBill

## 快速开始

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

## 项目简介

Flutter 3.41+ / Dart 3.11+ 移动端应用，用于家具批发进销存管理。SQLite 本地数据库，Provider 状态管理。支持 Android、iOS、Windows、macOS、Linux、Web 平台喵~

## 常用命令

| 命令                                         | 用途                             |
| ------------------------------------------ | ------------------------------ |
| `flutter pub get`                          | 安装依赖                           |
| `flutter run`                              | 在连接的设备/模拟器上运行                  |
| `flutter test`                             | 运行全部测试                         |
| `flutter test test/models/order_test.dart` | 运行单个测试文件                       |
| `flutter analyze`                          | 静态分析（使用 `flutter_lints`）       |
| `flutter analyze --no-fatal-infos`         | 静态分析（忽略 info 级别提示）          |
| `flutter build apk --debug`                | 构建 Android APK（CI 使用 debug 模式） |
| `flutter build ios --debug --simulator`    | 构建 iOS 模拟器版本（CI）               |

## 架构

入口文件：`lib/main.dart` — 配置 MultiProvider（8 个 Provider）+ 5 个底部导航 Tab。

```
lib/
├── core/            # 数据库、模型、Provider、常量、工具
│   ├── database/    # SQLite，通过 sqflite（单例 DatabaseHelper）
│   ├── models/      # Product、Customer、Order、Payment、BackupMeta、Category、Warehouse、PurchaseOrder、ReturnOrder、InventoryCheck、CustomerPrice、Member
│   ├── providers/   # ProductProvider、CustomerProvider、OrderProvider、SettingsProvider、CategoryProvider、WarehouseProvider、PurchaseProvider、ReturnProvider、MemberProvider
│   └── constants/   # 收款方式、订单状态、纸张类型等常量
├── features/        # 按业务领域组织的 UI 页面
│   ├── statistics/  # 仪表盘 + 统计报表 + 对账单 + 库存预警
│   ├── orders/      # 订单列表、新建、详情、草稿
│   ├── purchases/   # 采购订单列表、新建
│   ├── returns/     # 退货订单列表、新建
│   ├── inventory/   # 库存盘点
│   ├── products/    # 商品列表 + 编辑 + 分类管理
│   ├── customers/   # 客户列表 + 编辑
│   ├── members/     # 会员管理
│   ├── printing/    # PDF 预览与打印
│   ├── settings/    # 设置、店铺信息、打印配置、仓库管理、打印模板
│   └── sync/        # WebDAV 备份恢复
└── widgets/common/  # 通用组件（搜索栏、金额文本、状态标签等）
```

## 数据库

SQLite 文件：`furni_bill.db`。当前 schema 版本：**8**。迁移逻辑位于 `lib/core/database/database_helper.dart`。新增字段/表时，需递增 `version` 并在 `_upgradeDB` 中添加迁移代码喵~

数据表：`products`、`customers`、`orders`、`payments`、`inventory_logs`、`backup_metas`、`employees`、`categories`、`warehouses`、`purchase_orders`、`return_orders`、`inventory_checks`、`inventory_check_items`、`customer_prices`、`members`喵~

## 开发规范

- **UI 语言**：简体中文，所有面向用户的字符串硬编码中文喵~
- **主题**：Material 3，种子色 `#1565C0`。通过 SettingsProvider 支持深色模式喵~
- **状态管理**：仅使用 Provider，不用 Bloc、Riverpod 或 GetX喵~
- **数据库访问**：统一通过 `DatabaseHelper.instance` 单例。使用通用的 `query`/`insert`/`update`/`delete` 方法喵~
- **订单明细**：以 JSON 文本存储在 `orders.items` 列中（非独立表）喵~
- **草稿订单**：`is_draft=1`，上限 20 个（`AppConstants.maxDrafts`）喵~
- **模型命名**：避免与 Flutter 内置类名冲突（如 `Category` 使用 `import ... as models` 前缀）喵~

## CI/CD

GitHub Actions 工作流：`.github/workflows/build-and-release.yml`喵~

1. **测试阶段**：`flutter analyze --no-fatal-infos` + `flutter test`喵~
2. **构建阶段**：并行构建 Android APK（ubuntu）和 iOS IPA（macos）喵~
3. **发布阶段**：自动创建 GitHub Releases 预发布喵~

Tag 格式：`v{版本}-beta.{日期}.{运行号}`（如 `v1.0.0-beta.20260617.1`）喵~

产物：`furni_bill.apk`（Android）、`furni_bill.ipa`（iOS 无签名包）喵~

## 功能模块

| 模块 | 说明 |
|------|------|
| 仪表盘 | 今日概览、销售趋势、库存预警入口 |
| 订单管理 | 销售开单、草稿、订单列表、详情 |
| 采购管理 | 采购开单、入库、供应商管理 |
| 退货管理 | 销售退货、采购退货 |
| 商品管理 | 商品列表、编辑、分类、图片、条码 |
| 客户管理 | 客户列表、编辑、分级、信用额度 |
| 会员管理 | 会员列表、积分、等级 |
| 库存管理 | 库存盘点、库存预警 |
| 统计报表 | 销售趋势、客户对账单 |
| 打印功能 | 三联单、自定义模板 |
| 设置 | 店铺信息、打印配置、仓库管理 |
| 备份同步 | WebDAV 数据库备份/恢复 |

## 注意事项

- CI 构建的是 **debug** APK/IPA，非 release —— 未配置签名喵~
- `webdav_client` 用于备份同步 —— 移动端需网络权限喵~
- `barcode_scan2` 需要相机权限，UI 中需处理 `PermissionDeniedException`喵~
- `flutter_lints` 强制执行分析规则 —— 提交前务必运行 `flutter analyze`喵~
- `flutter analyze` 会因 info 级别提示返回非零退出码 —— CI 使用 `--no-fatal-infos` 忽略喵~
