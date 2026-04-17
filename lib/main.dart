// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Global Error Handler
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // You could add crash reporting here (e.g. Sentry/Firebase)
    debugPrint('Global Error: ${details.exception}');
  };

  // Initialize providers
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Set awal — ini dijalankan sekali saat app start
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light, // iOS
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FinanceProvider>(
            create: (_) => FinanceProvider()..initialize()),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDarkMode;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark,
                    systemNavigationBarColor: Color(0xFF121518),
                    systemNavigationBarIconBrightness: Brightness.light,
                  )
                : const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                    systemNavigationBarColor: Colors.white,
                    systemNavigationBarIconBrightness: Brightness.dark,
                  ),
            child: MaterialApp(
              title: 'Monetoo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const MainNavigation(),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    boldText: false,
                  ),
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
