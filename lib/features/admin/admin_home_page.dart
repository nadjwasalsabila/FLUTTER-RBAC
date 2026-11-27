import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/app_theme.dart';
import '../auth/components/register_screen.dart';
import '../auth/state/auth_state.dart';
import '../auth/types/auth_user.dart';
import '../manager/item_management/services/manager_item_service.dart';
import '../manager/item_management/types/manager_models.dart';
import '../shared/dashboard_widgets.dart';
import '../shared/flow.dart';
import '../shared/stock_movement_service.dart';
import '../staff/stock_adjustment/stock_adjustment.dart';
import 'admin_policy_page.dart';

/// Beranda admin: header teal, kartu statistik, pencarian, daftar barang,
/// dan akses ke halaman kebijakan izin peran.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    super.key,
    required this.db,
    required this.user,
    this.onSwitchAccount,
    this.authState,
  });

  final Database db;
  final AuthUser user;
  final VoidCallback? onSwitchAccount;

  /// AuthState untuk membuat akun manager/staff dari beranda admin.
  final AuthState? authState;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<ManagerItem> _items = const [];
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canDelete = false;
  bool _canAdjustStock = false;
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

  Future<bool> _checkPermission(String perm) async {
    final rows = await widget.db.query(
      'role_permissions',
      columns: const ['permission_key'],
      where: 'role_id = ? AND permission_key = ? AND is_active = 1',
      whereArgs: [widget.user.roleId, perm],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final service = ManagerItemService(widget.db, _checkPermission);
      final result = await service.getItems();
      final canCreate = await _checkPermission('item:create');
      final canDelete = await _checkPermission('item:delete');
      final canAdjustStock = await _checkPermission('stock:adjust');
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _isLoading = false;
        _canCreate = canCreate;
        _canDelete = canDelete;
        _canAdjustStock = canAdjustStock;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
    if (!_canCreate) return;
    final input = await ItemFormPage.show(context);
    if (input == null || !mounted) return;

    final service = ManagerItemService(widget.db, _checkPermission);
    final result = await service.addItem(input, userId: widget.user.id);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  /// SATU alur gabungan "Ubah Barang": data + stok dalam satu layar
  /// (form → konfirmasi → layar sukses).
  Future<void> _openEditItem(ManagerItem item) async {
    if (!_canCreate && !_canAdjustStock) return;
    final stockService = StockAdjustmentService(
      widget.db,
      (perm) async => StockPermissionDecision(
        allowed: await _checkPermission(perm),
        missingPermission: null,
      ),
    );
    await ItemEditPage.push(
      context,
      item: item,
      canEditData: _canCreate,
      canAdjustStock: _canAdjustStock,
      saveData: (input) => ManagerItemService(widget.db, _checkPermission)
          .updateItem(itemId: item.id, currentSku: item.sku, input: input),
      adjustStock: (input) => stockService.adjustStock(
        StockAdjustmentRequest(
          itemId: item.id,
          userId: widget.user.id,
          type: input.type,
          amount: input.amount,
          reason: input.reason,
        ),
      ),
    );
    if (mounted) await _loadItems();
  }

  Future<void> _confirmDelete(ManagerItem item) async {
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

    final service = ManagerItemService(widget.db, _checkPermission);
    final result = await service.deleteItem(item.id, item.sku);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppColors.primaryTeal : AppColors.errorRed,
      ),
    );
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

  /// Buat akun manager/staff dari beranda admin (tanpa pindah login).
  void _openCreateAccount() {
    final authState = widget.authState;
    if (authState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layanan akun tidak tersedia.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
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

  void _openPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminPolicyPage(
          db: widget.db,
          fullName: widget.user.fullName,
          roleId: widget.user.roleId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final lowStock = _items.where((item) => item.stock <= 10).length;
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(
        title: const Text('Gudang RBAC'),
        actions: [
          IconButton(
            onPressed: _openCreateAccount,
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Buat akun manager / staff',
          ),
          IconButton(
            onPressed: _openPolicy,
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Kelola izin peran',
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadItems,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang data',
          ),
          if (widget.onSwitchAccount != null)
            IconButton(
              onPressed: widget.onSwitchAccount,
              icon: const Icon(Icons.logout),
              tooltip: 'Ganti akun',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              color: AppColors.primaryTeal,
              onRefresh: _loadItems,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                children: [
                  DashboardUserHeader(
                    userName: widget.user.fullName,
                    roleLabel: widget.user.roleId,
                    onSwitchAccount: widget.onSwitchAccount,
                  ),
                  DashboardHeroCard(
                    title: 'Beranda admin',
                    subtitle: 'Kelola barang dan kebijakan izin peran.',
                    stats: [
                      DashboardStat('Jenis barang', '${_items.length}'),
                      DashboardStat('Stok menipis', '$lowStock'),
                    ],
                    onStatTap: (i) {
                      if (i == 1) _openPolicy();
                    },
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
                  DashboardSectionTitle(count: filtered.length),
                  if (_canCreate)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _openAddItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Tambah barang'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryTeal,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildEmptyState(),
                    )
                  else
                    ...filtered.map(
                      (item) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: DashboardItemCard(
                          item: item,
                          onTap: () => _openDetail(item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            'Tidak ada barang yang cocok.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
