import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/rbac/rbac_service.dart';
import '../manager/manager_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await RbacService.instance.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _selectUser(UserModel user) async {
    await RbacService.instance.setCurrentUser(user);
    if (!mounted) return;

    if (user.roleName == 'Manager') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ManagerPage(currentUser: user),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun ${user.roleName} belum tersedia di versi ini. Pilih akun Manager.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Akun Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih akun untuk masuk:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Setiap akun memiliki role dan permission yang berbeda.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, p) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _UserTile(
                          user: user,
                          onTap: () => _selectUser(user),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Manager':
        return Icons.manage_accounts;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Manager':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.roleName);
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(31),
          child: Icon(_roleIcon(user.roleName), color: color),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Role: ${user.roleName}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
