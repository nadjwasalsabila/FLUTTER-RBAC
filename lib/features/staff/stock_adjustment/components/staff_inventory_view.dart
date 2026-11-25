import 'package:flutter/material.dart';

import '../services/stock_adjustment_service.dart';
import '../types/stock_models.dart';
import 'staff_item_card.dart';
import 'staff_summary_header.dart';
import 'stock_adjustment_dialog.dart';

class StaffInventoryView extends StatefulWidget {
  const StaffInventoryView({
    super.key,
    required this.service,
    required this.activeUserId,
    this.activeUserName,
    this.activeRoleLabel,
    this.onSwitchAccount,
  });

  final StockAdjustmentService service;
  final int activeUserId;
  final String? activeUserName;
  final String? activeRoleLabel;
  final VoidCallback? onSwitchAccount;

  @override
  State<StaffInventoryView> createState() => _StaffInventoryViewState();
}

class _StaffInventoryViewState extends State<StaffInventoryView> {
  static const _primaryTeal = Color(0xFF145858);

  List<WarehouseItem> _items = const [];
  bool _isLoading = true;
  String? _statusMessage;
  bool _isErrorStatus = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final result = await widget.service.getItems();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _items = result.items;
      if (!result.allowed) {
        _statusMessage = result.errorMessage;
        _isErrorStatus = true;
      }
    });
  }

  Future<void> _openAdjustDialog(WarehouseItem item) async {
    final input = await StockAdjustmentDialog.show(context, item: item);
    if (input == null || !mounted) return;

    final result = await widget.service.adjustStock(
      StockAdjustmentRequest(
        itemId: item.id,
        userId: widget.activeUserId,
        type: input.type,
        amount: input.amount,
        reason: input.reason,
      ),
    );
    if (!mounted) return;

    setState(() {
      _statusMessage = result.message;
      _isErrorStatus = !result.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success) await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final totalStock = _items.fold<int>(0, (sum, item) => sum + item.stock);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
        title: const Text('Gudang RBAC — Stok Barang'),
        actions: [
          if (widget.onSwitchAccount != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: widget.onSwitchAccount,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Ganti Akun'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: StaffSummaryHeader(
                    userName: widget.activeUserName,
                    roleLabel: widget.activeRoleLabel,
                    itemCount: _items.length,
                    totalStock: totalStock,
                  ),
                ),
                if (_statusMessage != null)
                  StaffStatusBanner(
                    message: _statusMessage!,
                    isError: _isErrorStatus,
                    onDismiss: () => setState(() => _statusMessage = null),
                  ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryTeal),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Tidak ada data barang tersedia.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        return StaffItemCard(
          item: item,
          onAdjustPressed: () => _openAdjustDialog(item),
        );
      },
    );
  }
}
