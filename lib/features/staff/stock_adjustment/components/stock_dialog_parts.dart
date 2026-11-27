import 'package:flutter/material.dart';

import '../../../common/warehouse_theme.dart';
import '../types/stock_models.dart';

/// Banner barang pada dialog ubah stok: mint lembut + ikon kotak.
class StockDialogItemBanner extends StatelessWidget {
  const StockDialogItemBanner({super.key, required this.item});

  final WarehouseItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarehouseColors.paleMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const WarehouseItemChip(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name} (${item.sku})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: WarehouseColors.darkText,
                  ),
                ),
                Text(
                  'Stok saat ini: ${item.stock} unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WarehouseColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
          WarehouseStockBadge(stock: item.stock),
        ],
      ),
    );
  }
}

/// Pilihan jenis perubahan: Tambah Stok (teal) / Kurangi Stok (amber).
class StockAdjustmentTypeChips extends StatelessWidget {
  const StockAdjustmentTypeChips({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  final StockAdjustmentType selectedType;
  final ValueChanged<StockAdjustmentType> onSelected;

  @override
  Widget build(BuildContext context) {
    final isIncrease = selectedType == StockAdjustmentType.increase;
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Tambah Stok'),
          selected: isIncrease,
          selectedColor: WarehouseColors.primaryTeal,
          backgroundColor: WarehouseColors.paleMint,
          showCheckmark: false,
          labelStyle: TextStyle(
            color: isIncrease ? Colors.white : WarehouseColors.primaryTeal,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onSelected(StockAdjustmentType.increase),
        ),
        ChoiceChip(
          label: const Text('Kurangi Stok'),
          selected: !isIncrease,
          selectedColor: WarehouseColors.warmAmber,
          backgroundColor: WarehouseColors.paleMint,
          showCheckmark: false,
          labelStyle: TextStyle(
            color: !isIncrease ? Colors.white : WarehouseColors.primaryTeal,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onSelected(StockAdjustmentType.decrease),
        ),
      ],
    );
  }
}
