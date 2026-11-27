import 'package:flutter/material.dart';

import '../../../common/warehouse_theme.dart';
import '../types/manager_models.dart';

/// Dialog tambah/edit barang gaya Figma: judul + subjudul, field
/// bergaris lembut, banner info hijau, tombol amber "Simpan barang".
class ItemFormDialog extends StatefulWidget {
  const ItemFormDialog({super.key, this.initial});

  /// Jika [initial] diisi, dialog berjalan dalam mode EDIT
  /// (field stok disembunyikan — stok hanya berubah via Ubah Stok).
  final ManagerItem? initial;

  static Future<ManagerItemInput?> show(
    BuildContext context, {
    ManagerItem? initial,
  }) {
    return showDialog<ManagerItemInput>(
      context: context,
      builder: (_) => ItemFormDialog(initial: initial),
    );
  }

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  static const _fieldBorder = BorderSide(color: WarehouseColors.softMint);

  final _formKey = GlobalKey<FormState>();
  late final _skuController =
      TextEditingController(text: widget.initial?.sku ?? '');
  late final _nameController =
      TextEditingController(text: widget.initial?.name ?? '');
  late final _categoryController =
      TextEditingController(text: widget.initial?.category ?? '');
  late final _locationController =
      TextEditingController(text: widget.initial?.location ?? '');
  final _stockController = TextEditingController(text: '0');

  bool get _isEditMode => widget.initial != null;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ManagerItemInput(
        sku: _skuController.text,
        name: _nameController.text,
        category: _categoryController.text,
        location: _locationController.text,
        // Saat edit, stok tidak diedit — nilai awal dipertahankan.
        stock: _isEditMode
            ? widget.initial!.stock
            : int.parse(_stockController.text.trim()),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
        borderSide: _fieldBorder,
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
      title: Text(
        _isEditMode ? 'Edit barang' : 'Tambah barang',
        style: const TextStyle(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _skuController,
                decoration: _decoration('SKU', hint: 'contoh: SKU-1005'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'SKU wajib diisi.'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: _decoration('Nama barang'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Nama barang wajib diisi.'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: _decoration('Kategori'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Kategori wajib diisi.'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: _decoration('Lokasi', hint: 'contoh: Aisle A-05'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Lokasi wajib diisi.'
                        : null,
              ),
              const SizedBox(height: 12),
              // Saat edit, stok disembunyikan: perubahan stok hanya
              // boleh lewat tombol "Ubah Stok" agar tercatat di riwayat.
              if (!_isEditMode)
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Stok awal'),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Stok awal harus berupa angka >= 0.';
                    }
                    return null;
                  },
                ),
              if (!_isEditMode) const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WarehouseColors.paleMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: WarehouseColors.primaryTeal,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perubahan stok berikutnya dicatat otomatis lewat menu Ubah Stok.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: WarehouseColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
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
            minimumSize: const Size(120, 44),
          ),
          onPressed: _submit,
          child: const Text(
            'Simpan barang',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
