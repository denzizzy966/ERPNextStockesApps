import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_entry_screen.dart';
import 'screens/stock_entry_list_screen.dart';
import 'screens/current_stock_screen.dart';
import 'screens/items_screen.dart';
import 'screens/warehouses_screen.dart';
import 'screens/item_groups_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/data_screen.dart';
import 'widgets/app_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Inventory Management',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.blue,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        routes: {
          '/': (context) => Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return authProvider.isAuthenticated
                      ? const AppLayout(
                          currentIndex: 0,
                          child: DashboardScreen(),
                        )
                      : const LoginScreen();
                },
              ),
          '/stock-entry': (context) => const AppLayout(
                currentIndex: 1,
                child: StockEntryScreen(),
              ),
          '/stock-entry-list': (context) => const AppLayout(
                currentIndex: 1,
                child: StockEntryListScreen(),
              ),
          '/current-stock': (context) => const AppLayout(
                currentIndex: 2,
                child: CurrentStockScreen(),
              ),
          '/items': (context) => const AppLayout(
                currentIndex: 3,
                child: ItemsScreen(),
              ),
          '/warehouses': (context) => const AppLayout(
                currentIndex: 3,
                child: WarehousesScreen(),
              ),
          '/item-groups': (context) => const AppLayout(
                currentIndex: 3,
                child: ItemGroupsScreen(),
              ),
          '/data': (context) => const AppLayout(
                currentIndex: 3,
                child: DataScreen(),
              ),
          '/settings': (context) => const AppLayout(
                currentIndex: 4,
                child: SettingsScreen(),
              ),
        },
        initialRoute: '/',
      ),
    );
  }
}
