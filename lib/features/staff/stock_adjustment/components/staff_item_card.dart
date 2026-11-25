import 'package:flutter/material.dart';

import '../types/stock_models.dart';

class StaffItemCard extends StatelessWidget {
  const StaffItemCard({
    super.key,
    required this.item,
    required this.onAdjustPressed,
  });

  final WarehouseItem item;
  final VoidCallback onAdjustPressed;

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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onAdjustPressed,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Ubah Stok'),
          ),
        ],
      ),
    );
  }
}
