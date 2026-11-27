import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../manager/item_management/types/manager_models.dart';
import 'flow_widgets.dart';

/// Formulir "Tambah barang" layar penuh sesuai mockup:
/// judul besar, field putih berlabel (SKU, Nama, Kategori, Lokasi,
/// Satuan, Batas stok minimum, Stok awal) dan tombol amber
/// "Simpan barang". Setelah simpan → layar sukses.
class ItemFormPage extends StatefulWidget {
  const ItemFormPage({super.key, this.initial});

  final ManagerItem? initial;

  static Future<ManagerItemInput?> show(
    BuildContext context, {
    ManagerItem? initial,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<ManagerItemInput>(
        builder: (_) => ItemFormPage(initial: initial),
      ),
    );
  }

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  static const _satuanPresets = ['pasang', 'lembar', 'unit', 'box'];

  final _formKey = GlobalKey<FormState>();
  late final _skuController =
      TextEditingController(text: widget.initial?.sku ?? '');
  late final _nameController =
      TextEditingController(text: widget.initial?.name ?? '');
  late final _categoryController =
      TextEditingController(text: widget.initial?.category ?? '');
  late final _locationController =
      TextEditingController(text: widget.initial?.location ?? '');
  late final _satuanController =
      TextEditingController(text: widget.initial?.satuan ?? 'pasang');
  late final _minStockController = TextEditingController(
    text: widget.initial != null ? '${widget.initial!.minStock}' : '10',
  );
  final _stockController = TextEditingController(text: '0');

  bool get _isEditMode => widget.initial != null;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _satuanController.dispose();
    _minStockController.dispose();
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
        satuan: _satuanController.text,
        minStock: int.parse(_minStockController.text.trim()),
        // Saat edit, stok tidak diedit — nilai awal dipertahankan.
        stock: _isEditMode
            ? widget.initial!.stock
            : int.parse(_stockController.text.trim()),
      ),
    );
  }

  InputDecoration get _fieldDecoration => const InputDecoration(
        hintText: '—',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Ubah Data Barang' : 'Tambah Barang'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  // Judul besar sesuai mockup
                  Text(
                    _isEditMode ? 'Ubah Data Barang' : 'Tambah barang',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isEditMode
                        ? 'Perbarui informasi barang. Stok diubah lewat alur Ubah Stok.'
                        : 'Lengkapi informasi barang baru yang akan masuk ke gudang.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FlowField(
                    label: 'SKU',
                    child: TextFormField(
                      controller: _skuController,
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'contoh: SKU-1005',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'SKU wajib diisi.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FlowField(
                    label: 'Nama Barang',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _fieldDecoration,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama barang wajib diisi.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FlowField(
                    label: 'Kategori',
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'contoh: Alas Kaki',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Kategori wajib diisi.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FlowField(
                    label: 'Lokasi',
                    child: TextFormField(
                      controller: _locationController,
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'contoh: Aisle A-05',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Lokasi wajib diisi.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FlowField(
                    label: 'Satuan',
                    child: TextFormField(
                      controller: _satuanController,
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'contoh: pasang',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Satuan wajib diisi.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _satuanPresets
                        .map(
                          (s) => FlowChip(
                            label: s,
                            selected: _satuanController.text == s,
                            onTap: () =>
                                setState(() => _satuanController.text = s),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  FlowField(
                    label: 'Batas stok minimum',
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'contoh: 10',
                      ),
                      validator: (v) {
                        final parsed = int.tryParse(v?.trim() ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Batas stok minimum harus angka >= 0.';
                        }
                        return null;
                      },
                    ),
                  ),
                  // Saat edit, stok disembunyikan: perubahan stok hanya
                  // boleh lewat alur "Ubah Stok" agar tercatat di riwayat.
                  if (!_isEditMode) ...[
                    const SizedBox(height: 16),
                    FlowField(
                      label: 'Stok Awal',
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration.copyWith(
                          hintText: 'contoh: 20',
                        ),
                        validator: (v) {
                          final parsed = int.tryParse(v?.trim() ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Stok awal harus berupa angka >= 0.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AmberButton(
                    label: _isEditMode ? 'Simpan perubahan' : 'Simpan barang',
                    onTap: _submit,
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: 'Batalkan',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
