import 'package:rbac/core/rbac/permission_service.dart';
import 'package:rbac/features/auth/auth.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openTestWarehouseDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfiNoIsolate.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE roles (
            id TEXT PRIMARY KEY,
            display_name TEXT NOT NULL,
            description TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE permissions (
            key TEXT PRIMARY KEY,
            description TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE role_permissions (
            role_id TEXT NOT NULL,
            permission_key TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            PRIMARY KEY (role_id, permission_key),
            FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
            FOREIGN KEY (permission_key) REFERENCES permissions(key) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role_id TEXT NOT NULL,
            full_name TEXT NOT NULL,
            username TEXT NOT NULL UNIQUE,
            is_active INTEGER NOT NULL,
            password TEXT NOT NULL DEFAULT 'demo123',
            FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT
          )
        ''');
        await db.execute('''
          CREATE TABLE warehouse_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sku TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            location TEXT NOT NULL,
            stock INTEGER NOT NULL CHECK (stock >= 0),
            satuan TEXT NOT NULL DEFAULT 'unit',
            min_stock INTEGER NOT NULL DEFAULT 10,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE stock_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            delta INTEGER NOT NULL,
            reason TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (item_id) REFERENCES warehouse_items(id) ON DELETE RESTRICT,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
          )
        ''');

        await _seedBaseData(db);
      },
    ),
  );
  return db;
}

Future<void> _seedBaseData(Database db) async {
  await db.insert('roles', {
    'id': 'staff',
    'display_name': 'Petugas Gudang',
    'description': 'Melihat barang dan mengubah stok',
  });
  await db.insert('roles', {
    'id': 'manager',
    'display_name': 'Kepala Gudang',
    'description': 'Kelola master barang dan stok',
  });
  await db.insert('roles', {
    'id': 'admin',
    'display_name': 'Admin Sistem',
    'description': 'Kelola kebijakan izin role',
  });

  const permissions = {
    'item:read': 'Lihat daftar barang',
    'stock:adjust': 'Tambah dan kurangi stok',
    'item:create': 'Tambah barang baru',
    'item:delete': 'Hapus barang',
    'policy:edit': 'Ubah kebijakan permission',
  };
  for (final entry in permissions.entries) {
    await db.insert('permissions', {
      'key': entry.key,
      'description': entry.value,
    });
  }

  const rolePermissions = {
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
  for (final entry in rolePermissions.entries) {
    for (final perm in entry.value) {
      await db.insert('role_permissions', {
        'role_id': entry.key,
        'permission_key': perm,
        'is_active': 1,
      });
    }
  }

  await const UserSeeder().seed(db);

  await db.insert('warehouse_items', {
    'id': 1,
    'sku': 'SKU-1001',
    'name': 'Sepatu Safety Steel Toe',
    'category': 'Alas Kaki',
    'location': 'Aisle A-01',
    'stock': 10,
    'satuan': 'pasang',
    'min_stock': 10,
    'updated_at': '2026-11-25T10:00:00.000',
  });
  await db.insert('warehouse_items', {
    'id': 2,
    'sku': 'SKU-1002',
    'name': 'Kardus Kemasan M',
    'category': 'Pengemasan',
    'location': 'Aisle B-03',
    'stock': 25,
    'satuan': 'unit',
    'min_stock': 5,
    'updated_at': '2026-11-25T10:00:00.000',
  });
}

PermissionChecker buildDbPermissionChecker(Database db, String roleId) {
  return PermissionService(db).checkerForRole(roleId);
}
