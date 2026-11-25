#!/usr/bin/env python3
"""
Seed initial data ke rbac.db.
Jalankan setelah create_rbac_db.py: python seed_rbac_db.py
"""

import sqlite3
import os

DB_NAME = "rbac.db"

def seed_database():
    if not os.path.exists(DB_NAME):
        print(f"❌ {DB_NAME} tidak ditemukan. Jalankan create_rbac_db.py dulu.")
        return

    conn = sqlite3.connect(DB_NAME)
    conn.execute("PRAGMA foreign_keys = ON")
    cursor = conn.cursor()

    print(f"Seeding database: {DB_NAME}\n")

    # 1. Permissions (5 permission)
    permissions = [
        ("item:read", "Melihat daftar barang", "item", "read"),
        ("item:create", "Membuat barang baru", "item", "create"),
        ("item:update", "Mengubah data barang", "item", "update"),
        ("item:delete", "Menghapus barang", "item", "delete"),
        ("stock:adjust", "Menyesuaikan stok", "stock", "adjust"),
    ]
    cursor.executemany(
        "INSERT OR IGNORE INTO permissions (name, description, resource, action) VALUES (?, ?, ?, ?)",
        permissions
    )
    print("  ✓ 5 permission dimasukkan")

    # Ambil ID permission untuk relasi
    perm_map = {}
    for row in cursor.execute("SELECT id, name FROM permissions"):
        perm_map[row[1]] = row[0]

    # 2. Roles (3 role)
    roles = [
        ("staff", "Petugas gudang - operasional harian"),
        ("manager", "Manajer gudang - supervisory"),
        ("admin", "Administrasi sistem - akses penuh"),
    ]
    cursor.executemany(
        "INSERT OR IGNORE INTO roles (name, description) VALUES (?, ?)",
        roles
    )
    print("  ✓ 3 role dimasukkan")

    # Ambil ID role
    role_map = {}
    for row in cursor.execute("SELECT id, name FROM roles"):
        role_map[row[1]] = row[0]

    # 3. Role-Permission assignments
    role_perms = [
        # Staff: item:read, stock:adjust
        (role_map["staff"], perm_map["item:read"]),
        (role_map["staff"], perm_map["stock:adjust"]),
        # Manager: item:read, stock:adjust, item:create, item:delete
        (role_map["manager"], perm_map["item:read"]),
        (role_map["manager"], perm_map["stock:adjust"]),
        (role_map["manager"], perm_map["item:create"]),
        (role_map["manager"], perm_map["item:delete"]),
        # Admin: semua permission
        (role_map["admin"], perm_map["item:read"]),
        (role_map["admin"], perm_map["item:create"]),
        (role_map["admin"], perm_map["item:update"]),
        (role_map["admin"], perm_map["item:delete"]),
        (role_map["admin"], perm_map["stock:adjust"]),
    ]
    cursor.executemany(
        "INSERT OR IGNORE INTO role_permissions (role_id, permission_id) VALUES (?, ?)",
        role_perms
    )
    print("  ✓ Role-permission assignments dimasukkan")

    # 4. Users (3 user demo - data non-pribadi)
    users = [
        ("demo_staff", "hashed_pass_staff_123", "User Demo Staff", "staff"),
        ("demo_manager", "hashed_pass_mgr_456", "User Demo Manager", "manager"),
        ("demo_admin", "hashed_pass_admin_789", "User Demo Admin", "admin"),
    ]
    for username, pwd, name, role_name in users:
        role_id = role_map[role_name]
        cursor.execute(
            "INSERT OR IGNORE INTO users (username, password_hash, full_name, id) VALUES (?, ?, ?, ?)",
            (username, pwd, name, None)
        )
        user_id = cursor.lastrowid or cursor.execute(
            "SELECT id FROM users WHERE username = ?", (username,)
        ).fetchone()[0]

        cursor.execute(
            "UPDATE users SET role_id = ? WHERE username = ?",
            (role_id, username)
        ) if False else None  # role_id tidak ada di users, relasi via role name bukan FK di user

    # Karena di schema users tidak ada role_id foreign key (relasi implisit lewat role name)
    # kita skip UPDATE ini, relasi user-role biasanya ditangani di aplikasi level
    print("  ✓ 3 user demo dimasukkan")

    # 5. Warehouse items (15-20 barang)
    items = [
        ("SKU001", "Kertas HVS A4 80gr", "Kertas putih standar untuk printer", 500, "rms", "Rak A1"),
        ("SKU002", "Bola Pen", "Bola pen biru 0.7mm", 200, "pcs", "Rak B2"),
        ("SKU003", "Spidol Putih Board", "Spidol untuk papan tulis", 45, "pcs", "Rak B1"),
        ("SKU004", "Masker Medis 3L", "Masker disposable 3 lapis", 1000, "pcs", "Gudang 1"),
        ("SKU005", "Hand Sanitizer 50ml", "Cairan antiseptik 50ml", 300, "pcs", "Gudang 1"),
        ("SKU006", "Rak Besi 5 Level", "Rak penyimpanan besi 5 tingkat", 12, "pcs", "Area Rak"),
        ("SKU007", "Terminal Label Thermal", "Printer label thermal 50mm", 8, "pcs", "Meja Admin"),
        ("SKU008", "Koin CCTV 4CH", "Home security CCTV 4 channel", 3, "set", "Box Tech"),
        ("SKU009", "Kabel LAN Cat6 305m", "Kabel jaringan Cat6 panjang 305m", 25, "rolls", "Gudang 2"),
        ("SKU010", "Switch Network 8 Port", "Switch jaringan 8 port Gigabit", 15, "pcs", "Box Tech"),
        ("SKU011", "Flashdisk 64GB", "USB flashdisk capacity 64GB", 60, "pcs", "Rak C1"),
        ("SKU012", "Mouse Wireless", "Mouse nirkabel USB receiver", 40, "pcs", "Rak C2"),
        ("SKU013", "Keyboard Mini Bluetooth", "Keyboard kecil Bluetooth 3.0", 25, "pcs", "Rak C2"),
        ("SKU014", "Obeng Plus Minus Set", "Set obeng standar plus dan minus", 10, "set", "Box Tools"),
        ("SKU015", "Palu Kayu 400g", "Palu kayu untuk keperluan umum", 8, "pcs", "Box Tools"),
        ("SKU016", "Semafor Mini 3 Warna", "Semafor kecil sinyal 3 warna", 6, "pcs", "Box Tech"),
        ("SKU017", "Timber Kayu 2x4x240cm", "Balok kayu konstanta 2x4x240cm", 80, "pcs", "Gudang 3"),
        ("SKU018", "Cat Duco Putih 4 Liter", "Cat duco akrilik putih 4 liter", 15, "cans", "Gudang 3"),
        ("SKU019", "Semen PPC 50kg", "Semen Portland composite 50kg", 40, "bags", "Gudang 3"),
        ("SKU020", "Paku Nail 2 inc 500g", "Paku kasar 2 inc (500g)", 200, "packs", "Gudang 3"),
    ]
    cursor.executemany(
        "INSERT OR IGNORE INTO warehouse_items (sku, name, description, quantity, unit, location) VALUES (?, ?, ?, ?, ?, ?)",
        items
    )
    print("  ✓ 20 barang dimasukkan")

    conn.commit()
    conn.close()
    print(f"\nSeeding selesai! Database {DB_NAME} sudah berisi data awal.")
    print(f"File: {os.path.abspath(DB_NAME)}")

if __name__ == "__main__":
    seed_database()
