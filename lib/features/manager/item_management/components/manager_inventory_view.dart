import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/app_theme.dart';
import '../../../shared/dashboard_widgets.dart';
import '../../../shared/flow.dart';
import '../../../shared/stock_movement_service.dart';
import '../../../staff/stock_adjustment/stock_adjustment.dart';
import '../services/manager_item_service.dart';
import '../types/manager_models.dart';

class ManagerInventoryView extends StatefulWidget {
  const ManagerInventoryView({
    super.key,
    required this.service,
    required this.stockService,
    required this.db,
    required this.activeUserId,
    this.activeUserName,
    this.activeRoleLabel,
    this.onSwitchAccount,
  });

  final ManagerItemService service;

  /// Service stok yang sama dengan yang dipakai staff, agar perubahan
  /// stok manager & staff terhubung (satu DB, satu tabel stock_movements).
  final StockAdjustmentService stockService;
  final Database db;
  final int activeUserId;
  final String? activeUserName;
  final String? activeRoleLabel;
  final VoidCallback? onSwitchAccount;

  @override
  State<ManagerInventoryView> createState() => _ManagerInventoryViewState();
}

class _ManagerInventoryViewState extends State<ManagerInventoryView> {
  final TextEditingController _searchController = TextEditingController();

  List<ManagerItem> _items = const [];
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canDelete = false;
  bool _canAdjustStock = false;
  String? _statusMessage;
  bool _isErrorStatus = false;
  String _query = '';

  late final StockMovementService _movementService = StockMovementService(
    widget.db,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final itemsResult = await widget.service.getItems();
    final canCreate = await widget.service.hasPermission(
      ManagerItemService.createPermission,
    );
    final canDelete = await widget.service.hasPermission(
      ManagerItemService.deletePermission,
    );
    final canAdjustStock = await widget.service.hasPermission(
      StockAdjustmentService.adjustPermission,
    );
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

  List<ManagerItem> get _filteredItems {
    if (_query.isEmpty) return _items;
    return _items.where((item) {
      return item.sku.toLowerCase().contains(_query) ||
          item.name.toLowerCase().contains(_query) ||
          item.category.toLowerCase().contains(_query) ||
          item.location.toLowerCase().contains(_query);
    }).toList();
  }

  /// Alur penuh "Tambah barang": form layar penuh → layar sukses.
  Future<void> _openAddItem() async {
    if (!_canCreate) {
      _showStatus(ManagerItemService.createDeniedMessage, isError: true);
      return;
    }
    final input = await ItemFormPage.show(context);
    if (input == null || !mounted) return;

    final result = await widget.service.addItem(
      input,
      userId: widget.activeUserId,
    );
    if (!mounted) return;
    if (result.success) {
      await _loadItems();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlowSuccessScreen(
            title: 'Barang tersimpan',
            message:
                '${input.name.trim()} (${input.sku.trim()}) sudah masuk ke daftar barang.',
            bigValue: '${input.stock}',
            bigValueLabel: input.satuan.trim(),
            buttonLabel: 'Kembali ke daftar',
          ),
        ),
      );
    } else {
      _showStatus(result.message, isError: true);
    }
  }

  /// SATU alur gabungan "Ubah Barang": data + stok dalam satu layar
  /// (form → konfirmasi → layar sukses).
  Future<void> _openEditItem(ManagerItem item) async {
    if (!_canCreate && !_canAdjustStock) return;
    await ItemEditPage.push(
      context,
      item: item,
      canEditData: _canCreate,
      canAdjustStock: _canAdjustStock,
      saveData: (input) => widget.service.updateItem(
        itemId: item.id,
        currentSku: item.sku,
        input: input,
      ),
      adjustStock: (input) => widget.stockService.adjustStock(
        StockAdjustmentRequest(
          itemId: item.id,
          userId: widget.activeUserId,
          type: input.type,
          amount: input.amount,
          reason: input.reason,
        ),
      ),
    );
    if (mounted) await _loadItems();
  }

  Future<void> _confirmDelete(ManagerItem item) async {
    if (!_canDelete) {
      _showStatus(ManagerItemService.deleteDeniedMessage, isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text(
          'Hapus barang?',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '${item.name} (${item.sku}) akan dihapus permanen dari daftar.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
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

  /// Tap kartu → halaman detail penuh; tombol tunggal "Ubah Barang".
  Future<void> _openDetail(ManagerItem item) async {
    await ItemDetailPage.push(
      context,
      item: item,
      movementService: _movementService,
      canEdit: _canCreate,
      canDelete: _canDelete,
      canAdjustStock: _canAdjustStock,
      onEdit: () => _openEditItem(item),
      onDelete: () => _confirmDelete(item),
    );
    if (mounted) await _loadItems();
  }

  /// Satu sumber umpan balik saja: banner inline. Tidak ada snackbar ganda.
  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isErrorStatus = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = _items.where((item) => item.stock <= item.minStock).length;
    final filtered = _filteredItems;
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(
        title: const Text('Gudang RBAC'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadItems,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                DashboardUserHeader(
                  userName: widget.activeUserName,
                  roleLabel: widget.activeRoleLabel,
                  onSwitchAccount: widget.onSwitchAccount,
                ),
                DashboardHeroCard(
                  title: 'Beranda gudang',
                  subtitle: 'Kelola master barang dan pantau stok.',
                  stats: [
                    DashboardStat('Jenis barang', '${_items.length}'),
                    DashboardStat('Stok menipis', '$lowStock'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari nama atau kode barang',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                if (_statusMessage != null)
                  AppStatusBanner(
                    message: _statusMessage!,
                    isError: _isErrorStatus,
                    onDismiss: () => setState(() => _statusMessage = null),
                  ),
                DashboardSectionTitle(count: filtered.length),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryTeal,
                    onRefresh: _loadItems,
                    child: _buildBody(filtered),
                  ),
                ),
                const DashboardHintBar(
                  message: 'Pilih barang untuk melihat detail dan mengubahnya.',
                ),
              ],
            ),
          ),
        ),
      ),
      // FAB hanya muncul jika role benar-benar boleh menambah barang.
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _openAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Barang'),
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBody(List<ManagerItem> items) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black26),
          SizedBox(height: 10),
          Center(
            child: Text(
              'Belum ada barang tersedia.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return DashboardItemCard(item: item, onTap: () => _openDetail(item));
      },
    );
  }
}
