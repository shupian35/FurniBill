# 家具备货单 · FurniBill

家具批发行业的移动端开单工具 —— 商品管理、客户管理、快速开单、三联单打印、WebDAV 备份同步，一部手机全搞定。

## 功能

- **仪表盘** — 今日销售额、订单数、实收、欠款一目了然
- **商品管理** — 自定义属性（颜色/尺寸/材质等）、SKU、分类、库存预警、条码扫描
- **客户管理** — 等级折扣（普通/VIP/代理/批发商）、信用额度、欠款追踪
- **快速开单** — 选客户 → 加商品 → 调折扣 → 选收款方式 → 完成，支持挂单（草稿）
- **三联单打印** — 白联（存根）/ 红联（客户）/ 蓝联（记账），支持 A4 和三等分切纸
- **统计报表** — 销售趋势图（按日/按月），支持导出 Excel
- **WebDAV 同步** — 数据库备份/恢复，多设备数据互通
- **深色模式** / 负库存开关 / 收款语音播报 / 小数位数可配

## 技术栈

| 层 | 选型 |
|---|---|
| 框架 | Flutter 3.41+（Dart 3.11+）、Material 3 |
| 状态管理 | Provider |
| 本地数据库 | sqflite（SQLite） |
| PDF 生成 | pdf + printing |
| 图表 | fl_chart |
| 网络同步 | webdav_client |
| 平台 | Android / iOS / Windows / macOS / Linux / Web |

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
├── main.dart                     # 入口，MultiProvider + 5 个底部 Tab
├── core/
│   ├── models/                   # Product, Sku, Customer, Order, Payment, BackupMeta
│   ├── providers/                # ChangeNotifier 状态管理
│   ├── database/                 # SQLite 建表 + 通用 CRUD
│   ├── constants/                # 付款方式、客户等级、折扣映射等常量
│   └── services/                 # 预留服务层
├── features/
│   ├── orders/                   # 订单列表 / 新建 / 详情 / 草稿
│   ├── products/                 # 商品列表 / 编辑
│   ├── customers/                # 客户列表 / 编辑
│   ├── statistics/               # 仪表盘 / 销售趋势
│   ├── printing/                 # PDF 预览与打印
│   ├── settings/                 # 店铺信息 / 打印设置 / 偏好
│   └── sync/                     # WebDAV 备份同步
└── widgets/common/               # 通用组件（搜索栏、金额文本、状态标签等）
```

## CI/CD

推送 `main` 分支自动触发 GitHub Actions，并行构建 Android APK 和 iOS IPA（Debug），
构建完成后自动发布为 GitHub Release（pre-release）。

产物可直接在 [Releases](https://github.com/shupian35/FurniBill/releases) 页面下载。

## License

MIT
