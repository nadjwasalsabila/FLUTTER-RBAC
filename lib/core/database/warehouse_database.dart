import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:rbac/features/auth/services/user_seeder.dart';
import 'package:sqflite/sqflite.dart';

/// Membuka database utama aplikasi (`warehouse_rbac.db`) lengkap dengan
/// skema v4, migrasi otomatis, dan seed data awal.
Future<Database> openWarehouseDatabase() async {
  final dbPath = kIsWeb
      ? 'warehouse_rbac.db'
      : p.join(await getDatabasesPath(), 'warehouse_rbac.db');

  return openDatabase(
    dbPath,
    version: 4,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, _) => createAndSeedWarehouseSchema(db),
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
          "ALTER TABLE warehouse_items ADD COLUMN satuan TEXT NOT NULL DEFAULT 'unit'",
        );
        await db.execute(
          'ALTER TABLE warehouse_items ADD COLUMN min_stock INTEGER NOT NULL DEFAULT 10',
        );
      }
      if (oldVersion < 4) {
        await db.execute(
          "ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT 'demo123'",
        );
      }
    },
  );
}

Future<void> createAndSeedWarehouseSchema(Database db) async {
  const tables = [
    'CREATE TABLE roles (id TEXT PRIMARY KEY, display_name TEXT NOT NULL, description TEXT NOT NULL)',
    'CREATE TABLE permissions (key TEXT PRIMARY KEY, description TEXT NOT NULL)',
    'CREATE TABLE role_permissions (role_id TEXT NOT NULL, permission_key TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, PRIMARY KEY (role_id, permission_key), FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE, FOREIGN KEY (permission_key) REFERENCES permissions(key) ON DELETE CASCADE)',
    "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, role_id TEXT NOT NULL, full_name TEXT NOT NULL, username TEXT NOT NULL UNIQUE, is_active INTEGER NOT NULL, password TEXT NOT NULL DEFAULT 'demo123', FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT)",
    "CREATE TABLE warehouse_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT NOT NULL UNIQUE, name TEXT NOT NULL, category TEXT NOT NULL, location TEXT NOT NULL, stock INTEGER NOT NULL CHECK (stock >= 0), satuan TEXT NOT NULL DEFAULT 'unit', min_stock INTEGER NOT NULL DEFAULT 10, updated_at TEXT NOT NULL)",
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

  for (final perm in const [
    ('item:read', 'Lihat daftar barang'),
    ('stock:adjust', 'Tambah dan kurangi stok'),
    ('item:create', 'Tambah dan ubah data barang'),
    ('item:delete', 'Hapus barang'),
    ('policy:edit', 'Ubah kebijakan izin peran'),
  ]) {
    await db.insert('permissions', {
      'key': perm.$1,
      'description': perm.$2,
    });
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
        'is_active': 1,
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
