import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'retailers_screen.dart';
import 'orders_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final _screens = const [
    DashboardScreen(),
    ProductsScreen(),
    RetailersScreen(),
    OrdersScreen(),
  ];

  final _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: Text('Products'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.store_outlined),
      selectedIcon: Icon(Icons.store_rounded),
      label: Text('Retailers'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: Text('Orders'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryMid,
                border: Border(
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                labelType: NavigationRailLabelType.all,
                extended: false,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.hub_rounded, color: AppTheme.accent, size: 24),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'DMS',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                        tooltip: 'Sign Out',
                        onPressed: () => context.read<AuthProvider>().signOut(),
                      ),
                    ),
                  ),
                ),
                destinations: _destinations,
              ),
            ),
          Expanded(
            child: Container(
              color: AppTheme.primaryDark,
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryMid,
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                backgroundColor: Colors.transparent,
                indicatorColor: AppTheme.accent.withValues(alpha: 0.15),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined, color: AppTheme.textSecondary),
                    selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accent),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary),
                    selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.accent),
                    label: 'Products',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.store_outlined, color: AppTheme.textSecondary),
                    selectedIcon: Icon(Icons.store_rounded, color: AppTheme.accent),
                    label: 'Retailers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary),
                    selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.accent),
                    label: 'Orders',
                  ),
                ],
              ),
            ),
    );
  }
}
