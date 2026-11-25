import 'package:flutter/material.dart';

import '../../../staff/stock_adjustment/stock_adjustment.dart';
import '../services/manager_item_service.dart';
import '../types/manager_models.dart';
import 'item_form_dialog.dart';
import 'manager_item_card.dart';
import 'manager_summary_header.dart';

class ManagerInventoryView extends StatefulWidget {
  const ManagerInventoryView({
    super.key,
    required this.service,
    required this.stockService,
    required this.activeUserId,
    this.activeUserName,
    this.activeRoleLabel,
    this.onSwitchAccount,
  });

  final ManagerItemService service;

  /// Service stok yang sama dengan yang dipakai staff, agar perubahan
  /// stok manager & staff terhubung (satu DB, satu tabel stock_movements).
  final StockAdjustmentService stockService;
  final int activeUserId;
  final String? activeUserName;
  final String? activeRoleLabel;
  final VoidCallback? onSwitchAccount;

  @override
  State<ManagerInventoryView> createState() => _ManagerInventoryViewState();
}

class _ManagerInventoryViewState extends State<ManagerInventoryView> {
  static const _primaryTeal = Color(0xFF145858);

  List<ManagerItem> _items = const [];
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canDelete = false;
  bool _canAdjustStock = false;
  String? _statusMessage;
  bool _isErrorStatus = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final itemsResult = await widget.service.getItems();
    final canCreate =
        await widget.service.hasPermission(ManagerItemService.createPermission);
    final canDelete =
        await widget.service.hasPermission(ManagerItemService.deletePermission);
    final canAdjustStock =
        await widget.service.hasPermission(StockAdjustmentService.adjustPermission);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _items = itemsResult.items;
      _canCreate = canCreate;
      _canDelete = canDelete;
      _canAdjustStock = canAdjustStock;
      if (!itemsResult.allowed) {
        _statusMessage = itemsResult.errorMessage;
        _isErrorStatus = true;
      }
    });
  }

  Future<void> _openAddDialog() async {
    if (!_canCreate) {
      _showStatus(
        ManagerItemService.createDeniedMessage,
        isError: true,
      );
      return;
    }
    final input = await ItemFormDialog.show(context);
    if (input == null || !mounted) return;

    final result = await widget.service.addItem(
      input,
      userId: widget.activeUserId,
    );
    if (!mounted) return;
    _showStatus(result.message, isError: !result.success);
    if (result.success) await _loadItems();
  }

  Future<void> _openEditDialog(ManagerItem item) async {
    if (!_canCreate) {
      _showStatus(
        ManagerItemService.createDeniedMessage,
        isError: true,
      );
      return;
    }
    final input = await ItemFormDialog.show(context, initial: item);
    if (input == null || !mounted) return;

    final result = await widget.service.updateItem(
      itemId: item.id,
      currentSku: item.sku,
      input: input,
    );
    if (!mounted) return;
    _showStatus(result.message, isError: !result.success);
    if (result.success) await _loadItems();
  }

  /// Ubah stok memakai service & dialog yang sama dengan staff,
  /// sehingga stok manager <-> staff terhubung dan tercatat di riwayat.
  Future<void> _openAdjustDialog(ManagerItem item) async {
    if (!_canAdjustStock) {
      _showStatus(
        StockAdjustmentService.adjustDeniedMessage,
        isError: true,
      );
      return;
    }

    final stockItem = WarehouseItem(
      id: item.id,
      sku: item.sku,
      name: item.name,
      category: item.category,
      location: item.location,
      stock: item.stock,
      updatedAt: '',
    );
    final input = await StockAdjustmentDialog.show(context, item: stockItem);
    if (input == null || !mounted) return;

    final result = await widget.stockService.adjustStock(
      StockAdjustmentRequest(
        itemId: item.id,
        userId: widget.activeUserId,
        type: input.type,
        amount: input.amount,
        reason: input.reason,
      ),
    );
    if (!mounted) return;
    _showStatus(result.message, isError: !result.success);
    if (result.success) await _loadItems();
  }

  Future<void> _confirmDelete(ManagerItem item) async {
    if (!_canDelete) {
      _showStatus(
        ManagerItemService.deleteDeniedMessage,
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Konfirmasi Hapus',
          style: TextStyle(color: _primaryTeal, fontWeight: FontWeight.w700),
        ),
        content: Text('Apakah barang ${item.sku} ingin dihapus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Batal', style: TextStyle(color: _primaryTeal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await widget.service.deleteItem(item.id, item.sku);
    if (!mounted) return;
    _showStatus(result.message, isError: !result.success);
    if (result.success) await _loadItems();
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isErrorStatus = isError;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStock = _items.fold<int>(0, (sum, item) => sum + item.stock);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
        title: const Text('Gudang RBAC — Manajemen Barang'),
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
                  child: ManagerSummaryHeader(
                    userName: widget.activeUserName,
                    roleLabel: widget.activeRoleLabel,
                    itemCount: _items.length,
                    totalStock: totalStock,
                  ),
                ),
                if (_statusMessage != null)
                  ManagerStatusBanner(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
        backgroundColor: _canCreate ? _primaryTeal : Colors.grey,
        foregroundColor: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        return ManagerItemCard(
          item: item,
          canEdit: _canCreate,
          canDelete: _canDelete,
          onEdit: () => _openEditDialog(item),
          onAdjustStock: () => _openAdjustDialog(item),
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }
}
