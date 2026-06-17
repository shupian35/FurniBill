import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/product_provider.dart';
import 'core/providers/customer_provider.dart';
import 'core/providers/order_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/warehouse_provider.dart';
import 'core/providers/purchase_provider.dart';
import 'core/providers/return_provider.dart';
import 'core/providers/member_provider.dart';
import 'features/statistics/dashboard_page.dart';
import 'features/orders/order_list_page.dart';
import 'features/products/product_list_page.dart';
import 'features/customers/customer_list_page.dart';
import 'features/settings/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FurniBillApp());
}

class FurniBillApp extends StatelessWidget {
  const FurniBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()..init()),
        ChangeNotifierProvider(create: (_) => OrderProvider()..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..init()),
        ChangeNotifierProvider(create: (_) => WarehouseProvider()..init()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()..init()),
        ChangeNotifierProvider(create: (_) => ReturnProvider()..init()),
        ChangeNotifierProvider(create: (_) => MemberProvider()..init()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '简易开单',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: CardThemeData(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            ),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardPage(),
    OrderListPage(),
    ProductListPage(),
    CustomerListPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '概览'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '订单'),
          NavigationDestination(icon: Icon(Icons.chair_outlined), selectedIcon: Icon(Icons.chair), label: '商品'),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: '客户'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
