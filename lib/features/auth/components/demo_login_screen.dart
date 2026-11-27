import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/flow_widgets.dart';
import '../state/auth_state.dart';
import '../types/auth_user.dart';
import 'register_screen.dart';

/// Layar login sesuai mockup: hero ilustrasi gudang di atas,
/// tab pill "Masuk / Buat akun", field putih label di atas,
/// tombol amber pill, dan chip akun demo di bawah.
class DemoLoginScreen extends StatefulWidget {
  const DemoLoginScreen({
    super.key,
    required this.authState,
    this.onUserSelected,
  });

  final AuthState authState;
  final ValueChanged<AuthUser>? onUserSelected;

  @override
  State<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends State<DemoLoginScreen> {
  final _loginKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    if (widget.authState.users.isEmpty && !widget.authState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.authState.loadUsers();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials(AuthUser user) {
    setState(() {
      _emailController.text = user.username;
      _passwordController.text = AuthState.demoPassword;
      _inlineError = null;
    });
  }

  Future<void> _submitLogin() async {
    if (!(_loginKey.currentState?.validate() ?? false) || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });
    final user = await widget.authState.loginWithCredentials(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (user != null) {
      widget.onUserSelected?.call(user);
    } else {
      setState(() => _inlineError = 'Email atau password salah.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.authState,
                builder: (context, _) => _buildCardContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    final error = _inlineError ?? widget.authState.errorMessage;
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LoginHero(),
          const SizedBox(height: 20),
          _buildErrorBanner(error),
          FlowField(
            label: 'Username atau Email',
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'staff'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Username wajib diisi.'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          FlowField(
            label: 'Password',
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onFieldSubmitted: (_) => _submitLogin(),
              decoration: InputDecoration(
                hintText: 'demo123',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password wajib diisi.' : null,
            ),
          ),
          const SizedBox(height: 20),
          AmberButton(
            label: 'Masuk',
            enabled: !_isSubmitting,
            onTap: _submitLogin,
          ),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 22),
          _buildDemoAccounts(),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.errorRed, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.errorRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
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
    );
  }

  Widget _buildDemoAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Masuk cepat sebagai',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.authState.isLoading)
          const LinearProgressIndicator(color: AppColors.primaryTeal)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: widget.authState.users.map((user) {
              final isSelected =
                  _emailController.text.trim().toLowerCase() ==
                  user.username.toLowerCase();
              return ActionChip(
                avatar: Icon(
                  isSelected ? Icons.check_circle : Icons.person_outline,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.primaryTeal,
                ),
                backgroundColor:
                    isSelected ? AppColors.primaryTeal : AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primaryTeal : AppColors.border,
                ),
                label: Text(
                  '${user.fullName} · ${user.roleId}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                onPressed: () => _fillDemoCredentials(user),
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// Hero atas layar login sesuai mockup: ilustrasi gudang besar,
/// judul, dan subtitle.
class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Image.asset(
            'assets/onboarding/warehouse_onboarding.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Gudang RBAC',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Masuk untuk mengelola stok gudang',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        // Baris pemisah antara login dan buat akun.
        Builder(
          builder: (context) {
            return Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Masuk',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NavToRegister(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Tombol "Buat akun" — hanya teks, buka layar registrasi.
class _NavToRegister extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RegisterScreen(authState: _authStateOf(context)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Buat akun',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  AuthState _authStateOf(BuildContext context) {
    // Ambil AuthState dari ancestor paling dekat yang memilikinya.
    final state = context.findAncestorStateOfType<_DemoLoginScreenState>();
    return state!.widget.authState;
  }
}
