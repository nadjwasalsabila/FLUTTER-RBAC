import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../auth/types/auth_user.dart';
import '../manager/item_management/item_management.dart';
import 'admin_policy_page.dart';

/// Beranda admin. Tampilan mengikuti referensi: header teal, kartu statistik,
/// kolom pencarian, daftar barang, dan tombol mengelola izin peran.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    super.key,
    required this.db,
    required this.user,
    this.onSwitchAccount,
  });

  final Database db;
  final AuthUser user;
  final VoidCallback? onSwitchAccount;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _warmAmber = Color(0xFFF7B318);
  static const _paleMint = Color(0xFFE8F1E9);
  static const _darkText = Color(0xFF102A2A);

  final TextEditingController _searchController = TextEditingController();
  List<_AdminItem> _items = const [];
  bool _isLoading = true;
  String _query = '';

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
    try {
      final rows = await widget.db.query(
        'warehouse_items',
        columns: const ['id', 'sku', 'name', 'category', 'location', 'stock'],
        orderBy: 'sku ASC',
      );
      if (!mounted) return;
      setState(() {
        _items = rows.map(_AdminItem.fromMap).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<_AdminItem> get _filteredItems {
    if (_query.isEmpty) return _items;
    return _items.where((item) {
      return item.sku.toLowerCase().contains(_query) ||
          item.name.toLowerCase().contains(_query) ||
          item.category.toLowerCase().contains(_query) ||
          item.location.toLowerCase().contains(_query);
    }).toList();
  }

  Future<void> _openAddItem() async {
    final input = await ItemFormDialog.show(context);
    if (input == null || !mounted) return;

    final service = ManagerItemService(widget.db, (perm) async {
      final rows = await widget.db.query(
        'role_permissions',
        columns: const ['permission_key'],
        where: 'role_id = ? AND permission_key = ? AND is_active = 1',
        whereArgs: [widget.user.roleId, perm],
        limit: 1,
      );
      return rows.isNotEmpty;
    });

    final result = await service.addItem(input, userId: widget.user.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? _primaryTeal : Colors.red.shade700,
      ),
    );
    if (result.success) await _loadItems();
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
      backgroundColor: _paleMint,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Beranda gudang',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: _primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kelola barang, pantau stok hari ini.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        _buildStatsCard(lowStock),
                        const SizedBox(height: 18),
                        _buildSearchField(),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Text(
                              'Daftar barang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _primaryTeal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${filtered.length} barang',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _openAddItem,
                              icon: const Icon(Icons.add_circle_outline),
                              color: _primaryTeal,
                              tooltip: 'Tambah barang',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(color: _primaryTeal),
                            ),
                          )
                        else if (filtered.isEmpty)
                          _buildEmptyState()
                        else
                          ...filtered.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AdminItemCard(item: item),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _warmAmber,
                              foregroundColor: _darkText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _openPolicy,
                            child: const Text(
                              'Kelola izin peran',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: _primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warehouse_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  'Admin Sistem',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (widget.onSwitchAccount != null)
            IconButton(
              onPressed: widget.onSwitchAccount,
              color: _warmAmber,
              tooltip: 'Ganti akun',
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int lowStock) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primaryTeal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _StatColumn(label: 'Jenis barang', value: '${_items.length}'),
          const SizedBox(width: 28),
          _StatColumn(label: 'Stok menipis', value: '$lowStock'),
          const Spacer(),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama atau kode barang',
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _softMint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryTeal, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softMint),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            'Tidak ada barang yang cocok.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class _AdminItem {
  const _AdminItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
  });

  final int id;
  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;

  factory _AdminItem.fromMap(Map<String, Object?> map) {
    return _AdminItem(
      id: map['id']! as int,
      sku: map['sku']! as String,
      name: map['name']! as String,
      category: map['category']! as String,
      location: map['location']! as String,
      stock: map['stock']! as int,
    );
  }
}

class _AdminItemCard extends StatelessWidget {
  const _AdminItemCard({required this.item});

  final _AdminItem item;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.stock <= 10;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EDE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1E9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF145858),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _AdminHomePageState._darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.sku} · ${item.location}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${item.stock} rim',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _AdminHomePageState._darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lowStock
                            ? const Color(0xFFFFF0C2)
                            : const Color(0xFFE3F2E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lowStock ? 'Menipis' : 'Tersedia',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: lowStock
                              ? const Color(0xFF8A6100)
                              : const Color(0xFF145858),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    );
  }
}
