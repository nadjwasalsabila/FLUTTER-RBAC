import 'package:flutter/material.dart';

import '../../../common/warehouse_theme.dart';

/// Kartu ringkasan teal gelap ala Figma untuk staf gudang.
class StaffSummaryHeader extends StatelessWidget {
  const StaffSummaryHeader({
    super.key,
    required this.userName,
    required this.roleLabel,
    required this.itemCount,
    required this.totalStock,
  });

  final String? userName;
  final String? roleLabel;
  final int itemCount;
  final int totalStock;

  @override
  Widget build(BuildContext context) {
    return WarehouseSummaryCard(
      stats: [
        WarehouseStat(value: '$itemCount', label: 'Jenis barang'),
        WarehouseStat(value: '$totalStock', label: 'Total stok'),
      ],
      icon: Icons.local_shipping_outlined,
    );
  }
}

/// Banner status hasil aksi (sukses hijau lembut / gagal merah lembut).
class StaffStatusBanner extends StatelessWidget {
  const StaffStatusBanner({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: isError ? WarehouseColors.dangerBg : WarehouseColors.successBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 20,
            color: isError
                ? WarehouseColors.dangerRed
                : WarehouseColors.successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isError
                    ? WarehouseColors.dangerRed
                    : WarehouseColors.primaryTeal,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close,
              size: 18,
              color: WarehouseColors.subtitleText,
            ),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
