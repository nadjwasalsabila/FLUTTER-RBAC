import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../manager/item_management/types/manager_models.dart';
import '../stock_movement_service.dart';
import 'flow_widgets.dart';

/// Halaman detail barang sesuai mockup: judul besar nama barang,
/// kartu teal gelap dengan stok besar + kotak "Tersedia",
/// baris info putih, catatan mint, dan tombol amber di bawah.
class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({
    super.key,
    required this.item,
    required this.movementService,
    this.canEdit = false,
    this.canDelete = false,
    this.canAdjustStock = false,
    this.onEdit,
    this.onDelete,
  });

  final ManagerItem item;
  final StockMovementService movementService;
  final bool canEdit;
  final bool canDelete;
  final bool canAdjustStock;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static Future<void> push(
    BuildContext context, {
    required ManagerItem item,
    required StockMovementService movementService,
    bool canEdit = false,
    bool canDelete = false,
    bool canAdjustStock = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(
          item: item,
          movementService: movementService,
          canEdit: canEdit,
          canDelete: canDelete,
          canAdjustStock: canAdjustStock,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  late Future<List<StockMovement>> _movementsFuture;
  late ManagerItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _movementsFuture = widget.movementService.getMovements(_item.id);
  }

  void _runAction(VoidCallback? action) {
    if (action == null) return;
    action();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final isLowStock = item.stock <= item.minStock;

    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(
        title: const Text('Detail barang'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (widget.canDelete)
            IconButton(
              onPressed: () => _runAction(widget.onDelete),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus barang',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Judul besar: nama barang + SKU · kategori
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.sku} · ${item.category}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                // Kartu teal gelap: ikon kotak, "Stok saat ini",
                // stok besar "120 rim", kotak status "Tersedia".
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B6B63),
                        Color(0xFF145858),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Stok saat ini',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.stock} ${item.satuan}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isLowStock ? 'Menipis' : 'Tersedia',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Info putih: Lokasi penyimpanan / Satuan / Batas stok minimum.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Lokasi penyimpanan', item.location),
                      const Divider(height: 1, color: AppColors.border),
                      _infoRow('Satuan', item.satuan),
                      const Divider(height: 1, color: AppColors.border),
                      _infoRow(
                        'Batas stok minimum',
                        '${item.minStock} ${item.satuan}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Catatan mint.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Periksa jumlah fisik barang sebelum memperbarui stok.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMovements(),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
      // SATU tombol amber di bawah: buka layar Ubah Barang / Ubah Stok.
      bottomNavigationBar: (widget.canEdit || widget.canAdjustStock)
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AmberButton(
                label: widget.canEdit ? 'Ubah Barang' : 'Ubah Stok',
                onTap: () => _runAction(widget.onEdit),
              ),
            )
          : null,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovements() {
    return FutureBuilder<List<StockMovement>>(
      future: _movementsFuture,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat pergerakan stok',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              )
            else if (snapshot.hasError)
              const Text(
                'Gagal memuat riwayat.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              )
            else if ((snapshot.data ?? []).isEmpty)
              const Text(
                'Belum ada pergerakan stok tercatat.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              )
            else
              ...snapshot.data!.map(_movementTile),
          ],
        );
      },
    );
  }

  Widget _movementTile(StockMovement m) {
    final isIncoming = m.delta >= 0;
    final date = DateTime.tryParse(m.createdAt);
    final dateLabel = date == null
        ? ''
        : '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isIncoming ? AppColors.successBg : AppColors.errorBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncoming
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 16,
              color: isIncoming ? AppColors.primaryTeal : AppColors.errorRed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.reason,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  '${m.userName} · $dateLabel',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${m.delta >= 0 ? '+' : ''}${m.delta}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isIncoming ? AppColors.primaryTeal : AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}
