import 'package:flutter/material.dart';

import '../types/manager_models.dart';

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
  static const _primaryTeal = Color(0xFF145858);

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
        stock: _isEditMode ? widget.initial!.stock : int.parse(_stockController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        _isEditMode ? 'Edit Barang' : 'Tambah Barang',
        style: const TextStyle(color: _primaryTeal, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: 'SKU',
                  hintText: 'contoh: SKU-1005',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'SKU wajib diisi.'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Nama barang wajib diisi.'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Kategori wajib diisi.'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lokasi',
                  hintText: 'contoh: Aisle A-05',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                  decoration: InputDecoration(
                    labelText: 'Stok Awal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Stok awal harus berupa angka >= 0.';
                    }
                    return null;
                  },
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
