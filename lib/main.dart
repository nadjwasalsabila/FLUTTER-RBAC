import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rbac/core/app_theme.dart';
import 'package:rbac/features/admin/admin_home_page.dart';
import 'package:rbac/features/auth/auth.dart';
import 'package:rbac/features/manager/item_management/item_management.dart';
import 'package:rbac/features/onboarding/onboarding_screen.dart';
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
  const WarehouseStaffApp({
    super.key,
    this.database,
    this.showOnboarding = true,
  });

  final Database? database;
  final bool showOnboarding;

  @override
  State<WarehouseStaffApp> createState() => _WarehouseStaffAppState();
}

class _WarehouseStaffAppState extends State<WarehouseStaffApp> {
  late final Future<_AppDeps> _depsFuture = _initAppDeps();
  late bool _onboardingDone = !widget.showOnboarding;

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
      version: 4,
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
          if (oldVersion < 3) {
            await db.execute(
              'ALTER TABLE warehouse_items ADD COLUMN satuan TEXT NOT NULL DEFAULT \'unit\'',
            );
            await db.execute(
              'ALTER TABLE warehouse_items ADD COLUMN min_stock INTEGER NOT NULL DEFAULT 10',
            );
          }
          if (oldVersion < 4) {
            await db.execute(
              'ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT \'demo123\'',
            );
          }
      },
    );
  }

  Future<void> _createAndSeedSchema(Database db) async {
    const tables = [
      'CREATE TABLE roles (id TEXT PRIMARY KEY, display_name TEXT NOT NULL, description TEXT NOT NULL)',
      'CREATE TABLE permissions (key TEXT PRIMARY KEY, description TEXT NOT NULL)',
      'CREATE TABLE role_permissions (role_id TEXT NOT NULL, permission_key TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, PRIMARY KEY (role_id, permission_key), FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE, FOREIGN KEY (permission_key) REFERENCES permissions(key) ON DELETE CASCADE)',
      'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, role_id TEXT NOT NULL, full_name TEXT NOT NULL, username TEXT NOT NULL UNIQUE, is_active INTEGER NOT NULL, password TEXT NOT NULL DEFAULT \'demo123\', FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT)',
      'CREATE TABLE warehouse_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT NOT NULL UNIQUE, name TEXT NOT NULL, category TEXT NOT NULL, location TEXT NOT NULL, stock INTEGER NOT NULL CHECK (stock >= 0), satuan TEXT NOT NULL DEFAULT \'unit\', min_stock INTEGER NOT NULL DEFAULT 10, updated_at TEXT NOT NULL)',
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
      ('SKU-1001', 'Sepatu Safety Steel Toe', 'Alas Kaki', 'Aisle A-01', 12, 'pasang', 10),
      ('SKU-1002', 'Sepatu Lari Mesh Biru', 'Alas Kaki', 'Aisle A-02', 20, 'pasang', 5),
      ('SKU-1003', 'Sol Karet Anti-Slip', 'Komponen', 'Aisle B-01', 45, 'lembar', 10),
      ('SKU-1004', 'Kardus Kemasan Ukuran M', 'Pengemasan', 'Aisle C-03', 30, 'unit', 5),
    ]) {
      await db.insert('warehouse_items', {
        'sku': item.$1,
        'name': item.$2,
        'category': item.$3,
        'location': item.$4,
        'stock': item.$5,
        'satuan': item.$6,
        'min_stock': item.$7,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gudang RBAC',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: FutureBuilder<_AppDeps>(
        future: _depsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.errorRed),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat database',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final deps = snapshot.data;
          if (deps == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryTeal,
                ),
              ),
            );
          }
          return ListenableBuilder(
            listenable: deps.authState,
            builder: (context, _) {
              final user = deps.authState.activeUser;
              if (user == null) {
                if (!_onboardingDone) {
                  return OnboardingScreen(
                    onFinish: () => setState(() => _onboardingDone = true),
                  );
                }
                return DemoLoginScreen(authState: deps.authState);
              }
              switch (user.roleId) {
                case 'manager':
                  // Permission checker yang sama dipakai kedua service,
                  // dan keduanya memakai deps.db yang sama dengan staff
                  // sehingga stok & riwayat pergerakan selalu terhubung.
                  Future<bool> checkManagerPermission(String perm) async {
                    final rows = await deps.db.query(
                      'role_permissions',
                      columns: const ['permission_key'],
                      where:
                          'role_id = ? AND permission_key = ? AND is_active = 1',
                      whereArgs: [user.roleId, perm],
                      limit: 1,
                    );
                    return rows.isNotEmpty;
                  }

                  final managerService = ManagerItemService(
                    deps.db,
                    checkManagerPermission,
                  );
                  final stockService = StockAdjustmentService(
                    deps.db,
                    (perm) async {
                      final allowed = await checkManagerPermission(perm);
                      return StockPermissionDecision(
                        allowed: allowed,
                        missingPermission: allowed ? null : perm,
                      );
                    },
                  );
                  return ManagerInventoryView(
                    service: managerService,
                    stockService: stockService,
                    db: deps.db,
                    activeUserId: user.id,
                    activeUserName: user.fullName,
                    activeRoleLabel: user.roleId,
                    onSwitchAccount: deps.authState.switchAccount,
                  );
                case 'admin':
                  return AdminHomePage(
                    db: deps.db,
                    user: user,
                    authState: deps.authState,
                    onSwitchAccount: deps.authState.switchAccount,
                  );
                default:
                  final service = StockAdjustmentService(deps.db, (perm) async {
                    final rows = await deps.db.query(
                      'role_permissions',
                      columns: const ['permission_key'],
                      where:
                          'role_id = ? AND permission_key = ? AND is_active = 1',
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
                    db: deps.db,
                    activeUserId: user.id,
                    activeUserName: user.fullName,
                    activeRoleLabel: user.roleId,
                    onSwitchAccount: deps.authState.switchAccount,
                  );
              }
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
