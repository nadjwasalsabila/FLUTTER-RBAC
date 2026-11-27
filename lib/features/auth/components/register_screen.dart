import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../shared/flow/flow_widgets.dart';
import '../state/auth_state.dart';
import '../types/auth_user.dart';

/// Layar "Buat akun" sesuai mockup: judul besar, field Nama lengkap /
/// Username / Password / Role (chips), tombol amber "Simpan akun".
///
/// - Mode publik (dari login): role DIPAKSA "staff" — akun manager hanya
///   bisa dibuat oleh admin, dan admin tidak bisa dibuat lewat sini.
/// - Mode admin (dari beranda admin): pilih role manager/staff, akun
///   dibuat TANPA berpindah login.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.authState,
    this.adminMode = false,
    this.onAccountCreated,
  });

  final AuthState authState;

  /// true = dibuka dari beranda admin (boleh buat manager/staff,
  /// tidak auto-login).
  final bool adminMode;

  /// Dipanggil setelah akun berhasil dibuat (mode admin).
  final VoidCallback? onAccountCreated;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'staff';
  bool _isSubmitting = false;
  String? _error;

  List<String> get _allowedRoles => widget.adminMode
      ? AuthState.adminCreatableRoles
      : AuthState.publicRoles;

  @override
  void initState() {
    super.initState();
    _selectedRole = _allowedRoles.first;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    // Mode admin: buat akun tanpa berpindah login.
    if (widget.adminMode) {
      final error = await widget.authState.createAccountWithoutLogin(
        fullName: _fullNameController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        roleId: _selectedRole,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      widget.onAccountCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    final error = await widget.authState.registerAndLogin(
      fullName: _fullNameController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      roleId: _selectedRole,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    // Tampilkan layar sukses lalu kembali ke root (home sudah berganti
    // ke dashboard role akun baru).
    final user = widget.authState.activeUser!;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterSuccessScreen(user: user),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(title: const Text('Buat akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Buat akun',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Isi data untuk membuat akun baru.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius:
                              BorderRadius.circular(AppRadius.chip),
                          border:
                              Border.all(color: AppColors.errorRed, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.errorRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    FlowField(
                      label: 'Nama lengkap',
                      child: TextFormField(
                        controller: _fullNameController,
                        decoration:
                            const InputDecoration(hintText: 'Dimas Pratama'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama wajib diisi.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FlowField(
                      label: 'Username',
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'dimas',
                          prefixText: '@ ',
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Username wajib diisi.';
                          if (t.contains(' ')) {
                            return 'Username tidak boleh ada spasi.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    FlowField(
                      label: 'Password',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Minimal 6 karakter',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.primaryTeal,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password minimal 6 karakter.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FlowField(
                      label: 'Role akun',
                      child: _allowedRoles.length == 1
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.field),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: AppColors.primaryTeal,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Petugas Gudang (staff)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allowedRoles.map((role) {
                                return FlowChip(
                                  label: role == 'manager'
                                      ? 'Manager Gudang (manager)'
                                      : 'Petugas Gudang (staff)',
                                  selected: _selectedRole == role,
                                  onTap: () =>
                                      setState(() => _selectedRole = role),
                                );
                              }).toList(),
                            ),
                    ),
                    if (!widget.adminMode) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Akun Manager hanya dapat dibuat oleh Admin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    AmberButton(
                      label: 'Simpan akun',
                      enabled: !_isSubmitting,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 12),
                    GhostButton(
                      label: 'Kembali ke login',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                    if (_isSubmitting)
                      const Center(
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Layar sukses pembuatan akun sesuai mockup: lingkaran centang,
/// judul besar, kartu username besar, kartu role, tombol amber.
class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.paleMint,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Akun berhasil dibuat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat datang, ${user.fullName}! Akun baru sudah siap dipakai.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _successCard(
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    value: '@${user.username}',
                  ),
                  const SizedBox(height: 10),
                  _successCard(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: user.roleId,
                  ),
                  const SizedBox(height: 30),
                  AmberButton(
                    label: 'Mulai sekarang',
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

  Widget _successCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
