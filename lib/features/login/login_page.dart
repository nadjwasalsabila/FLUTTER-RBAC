import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../auth/types/auth_user.dart';
import '../manager/manager_page.dart';
import '../../core/rbac/rbac_evaluator.dart';
import '../../core/rbac/rbac_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<AuthUser> _users = [];
  bool _isLoading = true;

  late final Database _db;
  late final RbacEvaluator _rbacEvaluator;
  late final RbacService _rbacService;

  Future<void> _initDb() async {
    final dbPath = p.join(await getDatabasesPath(), 'warehouse_rbac.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  @override
  void initState() {
    super.initState();
    _initDb();
    _rbacEvaluator = RbacEvaluator(_db);
    _rbacService = RbacService(_db);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _rbacService.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectUser(AuthUser user) async {
    await _rbacService.setCurrentUser(user);
    if (!mounted) return;

    if (user.roleId == 'manager') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ManagerPage(
            db: _db,
            currentUser: user,
          ),
        ),
      );
    } else if (user.roleId == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminPolicyPage(
            db: _db,
            fullName: user.fullName,
            roleId: user.roleId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun ${user.roleId} belum tersedia di versi ini.',
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
  final AuthUser user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.roleId);
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(31),
          child: Icon(_roleIcon(user.roleId), color: color),
        ),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Role: ${user.roleId}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
