#!/usr/bin/env python3
"""
Script untuk membuat database SQLite RBAC.
Jalankan: python create_rbac_db.py
Hasil: rbac.db di folder yang sama
"""

import sqlite3
import os

DB_NAME = "rbac.db"

def create_database():
    # Connect with foreign keys enabled
    conn = sqlite3.connect(DB_NAME)
    conn.execute("PRAGMA foreign_keys = ON")
    cursor = conn.cursor()

    print(f"Membuat database: {DB_NAME}...")

    # 1. Table: users
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            full_name TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_active BOOLEAN DEFAULT 1
        )
    """)
    print("  ✓ Tabel users dibuat")

    # 2. Table: roles
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS roles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    print("  ✓ Tabel roles dibuat")

    # 3. Table: permissions
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS permissions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            resource TEXT,
            action TEXT
        )
    """)
    print("  ✓ Tabel permissions dibuat")

    # 4. Table: role_permissions (relasi role -> permission)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS role_permissions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role_id INTEGER NOT NULL,
            permission_id INTEGER NOT NULL,
            assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
            FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
            UNIQUE(role_id, permission_id)
        )
    """)
    print("  ✓ Tabel role_permissions dibuat")

    # 5. Table: warehouse_items
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS warehouse_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sku TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            description TEXT,
            quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
            unit TEXT DEFAULT 'pcs',
            location TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    print("  ✓ Tabel warehouse_items dibuat")

    # 6. Table: stock_movements (riwayat perubahan stok)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS stock_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            movement_type TEXT NOT NULL CHECK (movement_type IN ('in', 'out', 'adjustment')),
            quantity INTEGER NOT NULL,
            reason TEXT,
            reference TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (item_id) REFERENCES warehouse_items(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    """)
    print("  ✓ Tabel stock_movements dibuat")

    # Index untuk performa
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions(role_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_role_permissions_perm ON role_permissions(permission_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_stock_movements_item ON stock_movements(item_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_stock_movements_user ON stock_movements(user_id)")
    print("  ✓ Index dibuat")

    conn.commit()
    conn.close()
    print(f"\nDatabase {DB_NAME} siap digunakan!")
    print(f"Tempat: {os.path.abspath(DB_NAME)}")

if __name__ == "__main__":
    create_database()
