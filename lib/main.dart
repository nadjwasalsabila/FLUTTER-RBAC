import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rbac/features/admin/admin_home_page.dart';
import 'package:rbac/features/auth/auth.dart';
import 'package:rbac/features/manager/manager_dashboard.dart';
import 'package:rbac/features/staff/stock_adjustment/stock_adjustment.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const WarehouseStaffApp());
}

class WarehouseStaffApp extends StatefulWidget {
  const WarehouseStaffApp({super.key, this.database});

  final Database? database;

  @override
  State<WarehouseStaffApp> createState() => _WarehouseStaffAppState();
}

class _WarehouseStaffAppState extends State<WarehouseStaffApp> {
  late final Future<_AppDeps> _depsFuture = _initAppDeps();

  Future<_AppDeps> _initAppDeps() async {
    final db = widget.database ?? await _openAppDatabase();
    final authState = AuthState(LoginService(db));
    await authState.loadUsers();
    return _AppDeps(db: db, authState: authState);
  }

  Future<Database> _openAppDatabase() async {
    final dbPath = kIsWeb
        ? 'warehouse_rbac.db'
        : p.join(await getDatabasesPath(), 'warehouse_rbac.db');
    return openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) => _createAndSeedSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final columns = await db.rawQuery(
            'PRAGMA table_info(role_permissions)',
          );
          final hasIsActive = columns.any((c) => c['name'] == 'is_active');
          if (!hasIsActive) {
            await db.execute(
              'ALTER TABLE role_permissions ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
            );
          }
        }
      },
    );
  }

  Future<void> _createAndSeedSchema(Database db) async {
    const tables = [
      'CREATE TABLE roles (id TEXT PRIMARY KEY, display_name TEXT NOT NULL, description TEXT NOT NULL)',
      'CREATE TABLE permissions (key TEXT PRIMARY KEY, description TEXT NOT NULL)',
      'CREATE TABLE role_permissions (role_id TEXT NOT NULL, permission_key TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, PRIMARY KEY (role_id, permission_key), FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE, FOREIGN KEY (permission_key) REFERENCES permissions(key) ON DELETE CASCADE)',
      'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, role_id TEXT NOT NULL, full_name TEXT NOT NULL, username TEXT NOT NULL UNIQUE, is_active INTEGER NOT NULL, FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT)',
      'CREATE TABLE warehouse_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT NOT NULL UNIQUE, name TEXT NOT NULL, category TEXT NOT NULL, location TEXT NOT NULL, stock INTEGER NOT NULL CHECK (stock >= 0), updated_at TEXT NOT NULL)',
      'CREATE TABLE stock_movements (id INTEGER PRIMARY KEY AUTOINCREMENT, item_id INTEGER NOT NULL, user_id INTEGER NOT NULL, delta INTEGER NOT NULL, reason TEXT NOT NULL, created_at TEXT NOT NULL, FOREIGN KEY (item_id) REFERENCES warehouse_items(id) ON DELETE RESTRICT, FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT)',
    ];
    for (final sql in tables) {
      await db.execute(sql);
    }
    for (final role in const [
      ('staff', 'Petugas Gudang', 'Melihat barang dan mengubah stok'),
      ('manager', 'Kepala Gudang', 'Kelola master barang dan stok'),
      ('admin', 'Admin Sistem', 'Kelola kebijakan izin role'),
    ]) {
      await db.insert('roles', {
        'id': role.$1,
        'display_name': role.$2,
        'description': role.$3,
      });
    }
    for (final key in const [
      'item:read',
      'stock:adjust',
      'item:create',
      'item:delete',
      'policy:edit',
    ]) {
      await db.insert('permissions', {'key': key, 'description': key});
    }
    const matrix = {
      'staff': ['item:read', 'stock:adjust'],
      'manager': ['item:read', 'stock:adjust', 'item:create', 'item:delete'],
      'admin': [
        'item:read',
        'stock:adjust',
        'item:create',
        'item:delete',
        'policy:edit',
      ],
    };
    for (final entry in matrix.entries) {
      for (final perm in entry.value) {
        await db.insert('role_permissions', {
          'role_id': entry.key,
          'permission_key': perm,
        });
      }
    }
    await const UserSeeder().seed(db);
    for (final item in const [
      ('SKU-1001', 'Sepatu Safety Steel Toe', 'Alas Kaki', 'Aisle A-01', 12),
      ('SKU-1002', 'Sepatu Lari Mesh Biru', 'Alas Kaki', 'Aisle A-02', 20),
      ('SKU-1003', 'Sol Karet Anti-Slip', 'Komponen', 'Aisle B-01', 45),
      ('SKU-1004', 'Kardus Kemasan Ukuran M', 'Pengemasan', 'Aisle C-03', 30),
    ]) {
      await db.insert('warehouse_items', {
        'sku': item.$1,
        'name': item.$2,
        'category': item.$3,
        'location': item.$4,
        'stock': item.$5,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gudang RBAC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145858),
          primary: const Color(0xFF145858),
          secondaryContainer: const Color(0xFFC8E0CA),
          tertiary: const Color(0xFFF7B318),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8F6),
      ),
      home: FutureBuilder<_AppDeps>(
        future: _depsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Gagal memuat DB: ${snapshot.error}')),
            );
          }
          final deps = snapshot.data;
          if (deps == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ListenableBuilder(
            listenable: deps.authState,
            builder: (context, _) {
              final user = deps.authState.activeUser;
              if (user == null) {
                return DemoLoginScreen(authState: deps.authState);
              }
              if (user.roleId == 'admin') {
                return AdminHomePage(
                  db: deps.db,
                  user: user,
                  onSwitchAccount: deps.authState.switchAccount,
                );
              }
              if (user.roleId == 'manager') {
                return ManagerDashboard(
                  db: deps.db,
                  user: user,
                  onSwitchAccount: deps.authState.switchAccount,
                );
              }
              final service = StockAdjustmentService(deps.db, (perm) async {
                final rows = await deps.db.query(
                  'role_permissions',
                  columns: const ['permission_key'],
                  where: 'role_id = ? AND permission_key = ?',
                  whereArgs: [user.roleId, perm],
                  limit: 1,
                );
                return StockPermissionDecision(
                  allowed: rows.isNotEmpty,
                  missingPermission: rows.isEmpty ? perm : null,
                );
              });
              return StaffInventoryView(
                service: service,
                activeUserId: user.id,
                activeUserName: user.fullName,
                activeRoleLabel: user.roleId,
                onSwitchAccount: deps.authState.switchAccount,
              );
            },
          );
        },
      ),
    );
  }
}

class _AppDeps {
  const _AppDeps({required this.db, required this.authState});

  final Database db;
  final AuthState authState;
}
