import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../manager/item_management/types/manager_models.dart';

/// Dashboard per role sesuai mockup:
/// header pengguna (avatar + nama + role + tombol ganti akun),
/// kartu hero teal gelap "Beranda gudang" dengan tile statistik,
/// pencarian, dan daftar barang (stok besar + chip Tersedia/Menipis).

/// Header atas: avatar, nama, role, dan tombol ganti akun amber.
class DashboardUserHeader extends StatelessWidget {
  const DashboardUserHeader({
    super.key,
    required this.userName,
    required this.roleLabel,
    this.onSwitchAccount,
  });

  final String? userName;
  final String? roleLabel;
  final VoidCallback? onSwitchAccount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.softMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warehouse_outlined,
              color: AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'Petugas Gudang',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  roleLabel ?? 'staff',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onSwitchAccount != null)
            GestureDetector(
              onTap: onSwitchAccount,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.warmAmber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu hero teal gelap dengan judul, subjudul, dan 2 tile statistik.
class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stats,
    this.onStatTap,
  });

  final String title;
  final String subtitle;

  /// Maksimal 2 statistik: (icon, label, value, accent).
  final List<DashboardStat> stats;
  final void Function(int index)? onStatTap;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.white,
      const Color(0xFFF7B318),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B6B63),
            Color(0xFF145858),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: Judul + Subjudul di kiri, ilustrasi gudang di kanan atas.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                height: 90,
                child: Image.asset(
                  'assets/onboarding/warehouse_onboarding.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Baris bawah: 2 tile statistik mentok penuh (tanpa gambar di baris ini).
          Row(
            children: [
              for (var i = 0; i < stats.take(2).length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _HeroStatTile(
                    stat: stats[i],
                    valueColor: colors[i % colors.length],
                    onTap:
                        onStatTap == null ? null : () => onStatTap!(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardStat {
  const DashboardStat(this.label, this.value, {this.icon});
  final String label;
  final String value;
  final IconData? icon;
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({required this.stat, required this.valueColor, this.onTap});

  final DashboardStat stat;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stat.label,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Judul seksi daftar barang: "Daftar barang" + jumlah di kanan.
class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Text(
            'Daftar barang',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const Spacer(),
          Text(
            '$count barang',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Kartu barang gaya dashboard mockup: ikon kotak, nama, SKU · kategori,
/// stok besar "120 rim", chip status Tersedia/Menipis, chevron kanan.
class DashboardItemCard extends StatelessWidget {
  const DashboardItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ManagerItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.stock <= item.minStock;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.sku} · ${item.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${item.stock} ${item.satuan}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? AppColors.amberSoft
                                : AppColors.successBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isLowStock ? 'Menipis' : 'Tersedia',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isLowStock
                                  ? const Color(0xFF8A6100)
                                  : AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar bawah dashboard: pesan bantuan ("Pilih barang untuk ...").
class DashboardHintBar extends StatelessWidget {
  const DashboardHintBar({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
