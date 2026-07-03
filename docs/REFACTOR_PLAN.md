# FurniBill 重构 Vibe Coding 计划书

> 定位：不是大爆炸式重写，而是 6 周 × 1 个 vibe session 的渐进重构。每个 session 1.5–3 小时，跑通 → 截图 → 推 → 下一个。Vibe 在于：保持手感流畅、不陷入完美架构陷阱、能跑就行、跑稳了再漂亮。

## 0. 总原则（写给未来的我）

- 不破坏现有功能：每个 session 结束都要能 `flutter run`、能开 App、五个 Tab 都能点
- 业务价值优先：先动用户用得最多的代码（开单、列表、打印），后动基础设施
- 测试跟随：重构必带测试 —— 不求覆盖率 100%，但关键路径必须先有红，再变绿
- commit 小而频繁：每个 session 5–10 个 commit，每个 commit 可独立 revert
- 保留品牌：中文硬编码、Material 3、种子色 #1565C0、Provider 状态管理 —— 这些都不动
- 不过度设计：不引入 Bloc / Riverpod / Freezed / go_router 之类新东西；用仓库现有风格

## 1. 现状量化（vibe 起跑前的体检报告）

| 文件 | 行数 | 痛点 |
| --- | --- | --- |
| `lib/features/orders/order_create_page.dart` | 643 | 单页塞了：选客户、选商品、明细编辑、付款、折扣、打印预览调用、状态保存 |
| `lib/core/providers/order_provider.dart` | 177 | 9 个 Provider 里最大的，业务逻辑揉在 ChangeNotifier 里 |
| `lib/features/orders/order_detail_page.dart` | 243 | 详情页和创建页部分 UI 重复 |
| `lib/core/providers/settings_provider.dart` | 108 | 全局设置但和其他 Provider 没有依赖注入 |
| `lib/core/providers/*_provider.dart` × 9 | 49–177 | 模式高度雷同：CRUD + `notifyListeners()`，可抽象 |
| `lib/core/database/database_helper.dart` | ? | schema v1→v8 迁移逻辑没测试，是定时炸弹 |
| `test/` 下 Provider / 页面 / DB 测试 | 0 | 业务层零覆盖 |

核心判断：`order_create_page.dart` 是头号痛点（643 行），`order_provider.dart` 是头号业务风险（开单核心逻辑没测试）。

## 2. 六周路线图

### Week 1 — `order_create_page` 拆页（P0，单点爆破）

目标：把 643 行的开单页拆成 4 个组件 + 1 个状态壳。完成后 `order_create_page.dart` 应该 < 250 行。

步骤：

1. 先读一遍 `order_create_page.dart`，画一张脑图：哪些 `_build*` 方法是独立 widget，哪些是局部状态
2. 抽出：
   - `widgets/order_create_header.dart`（顶部：客户 + 日期 + 单号）
   - `widgets/order_create_item_list.dart`（中间：商品明细列表）
   - `widgets/order_create_footer.dart`（底部：金额汇总 + 付款 + 保存）
   - `widgets/order_create_item_row.dart`（明细行：选商品 / 改数量 / 改单价）
3. 用 `Consumer<OrderProvider>` 把数据下沉，让 4 个组件尽可能 stateless
4. 不动 OrderProvider 内部逻辑，只把 widget 拆开

验证：

- `flutter analyze --no-fatal-infos` 通过
- 手动 `flutter run`（Android 模拟器）走一遍：建单 → 选商品 → 改数量 → 付款 → 保存草稿 → 提交，全流程能跑
- 截图：开单页、选商品弹窗、保存后的详情页

commit 形态：4 个 commit，每个组件一个，第 5 个是清理 import。

vibe 收尾：开单页终于像页了。

### Week 2 — `OrderProvider` 单元测试 + 抽 `OrderCalculator`（P0，止血）

目标：开单核心逻辑有测试覆盖，不重写 Provider 结构，只把纯函数抽出来。

步骤：

1. `test/core/providers/order_provider_test.dart`：覆盖
   - `addItem` / `removeItem` / `updateItem`
   - `totalAmount` 计算（含折扣）
   - `saveDraft` / `submitOrder`（用 `sqflite_common_ffi` 跑内存 DB）
2. 看 `OrderProvider` 里有没有计算金额 / 计算优惠 / 校验数据这种纯函数，抽到 `lib/core/services/order_calculator.dart`
3. `OrderProvider` 里改成 `OrderCalculator.calculate(items, discount)` 调用
4. 给 `OrderCalculator` 写一组纯函数测试（不依赖 Flutter、不依赖 DB）

验证：

- `flutter test` 全绿
- `OrderProvider` 行数应该降到 ~110，剩下的都是 IO 编排
- 新增一个测试文件，覆盖率从 0% → 至少 60%（针对 `order/` 目录）

commit 形态：3 个 commit —— 测试红、抽函数、测试绿。

vibe 收尾：开单终于敢改了。

### Week 3 — `database_helper` 测试 + 迁移脚本（止血）

目标：schema v1→v8 迁移有测试，未来再加 v9 不再怕。

步骤：

1. `test/core/database/database_helper_test.dart`
   - 用 `sqflite_common_ffi` 起内存 DB
   - 准备一个 v1 的 fixture（直接 INSERT INTO 旧 schema）
   - 跑 `_upgradeDB` 升到 v8
   - 校验：表都建好了、字段都加上了、外键没问题
2. 顺便把 `_upgradeDB` 里 v1→v2、v2→v3…拆成 `Migration_v1_to_v2` 这种独立函数，单独可测
3. `analysis_options.yaml` 加 `avoid_dynamic_calls: true` 之类严格 lint（可选）

验证：

- `flutter test` 全绿
- `database_helper.dart` 行数应该变化不大，但可读性显著提升
- 模拟老用户升级场景：v1 DB → v8 DB，校验数据不丢

commit 形态：2 个 commit —— 测试框架、迁移拆分。

vibe 收尾：数据库这层是稳的。

### Week 4 — 通用 Provider 模式抽象（节制）

目标：9 个 Provider 高度雷同（CRUD + notifyListeners），抽一个 `BaseCrudProvider<T>` 父类，不强求所有 Provider 一次迁移。

步骤：

1. 先做只读分析：列出每个 Provider 的 `load / insert / update / delete` 命名差异
2. 设计 `BaseCrudProvider<T>` 的最小接口：
   ```dart
   abstract class BaseCrudProvider<T> extends ChangeNotifier {
     List<T> get items;
     Future<void> init();
     Future<int> create(T item);
     Future<int> update(T item);
     Future<int> delete(int id);
   }
   ```
3. 先只迁移一个 —— `CategoryProvider`（最简单，49 行）
4. 跑测试，不通过就回退（这是这次重构最危险的一步）
5. 如果 `CategoryProvider` 迁移顺利，把决定权留到下次 —— 不强推 9 个 Provider 全迁移

验证：

- `CategoryProvider` 减少到 ~25 行
- 分类管理页面功能不变
- 决策：在 README 留个 `// TODO: 渐进迁移其他 Provider` 标记，不一次性全做

commit 形态：3 个 commit —— 父类骨架、Category 迁移、文档。

vibe 收尾：找到该停就停的节奏，不做英雄式重构。

### Week 5 — 打印功能解耦（业务价值第二高）

目标：`features/printing/print_preview_page.dart` + 三联单生成逻辑独立成 `core/services/print_service.dart`，方便未来加 PDF 模板可视化编辑。

步骤：

1. 读 `print_preview_page.dart`，把生成 PDF / 调用 printing 插件 / 处理打印机选择抽到 `PrintService`
2. `PrintService` 暴露：`Future<Uint8List> buildPdf(Order order, PrintTemplate template)`
3. `print_preview_page.dart` 只管 UI：调 service → 拿 bytes → 渲染预览
4. 给 `PrintService.buildPdf` 写一个测试：输入固定 Order + 模板，输出固定 bytes（或固定页数 / 固定文本行数）

验证：

- 打印预览能跑、生成的 PDF 视觉效果和重构前一致
- 打印模板页（`features/settings/print_template_page.dart`）功能不变

commit 形态：3 个 commit —— service 抽出、UI 接入、测试。

vibe 收尾：打印功能第一次能独立测试。

### Week 6 — 收口 + 健康度报告

目标：跑一遍 quality gate，把所有最后 20% 清掉。

步骤：

1. 移除 `--no-fatal-infos` 之前，先把 info 级 lint 全清掉（变量命名、unused import、`super.key` 等）
2. 跑 `flutter analyze`，目标是 0 issues（不带 `--no-fatal-infos` 也能过）
3. 给 `OrderProvider` / `OrderCalculator` / `PrintService` 三个核心 service 各补一个 README 段落
4. 写一份 `docs/ARCHITECTURE.md`：一张 ASCII 架构图 + 三句话说明每个模块的职责
5. 给 `pubspec.yaml` 升一批不 breaking 的依赖：`intl 0.20.2→0.20.3`、`sqflite 2.4.2→2.4.3` 之类

验证：

- `flutter analyze` 0 issues
- `flutter test` 全绿
- CI workflow 移除 `--no-fatal-infos` flag

commit 形态：4 个 commit —— 清理 lint、文档、依赖、CI。

vibe 收尾：项目从能跑变成能改。

## 3. 不做（写下来才不会被诱惑）

| 不做 | 原因 |
| --- | --- |
| 引入 Riverpod / Bloc / go_router | Provider 已经够用，换状态管理是给未来挖坑 |
| 引入 Freezed / json_serializable | 模型层很薄，codegen 收益小、工具链成本大 |
| 一次性 9 个 Provider 迁移 | Week 4 已经说清楚，做一个观望，不要做英雄 |
| 重写 `order_create_page` 改用 `ListView.builder` 之外的方案 | 64 行模板是表象问题，真问题是 643 行总长；拆组件就够了 |
| 把中文文案抽到 .arb | 用户没要求 i18n；硬编码是产品决策不是技术债 |
| 性能优化（ListView.builder、const widget、RepaintBoundary 等等） | 用户没抱怨过卡顿；优化要在有 profile 数据之后做 |
| iOS 闪退的根本性根治 | 那是 bug 修复不是重构，放进另一个 plan |

## 4. 节奏卡

```
Week 1 ████████░░  order_create 拆页
Week 2 ████████░░  OrderProvider 测试 + 抽 OrderCalculator
Week 3 ████████░░  database_helper 测试 + 迁移拆分
Week 4 ██████░░░░  BaseCrudProvider 抽（节制！）
Week 5 ████████░░  PrintService 抽出
Week 6 ████████░░  收口 + 文档 + 依赖升级
```

每个 week 都是 1 个 vibe session，session 结束 = commit 推完 + `flutter run` 通。

## 5. 度量（怎么算重构成功）

| 指标 | 重构前 | Week 6 后 |
| --- | --- | --- |
| `order_create_page.dart` 行数 | 643 | < 250 |
| `OrderProvider` 行数 | 177 | ~110 |
| `database_helper.dart` 迁移函数行数 | 1 个 _upgradeDB 巨函数 | 8 个独立 migration 函数 |
| 业务测试覆盖率 | ~5% | ~40% |
| `flutter analyze`（不带 `--no-fatal-infos`） | 失败 | 通过 |
| 单文件最大行数 | 643 | < 350 |

## 6. 风险与对冲

| 风险 | 对冲 |
| --- | --- |
| Week 4 抽 `BaseCrudProvider` 时改坏 | 只迁一个（CategoryProvider），出问题立即 revert |
| Week 1 拆组件时引入 widget 重建 bug | 拆之前先抓一个完整的用户操作序列（录视频），拆完按序列走一遍对比 |
| 测试本身有 bug 给假绿 | Week 2 / 3 写测试时，故意改一行业务代码看测试是否变红 |
| 重构过程中 iOS 闪退问题被新代码掩盖 | 重构期间每周末跑一次 LiveContainer 实机测试 |
| 用户中途改需求打乱节奏 | 计划书放在 `docs/REFACTOR_PLAN.md`，每周日 review，必要时 reorder 但不延期 |

## 7. 速赢（任何一周里能顺手做的 5 分钟活）

- 删 unused import
- 补 `.gitignore`（如果有 build 产物漏掉）
- 把过长的字符串提取成命名常量
- 给 `// ignore: ...` 加解释注释
- 把 `print(...)` 换成 `debugPrint(...)`

## 8. 启动指令

从 Week 1 开始：

> 重构 week 1：把 `order_create_page.dart` 拆成 4 个组件，目标 250 行以内。

可以一气呵成读完 → 拆 → 跑测试 → 推 4 个 commit。
