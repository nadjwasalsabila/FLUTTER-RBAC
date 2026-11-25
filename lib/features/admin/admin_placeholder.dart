import 'package:flutter/material.dart';

/// Placeholder halaman admin. Fitur admin (kelola kebijakan izin role)
/// belum dibuat, sehingga admin yang login diarahkan ke halaman ini.
class AdminPlaceholder extends StatelessWidget {
  const AdminPlaceholder({super.key, this.onSwitchAccount});

  final VoidCallback? onSwitchAccount;

  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _darkText = Color(0xFF102A2A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
        title: const Text('Gudang RBAC — Admin'),
        actions: [
          if (onSwitchAccount != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: onSwitchAccount,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Ganti Akun'),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _softMint,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 56,
                  color: _primaryTeal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Halaman Admin Belum Tersedia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fitur admin (kelola kebijakan izin role) '
                'sedang dalam pengembangan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
