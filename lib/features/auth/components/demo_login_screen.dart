import 'package:flutter/material.dart';

import '../state/auth_state.dart';
import '../types/auth_user.dart';
import 'demo_quick_fill_bar.dart';
import 'login_brand_header.dart';

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
  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _warmAmber = Color(0xFFF7B318);
  static const _darkText = Color(0xFF102A2A);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

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
      _emailController.text = '${user.username}@gudang.demo';
      _passwordController.text = 'demo123';
    });
  }

  Future<void> _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final user = await widget.authState.loginWithCredentials(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (user != null) widget.onUserSelected?.call(user);
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primaryTeal),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _softMint, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryTeal, width: 1.8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _softMint, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14145858),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ListenableBuilder(
                  listenable: widget.authState,
                  builder: (context, _) => _buildCardContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    final error = widget.authState.errorMessage;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoginBrandHeader(),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email atau Username', 'staff@gudang.demo', Icons.email_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Email atau username wajib diisi.' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration('Password', 'Masukkan password', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: _primaryTeal),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi.' : null,
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _warmAmber),
              ),
              child: Text(error, style: const TextStyle(color: _darkText)),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _submitLogin,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Masuk', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 18),
          DemoQuickFillBar(
            users: widget.authState.users,
            isLoading: widget.authState.isLoading,
            onSelectUser: _fillDemoCredentials,
          ),
        ],
      ),
    );
  }
}
