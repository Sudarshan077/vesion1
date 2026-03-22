import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  List<dynamic> _rules = [];
  List<dynamic> _products = [];
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
        ApiService.getPriceRules().catchError((_) => <dynamic>[]),
        ApiService.getProducts().catchError((_) => <dynamic>[]),
      ]);
      setState(() {
        _rules = results[0];
        _products = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddRuleDialog() {
    String? selectedProductId;
    String? selectedBuyerType;
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Price Rule', style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: selectedProductId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppTheme.surfaceCard,
                    hint: const Text('Select a product', style: TextStyle(color: AppTheme.textSecondary)),
                    items: _products.map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem(
                        value: p['id']?.toString(),
                        child: Text(
                          '${p['name']} (${p['sku']})',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedProductId = v),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Buyer Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: selectedBuyerType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppTheme.surfaceCard,
                    hint: const Text('Select buyer type', style: TextStyle(color: AppTheme.textSecondary)),
                    items: const [
                      DropdownMenuItem(
                        value: 'RETAILER',
                        child: Text('All Retailers', style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'CONSUMER',
                        child: Text('All Consumers', style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => selectedBuyerType = v),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Custom Price (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProductId == null || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a product and enter a price')),
                  );
                  return;
                }
                if (selectedBuyerType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a buyer type')),
                  );
                  return;
                }
                final body = <String, dynamic>{
                  'productId': selectedProductId,
                  'buyerType': selectedBuyerType,
                  'customPrice': double.tryParse(priceController.text) ?? 0,
                };
                try {
                  final result = await ApiService.createPriceRule(body);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (result['statusCode'] == 200) {
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Price rule created')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['body']['message'] ?? 'Error')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connection error')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRuleDialog(Map<String, dynamic> rule) {
    final priceController = TextEditingController(text: rule['customPrice']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Price Rule', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoChip('Product', rule['productName'] ?? '—'),
            const SizedBox(height: 8),
            _infoChip(
              'Buyer',
              rule['buyerName'] ?? rule['buyerType'] ?? '—',
            ),
            const SizedBox(height: 8),
            _infoChip('Base Price', '₹${rule['basePrice'] ?? '—'}'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Custom Price (₹)',
                prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (priceController.text.isEmpty) return;
              try {
                final result = await ApiService.updatePriceRule(
                  rule['id'].toString(),
                  {'customPrice': double.tryParse(priceController.text) ?? 0},
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (result['statusCode'] == 200) {
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Price rule updated')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['body']['message'] ?? 'Error')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection error')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRule(Map<String, dynamic> rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Price Rule?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove custom price for ${rule['productName']}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deletePriceRule(rule['id'].toString());
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Price rule deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting rule')),
          );
        }
      }
    }
  }

  Widget _infoChip(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRuleDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Rule'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Custom Pricing', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text(
              'Set different prices for retailers and consumers',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            // How it works info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Custom prices override the base product price. Specific buyer prices take priority over type defaults.',
                      style: TextStyle(color: AppTheme.info.withValues(alpha: 0.9), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                _miniStatCard('Total Rules', '${_rules.length}', Icons.rule_rounded, AppTheme.accent),
                const SizedBox(width: 12),
                _miniStatCard(
                  'Retailer Rules',
                  '${_rules.where((r) => r['buyerType'] == 'RETAILER').length}',
                  Icons.store_rounded,
                  AppTheme.info,
                ),
                const SizedBox(width: 12),
                _miniStatCard(
                  'Consumer Rules',
                  '${_rules.where((r) => r['buyerType'] == 'CONSUMER').length}',
                  Icons.person_rounded,
                  AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Rules List
            Row(
              children: [
                const Icon(Icons.price_change_rounded, color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Text('Price Rules', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),

            if (_rules.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.price_change_outlined, color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No custom pricing rules yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap + to set different prices for retailers or consumers',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ..._rules.map((rule) => _buildRuleTile(rule, currencyFormat)),

            const SizedBox(height: 80), // FAB clearance
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTile(dynamic rule, NumberFormat currencyFormat) {
    final isRetailer = rule['buyerType'] == 'RETAILER';
    final color = isRetailer ? AppTheme.info : AppTheme.warning;
    final buyerLabel = rule['buyerName'] ?? (isRetailer ? 'All Retailers' : 'All Consumers');
    final basePrice = rule['basePrice'] is num ? rule['basePrice'].toDouble() : 0.0;
    final customPrice = rule['customPrice'] is num ? rule['customPrice'].toDouble() : 0.0;
    final discount = basePrice > 0 ? ((basePrice - customPrice) / basePrice * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Product icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRetailer ? Icons.store_rounded : Icons.person_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule['productName'] ?? '—',
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'For: $buyerLabel',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      currencyFormat.format(basePrice),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: AppTheme.textSecondary, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      currencyFormat.format(customPrice),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (discount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${discount.toStringAsFixed(0)}%',
                          style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.accent, size: 18),
            onPressed: () => _showEditRuleDialog(rule),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
            onPressed: () => _deleteRule(rule),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
