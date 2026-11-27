import 'package:flutter/material.dart';

import '../../../common/warehouse_theme.dart';
import '../types/stock_models.dart';
import 'stock_dialog_parts.dart';

class StockAdjustmentInput {
  const StockAdjustmentInput({
    required this.type,
    required this.amount,
    required this.reason,
  });

  final StockAdjustmentType type;
  final int amount;
  final String reason;
}

/// Dialog ubah stok gaya Figma: banner barang, chip jenis perubahan,
/// field bergaris lembut, tombol amber "Simpan perubahan".
class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({super.key, required this.item});

  final WarehouseItem item;

  static Future<StockAdjustmentInput?> show(
    BuildContext context, {
    required WarehouseItem item,
  }) {
    return showDialog<StockAdjustmentInput>(
      context: context,
      builder: (_) => StockAdjustmentDialog(item: item),
    );
  }

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  static const _presetReasons = [
    'Barang masuk',
    'Barang keluar',
    'Koreksi stok',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '1');
  final _reasonController = TextEditingController(text: 'Barang masuk');
  StockAdjustmentType _type = StockAdjustmentType.increase;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _selectType(StockAdjustmentType type) {
    setState(() {
      _type = type;
      if (_reasonController.text == 'Barang masuk' ||
          _reasonController.text == 'Barang keluar') {
        _reasonController.text = type == StockAdjustmentType.increase
            ? 'Barang masuk'
            : 'Barang keluar';
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      StockAdjustmentInput(
        type: _type,
        amount: int.parse(_amountController.text.trim()),
        reason: _reasonController.text.trim(),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: WarehouseColors.subtitleText,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      filled: true,
      fillColor: WarehouseColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WarehouseColors.softMint),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WarehouseColors.primaryTeal),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WarehouseColors.dangerRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WarehouseColors.dangerRed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Ubah Stok Barang',
        style: TextStyle(
          color: WarehouseColors.darkText,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StockDialogItemBanner(item: widget.item),
              const SizedBox(height: 12),
              StockAdjustmentTypeChips(
                selectedType: _type,
                onSelected: _selectType,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Jumlah perubahan'),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Jumlah perubahan harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _presetReasons
                    .map(
                      (reason) => ActionChip(
                        backgroundColor: WarehouseColors.paleMint,
                        side: BorderSide.none,
                        label: Text(
                          reason,
                          style: const TextStyle(
                            color: WarehouseColors.primaryTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () =>
                            setState(() => _reasonController.text = reason),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: _decoration('Alasan perubahan'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Alasan perubahan wajib diisi.'
                        : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: WarehouseColors.primaryTeal,
            side: const BorderSide(color: WarehouseColors.softMint),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(96, 44),
          ),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: WarehouseColors.warmAmber,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(140, 44),
          ),
          onPressed: _submit,
          child: const Text(
            'Simpan perubahan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
