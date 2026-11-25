import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rbac.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role_id INTEGER NOT NULL,
        FOREIGN KEY (role_id) REFERENCES roles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE role_permissions (
        role_id INTEGER NOT NULL,
        permission_id INTEGER NOT NULL,
        PRIMARY KEY (role_id, permission_id),
        FOREIGN KEY (role_id) REFERENCES roles(id),
        FOREIGN KEY (permission_id) REFERENCES permissions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouse_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        location TEXT NOT NULL,
        stock INTEGER NOT NULL CHECK (stock >= 0)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES warehouse_items(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    await db.execute('''
      INSERT INTO roles (id, name) VALUES
        (1, 'Staff'), (2, 'Manager'), (3, 'Admin')
    ''');

    await db.execute('''
      INSERT INTO users (id, name, role_id) VALUES
        (1, 'Budi (Staff)', 1),
        (2, 'Sari (Manager)', 2),
        (3, 'Admin Utama', 3)
    ''');

    await db.execute('''
      INSERT INTO permissions (id, name) VALUES
        (1, 'item:read'),
        (2, 'stock:adjust'),
        (3, 'item:create'),
        (4, 'item:delete'),
        (5, 'policy:edit')
    ''');

    await db.execute('''
      INSERT INTO role_permissions (role_id, permission_id) VALUES
        (1, 1), (1, 2),
        (2, 1), (2, 2), (2, 3), (2, 4),
        (3, 1), (3, 2), (3, 3), (3, 4), (3, 5)
    ''');

    final items = [
      "('SKU-001','Kardus Besar','Kemasan','Rak A1',100)",
      "('SKU-002','Selotip Bening','Alat','Laci B2',50)",
      "('SKU-003','Palet Kayu','Peralatan','Gudang C',20)",
      "('SKU-004','Helm Keselamatan','APD','Lemari D1',15)",
      "('SKU-005','Sarung Tangan Latex','APD','Lemari D2',200)",
      "('SKU-006','Timbangan Digital','Alat','Meja E1',5)",
      "('SKU-007','Forklift Kecil','Kendaraan','Parkir F',2)",
      "('SKU-008','Rak Besi','Perabot','Gudang C',10)",
      "('SKU-009','Label Barcode','Kemasan','Laci B1',500)",
      "('SKU-010','Spidol Permanen','Alat Tulis','Laci B3',30)",
      "('SKU-011','Bubble Wrap','Kemasan','Rak A2',80)",
      "('SKU-012','Kunci Inggris','Alat','Lemari D3',8)",
      "('SKU-013','Lampu LED','Elektronik','Rak G1',25)",
      "('SKU-014','Kabel Roll','Elektronik','Rak G2',12)",
      "('SKU-015','Papan Tulis','Perabot','Ruang H',3)",
    ];
    for (final item in items) {
      await db.execute(
        'INSERT INTO warehouse_items (sku, name, category, location, stock) VALUES $item',
      );
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
