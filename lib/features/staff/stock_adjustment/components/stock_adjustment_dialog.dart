import 'package:flutter/material.dart';

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
  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _darkText = Color(0xFF102A2A);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Ubah Stok Barang',
        style: TextStyle(color: _primaryTeal, fontWeight: FontWeight.w700),
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
                decoration: InputDecoration(
                  labelText: 'Jumlah perubahan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                        backgroundColor: _softMint,
                        side: BorderSide.none,
                        label: Text(reason, style: const TextStyle(color: _darkText, fontSize: 12)),
                        onPressed: () => setState(() => _reasonController.text = reason),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Alasan perubahan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Alasan perubahan wajib diisi.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: _primaryTeal)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
