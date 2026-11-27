import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/flow_widgets.dart';
import '../models/warehouse_models.dart';
import '../services/stock_movement_service.dart';

/// Halaman detail barang: menampilkan info stok, riwayat pergerakan,
/// tombol Hapus (jika `canDelete`), dan tombol Ubah Barang / Ubah Stok
/// (jika `canEdit || canAdjustStock`).
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

  final WarehouseItem item;
  final StockMovementService movementService;
  final bool canEdit;
  final bool canDelete;
  final bool canAdjustStock;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDelete;

  static Future<void> push(
    BuildContext context, {
    required WarehouseItem item,
    required StockMovementService movementService,
    bool canEdit = false,
    bool canDelete = false,
    bool canAdjustStock = false,
    VoidCallback? onEdit,
    Future<bool> Function()? onDelete,
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

  @override
  void initState() {
    super.initState();
    _movementsFuture = widget.movementService.getMovements(widget.item.id);
  }

  Future<void> _handleDelete() async {
    final deleted = await widget.onDelete?.call() ?? false;
    if (deleted && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLowStock = item.isLowStock;

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
              onPressed: _handleDelete,
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B6B63), Color(0xFF145858)],
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
                        style: TextStyle(fontSize: 13, color: Colors.white70),
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
                    style: TextStyle(fontSize: 12, color: AppColors.darkText),
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
      bottomNavigationBar: (widget.canEdit || widget.canAdjustStock)
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AmberButton(
                label: widget.canEdit ? 'Ubah Barang' : 'Ubah Stok',
                onTap: () => widget.onEdit?.call(),
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
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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
