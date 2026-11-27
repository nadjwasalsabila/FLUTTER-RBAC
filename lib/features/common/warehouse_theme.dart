import 'package:flutter/material.dart';

/// Token warna & komponen bersama yang mengikuti desain Figma
/// "Stok Gudang": teal gelap, mint lembut, aksen amber.
class WarehouseColors {
  WarehouseColors._();

  static const primaryTeal = Color(0xFF145858);
  static const softMint = Color(0xFFC8E0CA);
  static const paleMint = Color(0xFFDCEBDD);
  static const background = Color(0xFFF0F6F0);
  static const warmAmber = Color(0xFFF7B41B);
  static const darkText = Color(0xFF102A2A);
  static const subtitleText = Color(0xFF5B7470);

  static const successGreen = Color(0xFF1B7A46);
  static const successBg = Color(0xFFE5F3E6);
  static const warningText = Color(0xFF9A6A00);
  static const warningBg = Color(0xFFFFF3D6);
  static const dangerRed = Color(0xFFC0392B);
  static const dangerBg = Color(0xFFFDE2E2);
}

/// App bar teal gelap: chip ikon gudang + judul kecil + tombol akun amber.
class WarehouseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WarehouseAppBar({
    super.key,
    this.title = 'Stok Gudang',
    this.subtitle,
    this.onSwitchAccount,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSwitchAccount;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: WarehouseColors.primaryTeal,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.warehouse_outlined,
            color: WarehouseColors.primaryTeal,
            size: 20,
          ),
        ),
      ),
      leadingWidth: 52,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (onSwitchAccount != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: 'Ganti akun',
              child: InkWell(
                onTap: onSwitchAccount,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: WarehouseColors.warmAmber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Judul halaman + subjudul di atas konten.
class WarehousePageHeader extends StatelessWidget {
  const WarehousePageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: WarehouseColors.darkText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: WarehouseColors.subtitleText,
          ),
        ),
      ],
    );
  }
}

/// Satu statistik ringkas pada kartu ringkasan.
class WarehouseStat {
  const WarehouseStat({required this.value, required this.label});

  final String value;
  final String label;
}

/// Kartu ringkasan teal gelap dengan daftar statistik + ilustrasi ikon.
class WarehouseSummaryCard extends StatelessWidget {
  const WarehouseSummaryCard({
    super.key,
    required this.stats,
    this.icon = Icons.warehouse_outlined,
  });

  final List<WarehouseStat> stats;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WarehouseColors.primaryTeal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                for (final stat in stats)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

/// Kolom pencarian putih membulat.
class WarehouseSearchField extends StatelessWidget {
  const WarehouseSearchField({
    super.key,
    this.hintText = 'Cari nama, SKU, atau kategori…',
    this.onChanged,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: WarehouseColors.subtitleText,
          fontSize: 13.5,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: WarehouseColors.primaryTeal,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WarehouseColors.softMint),
        ),
      ),
    );
  }
}

/// Header seksi daftar: judul kiri + keterangan kanan.
class WarehouseSectionHeader extends StatelessWidget {
  const WarehouseSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: WarehouseColors.darkText,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: WarehouseColors.subtitleText,
            ),
          ),
      ],
    );
  }
}

/// Tombol aksi utama amber membulat, selebar parent.
class WarehousePrimaryButton extends StatelessWidget {
  const WarehousePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 20, color: Colors.white)
            : null,
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              onPressed == null ? Colors.grey.shade400 : WarehouseColors.warmAmber,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.white60,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// Chip chip ikon kotak barang (avatar kartu item).
class WarehouseItemChip extends StatelessWidget {
  const WarehouseItemChip({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: WarehouseColors.softMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: WarehouseColors.primaryTeal,
        size: size * 0.5,
      ),
    );
  }
}

/// Status ketersediaan stok berdasarkan jumlah.
enum WarehouseStockLevel { aman, menipis, habis }

WarehouseStockLevel warehouseStockLevelOf(int stock) {
  if (stock <= 0) return WarehouseStockLevel.habis;
  if (stock <= 10) return WarehouseStockLevel.menipis;
  return WarehouseStockLevel.aman;
}

/// Pil badge status stok: Aman / Menipis / Habis.
class WarehouseStockBadge extends StatelessWidget {
  const WarehouseStockBadge({super.key, required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final level = warehouseStockLevelOf(stock);
    final (label, textColor, bgColor) = switch (level) {
      WarehouseStockLevel.aman => ('Aman', WarehouseColors.successGreen, WarehouseColors.successBg),
      WarehouseStockLevel.menipis => ('Menipis', WarehouseColors.warningText, WarehouseColors.warningBg),
      WarehouseStockLevel.habis => ('Habis', WarehouseColors.dangerRed, WarehouseColors.dangerBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
