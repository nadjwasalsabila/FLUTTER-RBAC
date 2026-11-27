import 'package:flutter/material.dart';

import '../../../common/warehouse_theme.dart';
import '../services/stock_adjustment_service.dart';
import '../types/stock_models.dart';
import 'staff_item_card.dart';
import 'staff_summary_header.dart';
import 'stock_adjustment_dialog.dart';

/// Halaman "Penyesuaian stok" untuk role staff sesuai desain Figma:
/// kartu ringkasan teal, kolom pencarian, daftar barang dengan badge,
/// dan lembar aksi "Ubah stok" saat kartu diketuk.
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
  List<WarehouseItem> _items = const [];
  bool _isLoading = true;
  String? _statusMessage;
  bool _isErrorStatus = false;
  String _searchQuery = '';

  List<WarehouseItem> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.sku.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query) ||
              item.location.toLowerCase().contains(query),
        )
        .toList();
  }

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

  /// Lembar detail barang + tombol amber "Ubah stok" saat kartu diketuk.
  Future<void> _openItemDetails(WarehouseItem item) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WarehouseColors.softMint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const WarehouseItemChip(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: WarehouseColors.darkText,
                            ),
                          ),
                          Text(
                            '${item.sku} • ${item.category} • ${item.location}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: WarehouseColors.subtitleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    WarehouseStockBadge(stock: item.stock),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WarehouseColors.paleMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_outlined,
                        size: 18,
                        color: WarehouseColors.primaryTeal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stok saat ini: ${item.stock} unit',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: WarehouseColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                WarehousePrimaryButton(
                  label: 'Ubah stok',
                  icon: Icons.tune,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openAdjustDialog(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStock = _items.fold<int>(0, (sum, item) => sum + item.stock);
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: WarehouseColors.background,
      appBar: WarehouseAppBar(
        subtitle:
            'Halo, ${widget.activeUserName ?? 'Petugas Gudang'} · ${widget.activeRoleLabel ?? 'staff'}',
        onSwitchAccount: widget.onSwitchAccount,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: WarehousePageHeader(
                    title: 'Penyesuaian stok',
                    subtitle: 'Pilih barang lalu sesuaikan jumlah stoknya',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: StaffSummaryHeader(
                    userName: widget.activeUserName,
                    roleLabel: widget.activeRoleLabel,
                    itemCount: _items.length,
                    totalStock: totalStock,
                  ),
                ),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: StaffStatusBanner(
                      message: _statusMessage!,
                      isError: _isErrorStatus,
                      onDismiss: () => setState(() => _statusMessage = null),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: WarehouseSearchField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: WarehouseSectionHeader(
                    title: 'Daftar barang',
                    trailing: '${filteredItems.length} barang',
                  ),
                ),
                Expanded(child: _buildBody(filteredItems)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<WarehouseItem> items) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: WarehouseColors.primaryTeal),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Tidak ada data barang tersedia.'));
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada barang yang cocok dengan pencarian.',
          style: TextStyle(color: WarehouseColors.subtitleText),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return StaffItemCard(
          item: item,
          onOpenDetails: () => _openItemDetails(item),
        );
      },
    );
  }
}
