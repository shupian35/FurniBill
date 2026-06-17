# 家具备货单 · FurniBill

家具批发行业的移动端开单工具 —— 商品管理、客户管理、快速开单、三联单打印、WebDAV 备份同步，一部手机全搞定。

## 功能

### 仪表盘
- 今日销售额、订单数、实收、欠款一目了然
- 近 7 天销售趋势柱状图
- 从仪表盘直接新建销售单，支持挂单（草稿）

### 商品管理
- 商品基本信息：品名、规格、单位、单价、库存
- 列表搜索与编辑
- 差额补货（订单完成自动扣减库存）

### 客户管理
- 客户基本信息：姓名、手机号、地址
- 列表搜索与编辑
- 开单时快速选择客户，也可即时新增

### 快速开单
- 选客户 → 加商品 → 调数量折扣 → 整单折扣/抹零 → 选收款方式 → 完成
- 支持临时商品（不入库商品直接添加）
- 支持挂单（草稿），草稿上限 20 个，可恢复编辑后完成
- 开单完成自动扣减商品库存

### 收款管理
- 5 种收款方式：现金 / 微信 / 支付宝 / 转账 / 挂账
- 实收与找零自动计算
- 挂账订单欠款追踪

### 三联单打印
- 白联（存根）/ 红联（客户）/ 蓝联（记账）
- 支持 A4 和三等分切纸
- 店铺信息（名称、电话、地址、银行账号）自定义
- 页脚文字可自定义

### 统计报表
- 销售趋势柱状图（按日/按月）
- 支持导出 Excel

### WebDAV 备份同步
- 数据库备份/恢复
- 多设备数据互通
- 支持自动备份（每日/每周）
- 支持坚果云等 WebDAV 服务

### 偏好设置
- 深色模式
- 负库存开关（允许/禁止超库存开单）
- 金额小数位数可配（0~3 位）
- 收款语音播报

## 技术栈

| 层 | 选型 |
|---|---|
| 框架 | Flutter 3.41+（Dart 3.11+）、Material 3 |
| 状态管理 | Provider |
| 本地数据库 | sqflite（SQLite） |
| 持久化配置 | shared_preferences |
| PDF 生成与打印 | pdf + printing |
| 图表 | fl_chart |
| Excel 导出 | excel |
| WebDAV 同步 | webdav_client |
| 平台 | Android / iOS / Windows / macOS / Linux / Web |

## 数据库表结构

| 表名 | 说明 | 关键字段 |
|---|---|---|
| `products` | 商品 | id, name, spec, unit, price, stock, create_time, update_time |
| `customers` | 客户 | id, name, phone, address, create_time, update_time |
| `orders` | 订单 | id, order_no, customer_id, items(JSON), total_amount, discount, receivable, received, owing, status, payment_method, is_draft |
| `payments` | 收款记录 | id, order_id, customer_id, amount, method, create_time |
| `inventory_logs` | 库存流水 | id, product_id, change_amount, after_stock, reason, order_no |
| `backup_metas` | 备份元数据 | id, file_name, device_id, device_name, file_size, create_time |
| `employees` | 操作员 | id, name, phone, role, is_active, create_time |

## 快速开始

```bash
# 安装依赖
flutter pub get

# 运行
flutter run

# 测试
flutter test
```

## 项目结构

```
lib/
├── main.dart                          # 入口，MultiProvider + 5 个底部 Tab
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # 收款方式、订单状态、纸张类型等常量
│   ├── database/
│   │   └── database_helper.dart       # SQLite 建表、升级、通用 CRUD
│   ├── models/
│   │   ├── product.dart               # 商品模型
│   │   ├── customer.dart              # 客户模型
│   │   ├── order.dart                 # 订单 + OrderItem 模型
│   │   ├── payment.dart               # 收款记录模型
│   │   └── backup_meta.dart           # 备份元数据模型
│   ├── providers/
│   │   ├── product_provider.dart      # 商品状态管理
│   │   ├── customer_provider.dart     # 客户状态管理
│   │   ├── order_provider.dart        # 订单状态管理
│   │   └── settings_provider.dart     # 设置状态管理
│   ├── services/                      # 预留服务层
│   └── utils/                         # 预留工具层
├── features/
│   ├── statistics/
│   │   ├── dashboard_page.dart        # 仪表盘（今日概览 + 趋势图）
│   │   └── statistics_page.dart       # 统计报表
│   ├── orders/
│   │   ├── order_list_page.dart       # 订单列表
│   │   ├── order_create_page.dart     # 新建/编辑销售单
│   │   ├── order_detail_page.dart     # 订单详情
│   │   └── draft_list_page.dart       # 草稿列表
│   ├── products/
│   │   ├── product_list_page.dart     # 商品列表
│   │   └── product_edit_page.dart     # 商品编辑
│   ├── customers/
│   │   ├── customer_list_page.dart    # 客户列表
│   │   └── customer_edit_page.dart    # 客户编辑
│   ├── printing/
│   │   └── print_preview_page.dart    # PDF 预览与打印
│   ├── settings/
│   │   ├── settings_page.dart         # 设置主页
│   │   ├── shop_info_page.dart        # 店铺信息
│   │   └── print_settings_page.dart   # 打印设置
│   └── sync/
│       └── webdav_page.dart           # WebDAV 备份同步
└── widgets/
    └── common/
        └── widgets.dart               # 通用组件（搜索栏、金额文本、状态标签等）
```

## CI/CD

推送 `main` 分支自动触发 GitHub Actions，并行构建 Android APK 和 iOS IPA（Debug），
构建完成后自动发布为 GitHub Release（pre-release）。

产物可直接在 [Releases](https://github.com/shupian35/FurniBill/releases) 页面下载。

## License

MIT
