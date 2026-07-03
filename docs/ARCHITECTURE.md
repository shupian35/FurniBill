# FurniBill 架构

> 一张 ASCII 架构图 + 每个模块三句话说明职责。重构后的项目状态，最后更新于 Week 6。

## 架构图

```
+-----------------------------------------------------------------+
|                         UI (视图层)                        |
|  lib/features/<domain>/page.dart  +  widgets/  +  dialogs/        |
+-----+----------------------------------+------------------------+
      | 购买 Provider                       | 启用 SettingsProvider
      v                                  v
+------------+  购买 / 销售   +-------------------+  WebDAV  +-----------+
| Providers  |  -----------------> |   Database (SQLite)   |  <-----> |  Backup   |
| ChangeNoti |  addItem / submit   |  DatabaseHelper       |          |  Service  |
+-----+------+                    +-----+-----------------+          +-----------+
      |                                   |
      | 调用                           | SQL
      v                                   v
+---------------------+         +-------------------+
| Pure Services       |         | Schema v1 -> v8    |
| OrderCalculator     |         | lib/core/database/ |
| PrintService        |         |   migrations.dart  |
+---------------------+         +-------------------+
```

## 模块职责

### `lib/main.dart`
入口。搭 MultiProvider（8 个）+底部 5 个 Tab。是业务与基础设施的唯一拼装点。

### `lib/core/database/`
SQLite 本地存储。`DatabaseHelper` 单例提供通用 `query/insert/update/delete`；`migrations.dart` 把 v1→v8 拆成 4 个独立函数，可单测。

### `lib/core/models/`
POJO。Order 以 JSON 字串存明细（不独立表）；Category 用 `import ... as models` 避免与 Flutter 内置类名冲突。

### `lib/core/providers/`
状态管理（Provider / ChangeNotifier）。`BaseCrudProvider` 提供通用 CRUD，业务 Provider 继承后只需实现 4 个抽象方法（表名、fromMap、toMap、orderByClause）。

### `lib/core/services/`
无 UI 依赖的纯逻辑。`OrderCalculator` 处理金额/折扣/抹零；`PrintService` 处理 PDF 渲染、中文字体、三联单、金额转中文大写。

### `lib/features/<domain>/`
按业务领域组织的页面。页面只负责拼 UI + 调 Provider/调 Service，不保存业务算法。

### `lib/widgets/common/`
跨页面复用组件（搜索栏、金额文本、状态标签等）。

## 重构后的关键边界

- **Provider 与 Service 的边界**：Provider 是 ChangeNotifier，负责响应 UI；Service 是纯 Dart 类，负责计算与生成。两者都不依赖 Flutter（Provider 仅依 `package:flutter/foundation.dart`）。
- **Widget 与业务的边界**：Widget 只调公开的 Provider getter / Service 方法；不直接访问 DatabaseHelper。
- **业务与资料库的边界**：业务代码只购买 Order/OrderItem/Product 等模型。Schema 迁移、索引、外键在 migrations.dart 里。

## 重构公式

以 Week 1–6 为节奏，每周 1 个 vibe session，每 session 1.5–3 小时。详见 [REFACTOR_PLAN.md](./REFACTOR_PLAN.md)。
