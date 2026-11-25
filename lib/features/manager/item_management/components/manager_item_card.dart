import 'package:flutter/material.dart';

import '../types/manager_models.dart';

class ManagerItemCard extends StatelessWidget {
  const ManagerItemCard({
    super.key,
    required this.item,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onAdjustStock,
    required this.onDelete,
  });

  final ManagerItem item;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;
  final VoidCallback onDelete;

  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _warmAmber = Color(0xFFF7B318);
  static const _darkText = Color(0xFF102A2A);

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.stock <= 10;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softMint, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _softMint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.sku,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primaryTeal,
                        ),
                      ),
                    ),
                    Text(
                      '${item.category} • ${item.location}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isLowStock ? _warmAmber : const Color(0xFFEAF4EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stok: ${item.stock}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onAdjustStock,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Ubah Stok'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    style: IconButton.styleFrom(
                      foregroundColor: canEdit ? _primaryTeal : Colors.grey,
                      side: BorderSide(
                        color: canEdit ? _primaryTeal : Colors.grey,
                      ),
                    ),
                    onPressed: onEdit,
                    tooltip: canEdit
                        ? 'Edit barang'
                        : 'Tidak ada izin item:create',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    style: IconButton.styleFrom(
                      foregroundColor: canDelete ? Colors.red : Colors.grey,
                      side: BorderSide(
                        color: canDelete ? Colors.red : Colors.grey,
                      ),
                    ),
                    onPressed: onDelete,
                    tooltip: canDelete
                        ? 'Hapus barang'
                        : 'Tidak ada izin item:delete',
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
