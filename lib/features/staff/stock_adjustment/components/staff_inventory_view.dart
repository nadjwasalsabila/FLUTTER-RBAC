import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/app_theme.dart';
import '../../../manager/item_management/types/manager_models.dart';
import '../../../shared/dashboard_widgets.dart';
import '../../../shared/flow.dart';
import '../../../shared/stock_movement_service.dart';
import '../services/stock_adjustment_service.dart';
import '../types/stock_models.dart';

class StaffInventoryView extends StatefulWidget {
  const StaffInventoryView({
    super.key,
    required this.service,
    required this.db,
    required this.activeUserId,
    this.activeUserName,
    this.activeRoleLabel,
    this.onSwitchAccount,
  });

  final StockAdjustmentService service;
  final Database db;
  final int activeUserId;
  final String? activeUserName;
  final String? activeRoleLabel;
  final VoidCallback? onSwitchAccount;

  @override
  State<StaffInventoryView> createState() => _StaffInventoryViewState();
}

class _StaffInventoryViewState extends State<StaffInventoryView> {
  final TextEditingController _searchController = TextEditingController();

  List<WarehouseItem> _items = const [];
  bool _isLoading = true;
  bool _canAdjust = false;
  String? _statusMessage;
  bool _isErrorStatus = false;
  String _query = '';

  late final StockMovementService _movementService =
      StockMovementService(widget.db);

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
    final result = await widget.service.getItems();
    // Izin dicek lewat service stok itu sendiri; hasilnya dipakai untuk
    // memutuskan apakah aksi "Ubah Stok" ditawarkan atau tidak.
    final canAdjust =
        (await widget.service.checkPermission(
          StockAdjustmentService.adjustPermission,
        ))
            .allowed;
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _items = result.items;
      _canAdjust = canAdjust;
      if (!result.allowed) {
        _statusMessage = result.errorMessage;
        _isErrorStatus = true;
      }
    });
  }

  List<WarehouseItem> get _filteredItems {
    if (_query.isEmpty) return _items;
    return _items.where((item) {
      return item.sku.toLowerCase().contains(_query) ||
          item.name.toLowerCase().contains(_query) ||
          item.category.toLowerCase().contains(_query) ||
          item.location.toLowerCase().contains(_query);
    }).toList();
  }

  /// SATU alur gabungan "Ubah Stok" (staff hanya boleh stok):
  /// form → konfirmasi → layar sukses.
  Future<void> _openEditStock(ManagerItem item) async {
    if (!_canAdjust) {
      _showStatus(StockAdjustmentService.adjustDeniedMessage, isError: true);
      return;
    }
    await ItemEditPage.push(
      context,
      item: item,
      canEditData: false,
      canAdjustStock: _canAdjust,
      saveData: (_) async => throw UnsupportedError('no data edit'),
      adjustStock: (input) => widget.service.adjustStock(
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

  /// Tap kartu → halaman detail penuh; tombol tunggal "Ubah Stok".
  Future<void> _openDetail(WarehouseItem warehouseItem) {
    final item = ManagerItem(
      id: warehouseItem.id,
      sku: warehouseItem.sku,
      name: warehouseItem.name,
      category: warehouseItem.category,
      location: warehouseItem.location,
      stock: warehouseItem.stock,
      satuan: warehouseItem.satuan,
      minStock: warehouseItem.minStock,
    );
    return ItemDetailPage.push(
      context,
      item: item,
      movementService: _movementService,
      canAdjustStock: _canAdjust,
      onEdit: () => _openEditStock(item),
    ).then((_) {
      if (mounted) _loadItems();
    });
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
    final lowStock =
        _items.where((item) => item.stock <= item.minStock).length;
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
                  subtitle: 'Kelola barang, pantau stok harian.',
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
                  message: 'Pilih barang untuk melihat detail dan mengubah stok.',
                ),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return DashboardItemCard(
          item: ManagerItem(
            id: item.id,
            sku: item.sku,
            name: item.name,
            category: item.category,
            location: item.location,
            stock: item.stock,
            satuan: item.satuan,
            minStock: item.minStock,
          ),
          onTap: () => _openDetail(item),
        );
      },
    );
  }
}
