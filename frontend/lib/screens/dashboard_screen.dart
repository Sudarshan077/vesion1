import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _products = [];
  List<dynamic> _retailers = [];
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getProducts().catchError((_) => <dynamic>[]),
        ApiService.getRetailers().catchError((_) => <dynamic>[]),
        ApiService.getOrders().catchError((_) => <dynamic>[]),
      ]);
      setState(() {
        _products = results[0];
        _retailers = results[1];
        _orders = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    final totalRevenue = _orders.fold<double>(0.0, (sum, order) {
      final amount = order['totalAmount'];
      if (amount is num) return sum + amount.toDouble();
      return sum;
    });

    final pendingOrders = _orders.where((o) => o['orderStatus'] == 'PENDING').length;
    final lowStockProducts = _products.where((p) {
      final stock = p['currentStock'];
      return stock is num && stock < 20;
    }).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Welcome header
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Track your distribution business in real-time',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Stat cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 2
                      : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
                children: [
                  _StatCard(
                    icon: Icons.inventory_2_rounded,
                    label: 'Total Products',
                    value: '${_products.length}',
                    color: AppTheme.info,
                    subtitle: '$lowStockProducts low stock',
                  ),
                  _StatCard(
                    icon: Icons.store_rounded,
                    label: 'Retailers',
                    value: '${_retailers.length}',
                    color: AppTheme.accent,
                    subtitle: 'Active partners',
                  ),
                  _StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Orders',
                    value: '${_orders.length}',
                    color: AppTheme.warning,
                    subtitle: '$pendingOrders pending',
                  ),
                  _StatCard(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Revenue',
                    value: currencyFormat.format(totalRevenue),
                    color: AppTheme.success,
                    subtitle: 'Total earned',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent orders
          _buildSectionHeader('Recent Orders', Icons.receipt_long_rounded),
          const SizedBox(height: 12),
          if (_orders.isEmpty)
            _buildEmptyState('No orders yet', Icons.receipt_long_rounded)
          else
            ..._orders.take(5).map((order) => _OrderTile(order: order, currencyFormat: currencyFormat)),

          const SizedBox(height: 24),

          // Low stock alerts
          _buildSectionHeader('Inventory Alerts', Icons.warning_amber_rounded),
          const SizedBox(height: 12),
          if (lowStockProducts == 0)
            _buildEmptyState('All products well stocked', Icons.check_circle_outline)
          else
            ..._products
                .where((p) => p['currentStock'] is num && (p['currentStock'] as num) < 20)
                .take(5)
                .map((p) => _LowStockTile(product: p)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final NumberFormat currencyFormat;

  const _OrderTile({required this.order, required this.currencyFormat});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppTheme.warning;
      case 'CONFIRMED':
        return AppTheme.info;
      case 'DELIVERED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['orderStatus'] ?? 'UNKNOWN';
    final amount = order['totalAmount'] is num ? order['totalAmount'].toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_rounded, color: _statusColor(status), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['id']?.toString().substring(0, 8) ?? '—'}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order['items']?.length ?? 0} items',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(amount),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final Map<String, dynamic> product;

  const _LowStockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final stock = product['currentStock'] ?? 0;
    final isVeryLow = stock is num && stock < 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isVeryLow ? AppTheme.danger : AppTheme.warning).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isVeryLow ? AppTheme.danger : AppTheme.warning).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVeryLow ? Icons.error_rounded : Icons.warning_amber_rounded,
              color: isVeryLow ? AppTheme.danger : AppTheme.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'SKU: ${product['sku'] ?? '—'}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$stock left',
            style: TextStyle(
              color: isVeryLow ? AppTheme.danger : AppTheme.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
