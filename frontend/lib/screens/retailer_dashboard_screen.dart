import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class RetailerDashboardScreen extends StatefulWidget {
  const RetailerDashboardScreen({super.key});

  @override
  State<RetailerDashboardScreen> createState() => _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState extends State<RetailerDashboardScreen> {
  List<dynamic> _products = [];
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
        ApiService.getOrders().catchError((_) => <dynamic>[]),
      ]);
      setState(() {
        _products = results[0];
        _orders = results[1];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    final pendingOrders = _orders.where((o) => o['orderStatus'] == 'PENDING').length;
    final deliveredOrders = _orders.where((o) => o['orderStatus'] == 'DELIVERED').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welcome', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Browse products and track your orders', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.inventory_2_rounded,
                  label: 'Available Products',
                  value: '${_products.length}',
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.pending_actions_rounded,
                  label: 'Pending Orders',
                  value: '$pendingOrders',
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Delivered',
                  value: '$deliveredOrders',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent products
          Row(
            children: [
              const Icon(Icons.new_releases_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text('Product Catalog', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          if (_products.isEmpty)
            _buildEmptyState('No products available yet', Icons.inventory_2_outlined)
          else
            ..._products.take(6).map((p) => _ProductTile(product: p)),

          const SizedBox(height: 24),

          // Recent orders
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text('My Recent Orders', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          if (_orders.isEmpty)
            _buildEmptyState('No orders yet', Icons.receipt_long_outlined)
          else
            ..._orders.take(5).map((o) => _OrderTile(order: o)),
        ],
      ),
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
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
              color: AppTheme.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.info, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'Unknown', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text('SKU: ${product['sku'] ?? '—'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${product['price'] ?? 0}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 16)),
              Text('${product['currentStock'] ?? 0} in stock', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderTile({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return AppTheme.warning;
      case 'CONFIRMED': return AppTheme.info;
      case 'DELIVERED': return AppTheme.success;
      case 'CANCELLED': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['orderStatus'] ?? 'UNKNOWN';
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order['id']?.toString().substring(0, 8) ?? '—'}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text('${order['items']?.length ?? 0} items', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
