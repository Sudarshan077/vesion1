import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'retailers_screen.dart';
import 'orders_screen.dart';
import 'consumer_dashboard_screen.dart';
import 'retailer_dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Role-specific screen configurations
  List<Widget> _getScreens(AuthProvider auth) {
    if (auth.isCustomer) {
      return const [
        ConsumerDashboardScreen(),
        OrdersScreen(),
      ];
    } else if (auth.isRetailer) {
      return const [
        RetailerDashboardScreen(),
        OrdersScreen(),
      ];
    } else {
      // Admin/Distributor — the original dashboard
      return const [
        DashboardScreen(),
        ProductsScreen(),
        RetailersScreen(),
        OrdersScreen(),
      ];
    }
  }

  List<NavigationRailDestination> _getRailDestinations(AuthProvider auth) {
    if (auth.isCustomer) {
      return const [
        NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: Text('My Orders')),
      ];
    } else if (auth.isRetailer) {
      return const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: Text('My Orders')),
      ];
    } else {
      return const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: Text('Products')),
        NavigationRailDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store_rounded), label: Text('Retailers')),
        NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: Text('Orders')),
      ];
    }
  }

  List<NavigationDestination> _getBottomDestinations(AuthProvider auth) {
    if (auth.isCustomer) {
      return const [
        NavigationDestination(icon: Icon(Icons.home_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.home_rounded, color: AppTheme.accent), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.accent), label: 'My Orders'),
      ];
    } else if (auth.isRetailer) {
      return const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accent), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.accent), label: 'My Orders'),
      ];
    } else {
      return const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accent), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.accent), label: 'Products'),
        NavigationDestination(icon: Icon(Icons.store_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.store_rounded, color: AppTheme.accent), label: 'Retailers'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary), selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.accent), label: 'Orders'),
      ];
    }
  }

  String _getRoleLabel(AuthProvider auth) {
    if (auth.isCustomer) return 'CONSUMER';
    if (auth.isRetailer) return 'RETAILER';
    return 'DMS';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 600;
    final screens = _getScreens(auth);

    // Clamp index in case role changes
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

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
                      Text(
                        _getRoleLabel(auth),
                        style: const TextStyle(
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
                destinations: _getRailDestinations(auth),
              ),
            ),
          Expanded(
            child: Container(
              color: AppTheme.primaryDark,
              child: screens[_selectedIndex],
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
                destinations: _getBottomDestinations(auth),
              ),
            ),
    );
  }
}

