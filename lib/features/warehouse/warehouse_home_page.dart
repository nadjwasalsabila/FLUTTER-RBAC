import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/app_theme.dart';
import '../../core/rbac/permission_service.dart';
import '../../core/widgets/flow_widgets.dart';
import '../admin/admin_policy_page.dart';
import '../auth/components/register_screen.dart';
import '../auth/state/auth_state.dart';
import '../auth/types/auth_user.dart';
import 'models/warehouse_models.dart';
import 'services/item_service.dart';
import 'services/stock_adjustment_service.dart';
import 'services/stock_movement_service.dart';
import 'widgets/dashboard_widgets.dart';
import 'widgets/item_detail_page.dart';
import 'widgets/item_edit_page.dart';
import 'widgets/item_form_page.dart';

/// SATU beranda gudang terpadu untuk seluruh peran (staff, manager, admin).
/// Seluruh aksi UI (Tambah, Ubah, Hapus, Ubah Stok, Kelola Izin, Buat Akun)
/// ditampilkan atau disembunyikan secara dinamis berdasarkan `role_permissions`
/// yang aktif di database, sementara validasi keamanan tetap dijaga di service.
class WarehouseHomePage extends StatefulWidget {
  const WarehouseHomePage({
    super.key,
    required this.db,
    required this.user,
    this.authState,
    this.onSwitchAccount,
  });

  final Database db;
  final AuthUser user;
  final AuthState? authState;
  final VoidCallback? onSwitchAccount;

  @override
  State<WarehouseHomePage> createState() => _WarehouseHomePageState();
}

class _WarehouseHomePageState extends State<WarehouseHomePage> {
  final TextEditingController _searchController = TextEditingController();

  late PermissionService _permissionService;
  late ItemService _itemService;
  late StockAdjustmentService _stockService;
  late StockMovementService _movementService;

  List<WarehouseItem> _items = const [];
  Set<String> _permissions = const {};
  bool _isLoading = true;
  String? _statusMessage;
  bool _isErrorStatus = false;
  String _query = '';

  bool get _canCreate => _permissions.contains(AppPermissions.itemCreate);
  bool get _canDelete => _permissions.contains(AppPermissions.itemDelete);
  bool get _canAdjustStock => _permissions.contains(AppPermissions.stockAdjust);
  bool get _canEditPolicy => _permissions.contains(AppPermissions.policyEdit);

  @override
  void initState() {
    super.initState();
    _initServices();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _loadData();
  }

  @override
  void didUpdateWidget(covariant WarehouseHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.db != widget.db || oldWidget.user != widget.user) {
      _initServices();
      _loadData();
    }
  }

  void _initServices() {
    _permissionService = PermissionService(widget.db);
    final checker = _permissionService.checkerForRole(widget.user.roleId);
    _itemService = ItemService(widget.db, checker);
    _stockService = StockAdjustmentService(widget.db, checker);
    _movementService = StockMovementService(widget.db);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final perms = await _permissionService.getActivePermissions(
        widget.user.roleId,
      );
      final itemsResult = await _itemService.getItems();
      if (!mounted) return;
      setState(() {
        _permissions = perms;
        _items = itemsResult.items;
        _isLoading = false;
        if (!itemsResult.allowed) {
          _statusMessage = itemsResult.errorMessage;
          _isErrorStatus = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'Gagal memuat data gudang.';
        _isErrorStatus = true;
      });
    }
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

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isErrorStatus = isError;
    });
  }

  Future<void> _openAddItem() async {
    if (!_canCreate) {
      _showStatus(ItemService.createDeniedMessage, isError: true);
      return;
    }
    final input = await ItemFormPage.show(context);
    if (input == null || !mounted) return;

    final result = await _itemService.addItem(input, userId: widget.user.id);
    if (!mounted) return;

    if (result.success) {
      await _loadData();
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

  Future<void> _openEditItem(WarehouseItem item) async {
    if (!_canCreate && !_canAdjustStock) return;
    await ItemEditPage.push(
      context,
      item: item,
      canEditData: _canCreate,
      canAdjustStock: _canAdjustStock,
      saveData: (input) => _itemService.updateItem(
        itemId: item.id,
        currentSku: item.sku,
        input: input,
      ),
      adjustStock: (input) => _stockService.adjustStock(
        StockAdjustmentRequest(
          itemId: item.id,
          userId: widget.user.id,
          type: input.type,
          amount: input.amount,
          reason: input.reason,
        ),
      ),
    );
    if (mounted) await _loadData();
  }

  Future<bool> _confirmDelete(WarehouseItem item) async {
    if (!_canDelete) {
      _showStatus(ItemService.deleteDeniedMessage, isError: true);
      return false;
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

    if (confirmed != true || !mounted) return false;

    final result = await _itemService.deleteItem(item.id, item.sku);
    if (!mounted) return false;
    _showStatus(result.message, isError: !result.success);
    if (result.success) {
      await _loadData();
      return true;
    }
    return false;
  }

  Future<void> _openDetail(WarehouseItem item) async {
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
    if (mounted) await _loadData();
  }

  void _openCreateAccount() {
    final authState = widget.authState;
    if (authState == null || !_canEditPolicy) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(
          authState: authState,
          adminMode: true,
          onAccountCreated: () {},
        ),
      ),
    );
  }

  Future<void> _openPolicy() async {
    if (!_canEditPolicy) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminPolicyPage(
          db: widget.db,
          fullName: widget.user.fullName,
          roleId: widget.user.roleId,
        ),
      ),
    );
    if (mounted) await _loadData();
  }

  String get _heroTitle =>
      _canEditPolicy ? 'Beranda admin' : 'Beranda gudang';

  String get _heroSubtitle {
    if (_canEditPolicy) return 'Kelola barang dan kebijakan izin peran.';
    if (_canCreate) return 'Kelola master barang dan pantau stok.';
    return 'Kelola barang, pantau stok harian.';
  }

  String get _hintMessage {
    if (_canCreate) {
      return 'Pilih barang untuk melihat detail, mengubah, atau menghapusnya.';
    }
    if (_canAdjustStock) {
      return 'Pilih barang untuk melihat detail dan mengubah stok.';
    }
    return 'Pilih barang untuk melihat detail dan riwayat stok.';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final lowStock = _items.where((item) => item.isLowStock).length;

    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(
        title: const Text('Gudang RBAC'),
        actions: [
          if (_canEditPolicy && widget.authState != null)
            IconButton(
              onPressed: _openCreateAccount,
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Buat akun manager / staff',
            ),
          if (_canEditPolicy)
            IconButton(
              onPressed: _openPolicy,
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Kelola izin peran',
            ),
          IconButton(
            onPressed: _isLoading ? null : _loadData,
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
                  userName: widget.user.fullName,
                  roleLabel: widget.user.roleId,
                  onSwitchAccount: widget.onSwitchAccount,
                ),
                DashboardHeroCard(
                  title: _heroTitle,
                  subtitle: _heroSubtitle,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      const Text(
                        'Daftar barang',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${filtered.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (_canCreate)
                        TextButton.icon(
                          onPressed: _openAddItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah barang'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryTeal,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryTeal,
                    onRefresh: _loadData,
                    child: _buildItemList(filtered),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemList(List<WarehouseItem> filtered) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildEmptyState(),
          DashboardHintBar(message: _hintMessage),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: filtered.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == filtered.length) {
          return DashboardHintBar(message: _hintMessage);
        }
        final item = filtered[index];
        return DashboardItemCard(
          item: item,
          onTap: () => _openDetail(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.black26,
          ),
          const SizedBox(height: 10),
          Text(
            _query.isEmpty
                ? 'Belum ada barang tersedia.'
                : 'Tidak ada barang yang cocok.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
