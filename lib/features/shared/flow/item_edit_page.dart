import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../manager/item_management/types/manager_models.dart';
import '../../staff/stock_adjustment/types/stock_models.dart';
import 'flow_widgets.dart';

/// SATU layar gabungan untuk mengubah barang: data (SKU, nama, kategori,
/// lokasi, satuan, batas stok minimum) DAN stok (masuk/keluar, jumlah,
/// alasan) dalam satu alur: Form → Konfirmasi → Layar sukses.
///
/// - Role dengan izin edit data: semua field aktif.
/// - Role hanya boleh ubah stok (mis. staff): hanya bagian stok.
class ItemEditPage extends StatefulWidget {
  const ItemEditPage({
    super.key,
    required this.item,
    required this.canEditData,
    required this.canAdjustStock,
    required this.saveData,
    required this.adjustStock,
  });

  final ManagerItem item;
  final bool canEditData;
  final bool canAdjustStock;

  /// Simpan perubahan DATA barang (SKU, nama, dst).
  final Future<ManagerItemResult> Function(ManagerItemInput input) saveData;

  /// Simpan perubahan STOK (tercatat di riwayat pergerakan).
  final Future<StockAdjustmentResult> Function(
    StockAdjustmentInput input,
  ) adjustStock;

  static Future<void> push(
    BuildContext context, {
    required ManagerItem item,
    required bool canEditData,
    required bool canAdjustStock,
    required Future<ManagerItemResult> Function(ManagerItemInput input)
        saveData,
    required Future<StockAdjustmentResult> Function(
      StockAdjustmentInput input,
    ) adjustStock,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemEditPage(
          item: item,
          canEditData: canEditData,
          canAdjustStock: canAdjustStock,
          saveData: saveData,
          adjustStock: adjustStock,
        ),
      ),
    );
  }

  @override
  State<ItemEditPage> createState() => _ItemEditPageState();
}

/// Nilai perubahan stok yang sudah tervalidasi.
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

class _ItemEditPageState extends State<ItemEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller data barang
  late final _skuController =
      TextEditingController(text: widget.item.sku);
  late final _nameController =
      TextEditingController(text: widget.item.name);
  late final _categoryController =
      TextEditingController(text: widget.item.category);
  late final _locationController =
      TextEditingController(text: widget.item.location);
  late final _satuanController =
      TextEditingController(text: widget.item.satuan);
  late final _minStockController =
      TextEditingController(text: '${widget.item.minStock}');

  // Controller stok — berisi JUMLAH STOK yang diinginkan (angka final).
  // Tombol +/- menambah/mengurangi dari stok yang sudah ada; jenis
  // perubahan (masuk/keluar) otomatis dari selisihnya.
  late final _amountController =
      TextEditingController(text: '${widget.item.stock}');
  final _reasonController = TextEditingController(text: 'Barang masuk');

  /// Apakah perubahan stok disertakan dalam penyimpanan ini.
  /// Untuk role tanpa izin edit data (mis. staff), stok selalu disertakan.
  bool get _stockIncluded => _stockIncludedFlag || !widget.canEditData;
  bool _stockIncludedFlag = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _satuanController.dispose();
    _minStockController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ----- Deteksi perubahan -----

  ManagerItemInput get _currentInput => ManagerItemInput(
        sku: _skuController.text,
        name: _nameController.text,
        category: _categoryController.text,
        location: _locationController.text,
        satuan: _satuanController.text,
        minStock: int.tryParse(_minStockController.text.trim()) ?? 0,
        stock: widget.item.stock,
      );

  bool get _dataChanged {
    final i = widget.item;
    return _skuController.text.trim() != i.sku ||
        _nameController.text.trim() != i.name ||
        _categoryController.text.trim() != i.category ||
        _locationController.text.trim() != i.location ||
        _satuanController.text.trim() != i.satuan ||
        (int.tryParse(_minStockController.text.trim()) ?? -1) != i.minStock;
  }

  /// Jumlah stok baru yang diinginkan (dari field / tombol +/-).
  int get _newStock => int.tryParse(_amountController.text.trim()) ?? 0;

  /// Selisih terhadap stok saat ini: positif = masuk, negatif = keluar.
  int get _stockDelta => _newStock - widget.item.stock;

  int get _nextStock => _newStock;

  bool get _hasAnyChange =>
      (widget.canEditData && _dataChanged) ||
      (widget.canAdjustStock && _stockIncluded);

  // ----- Aksi -----

  /// Tombol +/- di samping field jumlah: tambah/kurangi dari jumlah
  /// stok yang sudah ada, satu-satu.
  void _stepAmount(int step) {
    final current = int.tryParse(_amountController.text.trim()) ?? 0;
    final next = (current + step).clamp(0, 1000000);
    _amountController.text = '$next';
    _syncDefaultReason(next - widget.item.stock);
    setState(() {});
  }

  /// Ikuti perubahan default alasan mengikuti arah selisih stok
  /// (hanya bila user belum mengubah alasan secara manual).
  void _syncDefaultReason(int delta) {
    final t = _reasonController.text.trim();
    if (t == 'Barang masuk' || t == 'Barang keluar') {
      _reasonController.text = delta < 0 ? 'Barang keluar' : 'Barang masuk';
    }
  }

  Future<void> _openConfirmation() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_hasAnyChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada perubahan untuk disimpan.'),
          backgroundColor: AppColors.darkText,
        ),
      );
      return;
    }
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EditConfirmPage(
          item: widget.item,
          newData: _currentInput,
          dataChanged: widget.canEditData && _dataChanged,
          stockIncluded: widget.canAdjustStock && _stockIncluded,
          stockDelta: _stockDelta,
          nextStock: _nextStock,
          reason: _reasonController.text.trim(),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _save();
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);

    final bool wantData = widget.canEditData && _dataChanged;
    final bool wantStock = widget.canAdjustStock && _stockIncluded;

    if (wantData) {
      final result = await widget.saveData(_currentInput);
      if (!result.success) {
        _failSave(result.message);
        return;
      }
    }
    if (wantStock) {
      final result = await widget.adjustStock(
        StockAdjustmentInput(
          // Jenis perubahan otomatis dari selisih stok baru vs saat ini:
          // bertambah = masuk, berkurang = keluar.
          type: _stockDelta >= 0
              ? StockAdjustmentType.increase
              : StockAdjustmentType.decrease,
          amount: _stockDelta.abs(),
          reason: _reasonController.text.trim(),
        ),
      );
      if (!result.success) {
        _failSave(result.message);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Buang form + konfirmasi, lalu tampilkan layar sukses
    // (hijau, ikon centang besar, angka stok besar — sesuai mockup).
    Navigator.of(context)
      ..pop()
      ..pop();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlowSuccessScreen(
          title: wantData ? 'Perubahan tersimpan' : 'Stok berhasil diubah',
          message: wantData
              ? 'Data ${_nameController.text.trim()} berhasil diperbarui.'
              : 'Stok ${widget.item.name} berhasil diperbarui.',
          bigValue: wantStock
              ? '$_nextStock'
              : null,
          bigValueLabel: wantStock ? widget.item.satuan : null,
          buttonLabel: 'Kembali ke daftar',
        ),
      ),
    );
  }

  void _failSave(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
    );
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(title: const Text('Ubah Barang')),
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
                    'Ubah barang',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.name} · stok saat ini ${item.stock} ${item.satuan}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (widget.canEditData) ...[
                    FlowField(
                      label: 'SKU',
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(),
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
                        decoration: const InputDecoration(),
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
                        decoration: const InputDecoration(),
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
                        decoration: const InputDecoration(),
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
                        decoration: const InputDecoration(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Satuan wajib diisi.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FlowField(
                      label: 'Batas stok minimum',
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(),
                        validator: (v) {
                          final parsed = int.tryParse(v?.trim() ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Batas stok minimum harus angka >= 0.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (widget.canAdjustStock) ...[
                    if (widget.canEditData)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primaryTeal,
                        title: const Text(
                          'Ubah stok juga',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                        subtitle: const Text(
                          'Aktifkan bila stok juga perlu diubah (tercatat di riwayat).',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        value: _stockIncludedFlag,
                        onChanged: (v) =>
                            setState(() => _stockIncludedFlag = v),
                      ),
                    if (_stockIncluded || !widget.canEditData) ...[
                      if (widget.canEditData) const SizedBox(height: 8),
                      FlowField(
                        label: 'Jumlah stok',
                        child: Row(
                          children: [
                            _StepButton(
                              icon: Icons.remove_rounded,
                              onTap: () => _stepAmount(-1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType
                                    .numberWithOptions(signed: true),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  helperText:
                                      'Stok masuk (+) atau keluar (−) dari jumlah ini',
                                ),
                                onChanged: (v) =>
                                    _syncDefaultReason(_stockDelta),
                                validator: (v) {
                                  final parsed = int.tryParse(v?.trim() ?? '');
                                  if (parsed == null || parsed < 0) {
                                    return 'Jumlah stok harus angka >= 0.';
                                  }
                                  if (parsed == widget.item.stock) {
                                    return 'Jumlah stok masih sama dengan sekarang.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            _StepButton(
                              icon: Icons.add_rounded,
                              onTap: () => _stepAmount(1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FlowField(
                        label: 'Alasan perubahan',
                        child: TextFormField(
                          controller: _reasonController,
                          decoration: const InputDecoration(),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Alasan perubahan wajib diisi.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _nextStock < 0
                              ? AppColors.errorBg
                              : AppColors.successBg,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _nextStock < 0
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              size: 20,
                              color: _nextStock < 0
                                  ? AppColors.errorRed
                                  : AppColors.primaryTeal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _nextStock < 0
                                    ? 'Stok akhir tidak boleh negatif.'
                                    : 'Stok akhir: $_nextStock ${item.satuan}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  AmberButton(
                    label: 'Simpan perubahan',
                    enabled: !(_isSubmitting ||
                        (!_stockIncluded && !widget.canEditData) ||
                        (_stockIncluded && _nextStock < 0)),
                    onTap: _openConfirmation,
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

/// Tombol bulat +/- di samping field jumlah perubahan.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryTeal,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

/// Layar "Konfirmasi" — tinjauan SEMUA perubahan (data + stok).
class _EditConfirmPage extends StatelessWidget {
  const _EditConfirmPage({
    required this.item,
    required this.newData,
    required this.dataChanged,
    required this.stockIncluded,
    required this.stockDelta,
    required this.nextStock,
    required this.reason,
  });

  final ManagerItem item;
  final ManagerItemInput newData;
  final bool dataChanged;
  final bool stockIncluded;
  final int stockDelta;
  final int nextStock;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(title: const Text('Konfirmasi')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Text(
                  'Konfirmasi',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Periksa perubahan sebelum disimpan.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 22),
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        newData.name.trim().isEmpty
                            ? item.name
                            : newData.name.trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        item.sku,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (dataChanged) ...[
                        _changeRow('SKU', item.sku, newData.sku.trim()),
                        _changeRow('Nama', item.name, newData.name.trim()),
                        _changeRow(
                            'Kategori', item.category, newData.category.trim()),
                        _changeRow(
                            'Lokasi', item.location, newData.location.trim()),
                        _changeRow('Satuan', item.satuan, newData.satuan.trim()),
                        _changeRow('Batas stok minimum',
                            '${item.minStock}', '${newData.minStock}'),
                        const SizedBox(height: 12),
                      ],
                      if (stockIncluded)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Stok saat ini',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${item.stock} ${item.satuan}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                stockDelta >= 0
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_back_rounded,
                                color: stockDelta >= 0
                                    ? AppColors.primaryTeal
                                    : AppColors.errorRed,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Stok setelahnya',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '$nextStock ${item.satuan}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (stockIncluded)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _detailRow('Alasan', reason),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AmberButton(
                  label: 'Ya, simpan perubahan',
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 12),
                GhostButton(
                  label: 'Batalkan',
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Baris perubahan data: lama → baru (disembunyikan bila sama).
  Widget _changeRow(String label, String oldV, String newV) {
    if (oldV == newV) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              '$oldV  →  $newV',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ),
      ],
    );
  }
}
