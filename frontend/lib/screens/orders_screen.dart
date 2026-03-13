import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      _orders = await ApiService.getOrders();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredOrders {
    if (_filterStatus == 'ALL') return _orders;
    return _orders.where((o) => o['orderStatus'] == _filterStatus).toList();
  }

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
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final statuses = ['ALL', 'PENDING', 'CONFIRMED', 'DELIVERED', 'CANCELLED'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppTheme.accent,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${_orders.length} Orders',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: statuses.map((status) {
                        final isSelected = _filterStatus == status;
                        final count = status == 'ALL'
                            ? _orders.length
                            : _orders.where((o) => o['orderStatus'] == status).length;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('$status ($count)'),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _filterStatus = status),
                            backgroundColor: AppTheme.surfaceCard,
                            selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                            checkmarkColor: AppTheme.accent,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppTheme.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_filteredOrders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text('No orders found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._filteredOrders.map((order) {
                      final status = order['orderStatus'] ?? 'UNKNOWN';
                      final amount = order['totalAmount'] is num ? order['totalAmount'].toDouble() : 0.0;
                      final items = order['items'] as List? ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          shape: const Border(),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.receipt_rounded, color: _statusColor(status), size: 20),
                          ),
                          title: Text(
                            'Order #${order['id']?.toString().substring(0, 8) ?? '—'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                currencyFormat.format(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accent,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            ...items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['product']?['name'] ?? 'Product',
                                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      'x${item['quantity'] ?? 0}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      currencyFormat.format(
                                        item['subTotal'] is num ? item['subTotal'].toDouble() : 0,
                                      ),
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
