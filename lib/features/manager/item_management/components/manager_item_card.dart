import 'package:flutter/material.dart';

import '../../../common/warehouse_theme.dart';
import '../types/manager_models.dart';

/// Kartu barang gaya Figma: chip ikon, nama, keterangan, badge stok,
/// dan chevron — ketuk kartu untuk membuka daftar aksi.
class ManagerItemCard extends StatelessWidget {
  const ManagerItemCard({
    super.key,
    required this.item,
    required this.canEdit,
    required this.canDelete,
    required this.onOpenDetails,
  });

  final ManagerItem item;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WarehouseColors.softMint.withValues(alpha: 0.6)),
          ),
          child: Row(
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: WarehouseColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  WarehouseStockBadge(stock: item.stock),
                  const SizedBox(height: 4),
                  Text(
                    '${item.stock} unit',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: WarehouseColors.subtitleText,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: WarehouseColors.subtitleText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
