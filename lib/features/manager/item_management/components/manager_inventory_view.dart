import 'package:flutter/material.dart';

import '../../../common/warehouse_theme.dart';
import '../../../staff/stock_adjustment/stock_adjustment.dart';
import '../services/manager_item_service.dart';
import '../types/manager_models.dart';
import 'item_form_dialog.dart';
import 'manager_item_card.dart';
import 'manager_summary_header.dart';

/// Halaman "Beranda gudang" untuk role manager sesuai desain Figma:
/// kartu ringkasan teal, kolom pencarian, daftar barang, dan tombol
/// amber "Tambah barang" di bawah.
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
  List<ManagerItem> _items = const [];
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canDelete = false;
  bool _canAdjustStock = false;
  String? _statusMessage;
  bool _isErrorStatus = false;
  String _searchQuery = '';

  List<ManagerItem> get _filteredItems {
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
      builder: (ctx) => _WarehouseConfirmDialog(item: item),
    );

    if (confirmed != true || !mounted) return;

    final result = await widget.service.deleteItem(item.id, item.sku);
    if (!mounted) return;
    _showStatus(result.message, isError: !result.success);
    if (result.success) await _loadItems();
  }

  /// Lembar aksi barang (Ubah Stok / Edit / Hapus) saat kartu diketuk.
  Future<void> _openItemActions(ManagerItem item) {
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
                const SizedBox(height: 16),
                WarehousePrimaryButton(
                  label: 'Ubah Stok',
                  icon: Icons.tune,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openAdjustDialog(item);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _canCreate
                      ? () {
                          Navigator.of(sheetContext).pop();
                          _openEditDialog(item);
                        }
                      : null,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    _canCreate ? 'Edit barang' : 'Edit barang (tanpa izin)',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _canCreate
                        ? WarehouseColors.primaryTeal
                        : Colors.grey,
                    side: BorderSide(
                      color: _canCreate
                          ? WarehouseColors.softMint
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _canDelete
                      ? () {
                          Navigator.of(sheetContext).pop();
                          _confirmDelete(item);
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    _canDelete ? 'Hapus barang' : 'Hapus barang (tanpa izin)',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _canDelete
                        ? WarehouseColors.dangerRed
                        : Colors.grey,
                    side: BorderSide(
                      color: _canDelete
                          ? WarehouseColors.dangerBg
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: WarehouseColors.background,
      appBar: WarehouseAppBar(
        subtitle:
            'Halo, ${widget.activeUserName ?? 'Kepala Gudang'} · ${widget.activeRoleLabel ?? 'manager'}',
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
                    title: 'Beranda gudang',
                    subtitle: 'Kelola master barang & pantau stok gudang',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: ManagerSummaryHeader(
                    userName: widget.activeUserName,
                    roleLabel: widget.activeRoleLabel,
                    itemCount: _items.length,
                    totalStock: totalStock,
                  ),
                ),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ManagerStatusBanner(
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: WarehousePrimaryButton(
            label: 'Tambah barang',
            icon: Icons.add,
            onPressed: _openAddDialog,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<ManagerItem> items) {
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return ManagerItemCard(
          item: item,
          canEdit: _canCreate,
          canDelete: _canDelete,
          onOpenDetails: () => _openItemActions(item),
        );
      },
    );
  }
}

/// Dialog konfirmasi hapus bergaya Figma (putih membulat, tombol merah).
class _WarehouseConfirmDialog extends StatelessWidget {
  const _WarehouseConfirmDialog({required this.item});

  final ManagerItem item;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Konfirmasi Hapus',
        style: TextStyle(
          color: WarehouseColors.primaryTeal,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text('Apakah barang ${item.sku} ingin dihapus?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Batal',
            style: TextStyle(color: WarehouseColors.primaryTeal),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: WarehouseColors.dangerRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
