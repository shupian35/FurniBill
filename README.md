# 家具备货单 · FurniBill

家具批发行业的移动端进销存工具 —— 商品管理、客户管理、快速开单、采购管理、退货处理、库存盘点、三联单打印、WebDAV 备份同步，一部手机全搞定。

## 功能

### 仪表盘
- 今日销售额、订单数、实收、欠款一目了然
- 近 7 天销售趋势柱状图
- 从仪表盘直接新建销售单，支持挂单（草稿）
- 库存预警提醒

### 商品管理
- 商品基本信息：品名、规格、单位、单价、成本价、库存、条码、图片
- 商品分类管理
- 列表搜索与编辑
- 差额补货（订单完成自动扣减库存）
- 库存预警（设置最低库存）

### 客户管理
- 客户基本信息：姓名、手机号、地址
- 客户分级：普通、VIP、代理、批发商
- 信用额度、账期管理
- 列表搜索与编辑
- 开单时快速选择客户，也可即时新增

### 快速开单
- 选客户 → 加商品 → 调数量折扣 → 整单折扣/抹零 → 选收款方式 → 完成
- 支持临时商品（不入库商品直接添加）
- 支持挂单（草稿），草稿上限 20 个，可恢复编辑后完成
- 开单完成自动扣减商品库存
- 客户专属价格

### 采购管理
- 采购开单：供应商信息、商品选择、入库
- 采购列表：查看历史采购记录
- 入库自动增加库存

### 退货管理
- 销售退货：从原订单选择退货商品
- 采购退货：退回供应商
- 退货自动调整库存

### 收款管理
- 5 种收款方式：现金 / 微信 / 支付宝 / 转账 / 挂账
- 实收与找零自动计算
- 挂账订单欠款追踪

### 库存管理
- 库存盘点：系统库存 vs 实际库存，自动计算差异
- 库存预警：低于最低库存的商品提醒
- 多仓库支持

### 三联单打印
- 白联（存根）/ 红联（客户）/ 蓝联（记账）
- 支持 A4 和三等分切纸
- 自定义打印模板（默认、紧凑、详细）
- 店铺信息（名称、电话、地址、银行账号）自定义
- 页脚文字可自定义

### 统计报表
- 销售趋势柱状图（按日/按月）
- 客户对账单
- 支持导出 Excel

### 会员管理
- 会员列表、积分、等级
- 关联客户信息

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
- 仓库管理
- 打印模板选择

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
| `products` | 商品 | id, name, spec, unit, price, cost_price, stock, min_stock, category_id, image_url, barcode, warehouse_id |
| `customers` | 客户 | id, name, phone, address, tier, credit_limit, due_days, total_owing |
| `orders` | 订单 | id, order_no, customer_id, items(JSON), total_amount, discount, receivable, received, owing, status, payment_method, is_draft |
| `payments` | 收款记录 | id, order_id, customer_id, amount, method, create_time |
| `inventory_logs` | 库存流水 | id, product_id, change_amount, after_stock, reason, order_no |
| `backup_metas` | 备份元数据 | id, file_name, device_id, device_name, file_size, create_time |
| `employees` | 操作员 | id, name, phone, role, permissions, is_active, create_time |
| `categories` | 商品分类 | id, name, parent_id, sort_order |
| `warehouses` | 仓库 | id, name, address, phone, is_default |
| `purchase_orders` | 采购订单 | id, order_no, supplier_name, warehouse_id, items(JSON), total_amount, paid_amount, owing_amount, status |
| `return_orders` | 退货订单 | id, order_no, type, original_order_id, items(JSON), total_amount, status, reason |
| `inventory_checks` | 盘点记录 | id, check_no, warehouse_id, status, remark |
| `inventory_check_items` | 盘点明细 | id, check_id, product_id, system_stock, actual_stock, difference |
| `customer_prices` | 客户价格 | id, customer_id, product_id, price |
| `members` | 会员 | id, customer_id, member_no, name, phone, points, level |

## 快速开始

```bash
# 安装依赖
flutter pub get

# 运行
flutter run

# 测试
flutter test

# 静态分析
flutter analyze
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
│   │   ├── backup_meta.dart           # 备份元数据模型
│   │   ├── category.dart              # 商品分类模型
│   │   ├── warehouse.dart             # 仓库模型
│   │   ├── purchase_order.dart        # 采购订单模型
│   │   ├── return_order.dart          # 退货订单模型
│   │   ├── inventory_check.dart       # 盘点模型
│   │   ├── customer_price.dart        # 客户价格模型
│   │   └── member.dart                # 会员模型
│   ├── providers/
│   │   ├── product_provider.dart      # 商品状态管理
│   │   ├── customer_provider.dart     # 客户状态管理
│   │   ├── order_provider.dart        # 订单状态管理
│   │   ├── settings_provider.dart     # 设置状态管理
│   │   ├── category_provider.dart     # 分类状态管理
│   │   ├── warehouse_provider.dart    # 仓库状态管理
│   │   ├── purchase_provider.dart     # 采购状态管理
│   │   ├── return_provider.dart       # 退货状态管理
│   │   └── member_provider.dart       # 会员状态管理
│   ├── services/                      # 预留服务层
│   └── utils/                         # 预留工具层
├── features/
│   ├── statistics/
│   │   ├── dashboard_page.dart        # 仪表盘（今日概览 + 趋势图 + 库存预警）
│   │   ├── statistics_page.dart       # 统计报表
│   │   ├── reconciliation_page.dart   # 客户对账单
│   │   └── inventory_alert_page.dart  # 库存预警
│   ├── orders/
│   │   ├── order_list_page.dart       # 订单列表
│   │   ├── order_create_page.dart     # 新建/编辑销售单
│   │   ├── order_detail_page.dart     # 订单详情
│   │   └── draft_list_page.dart       # 草稿列表
│   ├── purchases/
│   │   ├── purchase_list_page.dart    # 采购列表
│   │   └── purchase_create_page.dart  # 新建采购单
│   ├── returns/
│   │   ├── return_list_page.dart      # 退货列表
│   │   └── return_create_page.dart    # 新建退货单
│   ├── inventory/
│   │   ├── inventory_check_list_page.dart  # 盘点记录
│   │   └── inventory_check_page.dart       # 执行盘点
│   ├── products/
│   │   ├── product_list_page.dart     # 商品列表
│   │   ├── product_edit_page.dart     # 商品编辑
│   │   ├── category_list_page.dart    # 分类列表
│   │   └── category_edit_page.dart    # 分类编辑
│   ├── customers/
│   │   ├── customer_list_page.dart    # 客户列表
│   │   └── customer_edit_page.dart    # 客户编辑
│   ├── members/
│   │   ├── member_list_page.dart      # 会员列表
│   │   └── member_edit_page.dart      # 会员编辑
│   ├── printing/
│   │   └── print_preview_page.dart    # PDF 预览与打印
│   ├── settings/
│   │   ├── settings_page.dart         # 设置主页
│   │   ├── shop_info_page.dart        # 店铺信息
│   │   ├── print_settings_page.dart   # 打印设置
│   │   ├── print_template_page.dart   # 打印模板
│   │   ├── warehouse_list_page.dart   # 仓库列表
│   │   └── warehouse_edit_page.dart   # 仓库编辑
│   └── sync/
│       └── webdav_page.dart           # WebDAV 备份同步
└── widgets/
    └── common/
        └── widgets.dart               # 通用组件（搜索栏、金额文本、状态标签等）
```

## CI/CD

推送 `main` 分支自动触发 GitHub Actions：

1. **测试阶段**：`flutter analyze` + `flutter test`
2. **构建阶段**：并行构建 Android APK + iOS IPA
3. **发布阶段**：自动创建 GitHub Release（pre-release）

### 产物

| 文件 | 说明 |
|---|---|
| `furni_bill.apk` | Android 调试安装包 |
| `furni_bill.ipa` | iOS 无签名包（需越狱或企业签名安装） |

产物可直接在 [Releases](https://github.com/shupian35/FurniBill/releases) 页面下载。

## License

MIT
