import 'package:flutter/material.dart';

import '../types/stock_models.dart';

class StockDialogItemBanner extends StatelessWidget {
  const StockDialogItemBanner({super.key, required this.item});

  final WarehouseItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E0CA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.name} (${item.sku})',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF102A2A),
            ),
          ),
          Text(
            'Stok saat ini: ${item.stock}',
            style: const TextStyle(color: Color(0xFF145858)),
          ),
        ],
      ),
    );
  }
}

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
          selectedColor: const Color(0xFF145858),
          backgroundColor: const Color(0xFFC8E0CA),
          labelStyle: TextStyle(
            color: isIncrease ? Colors.white : const Color(0xFF102A2A),
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onSelected(StockAdjustmentType.increase),
        ),
        ChoiceChip(
          label: const Text('Kurangi Stok'),
          selected: !isIncrease,
          selectedColor: const Color(0xFFF7B318),
          backgroundColor: const Color(0xFFC8E0CA),
          labelStyle: const TextStyle(
            color: Color(0xFF102A2A),
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onSelected(StockAdjustmentType.decrease),
        ),
      ],
    );
  }
}
