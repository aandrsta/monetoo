// lib/screens/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../utils/app_theme.dart';
import 'transaction_screen.dart';
import 'category_screen.dart';
import 'statistics_screen.dart';
import 'account_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AccountScreen(),
    TransactionScreen(),
    CategoryScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: AppTheme.accent.withOpacity(0.15),
              hoverColor: AppTheme.accent.withOpacity(0.1),
              gap: 8,
              activeColor: AppTheme.accent,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppTheme.accent.withOpacity(0.1),
              color: AppTheme.textSecondary,
              tabs: const [
                GButton(
                  icon: Icons.account_balance_wallet_rounded,
                  text: 'Akun',
                ),
                GButton(
                  icon: Icons.receipt_long_rounded,
                  text: 'Transaksi',
                ),
                GButton(
                  icon: Icons.category_rounded,
                  text: 'Kategori',
                ),
                GButton(
                  icon: Icons.bar_chart_rounded,
                  text: 'Statistik',
                ),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
