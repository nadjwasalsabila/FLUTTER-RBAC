import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/core/rbac/permission_service.dart';
import 'package:rbac/core/widgets/flow_widgets.dart';
import 'package:rbac/features/auth/auth.dart';
import 'package:rbac/features/warehouse/warehouse.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database_helper.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openTestWarehouseDb();
  });

  tearDown(() async {
    await db.close();
  });

  const staffUser = AuthUser(
    id: 1,
    roleId: 'staff',
    fullName: 'Petugas Gudang',
    username: 'staff',
    isActive: true,
  );

  const managerUser = AuthUser(
    id: 2,
    roleId: 'manager',
    fullName: 'Kepala Gudang',
    username: 'manager',
    isActive: true,
  );

  const adminUser = AuthUser(
    id: 3,
    roleId: 'admin',
    fullName: 'Admin Sistem',
    username: 'admin',
    isActive: true,
  );

  testWidgets('DemoLoginScreen logs in Staff via form credentials', (
    tester,
  ) async {
    final authState = AuthState(LoginService(db));
    AuthUser? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: DemoLoginScreen(
          authState: authState,
          onUserSelected: (user) => selected = user,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'staff');
    await tester.enterText(find.byType(TextFormField).at(1), 'demo123');
    await tester.tap(
      find
          .descendant(of: find.byType(AmberButton), matching: find.text('Masuk'))
          .first,
    );
    await tester.pumpAndSettle();

    expect(authState.activeUser?.id, 1);
    expect(authState.activeUser?.roleId, 'staff');
    expect(selected?.username, 'staff');
  });

  testWidgets('DemoLoginScreen quick-fill chip only fills form until Masuk is tapped', (
    tester,
  ) async {
    final authState = AuthState(LoginService(db));

    await tester.pumpWidget(
      MaterialApp(home: DemoLoginScreen(authState: authState)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Petugas Gudang · staff'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Petugas Gudang · staff'));
    await tester.pumpAndSettle();

    // Belum login sebelum menekan tombol Masuk.
    expect(authState.activeUser, isNull);

    final masukButton = find
        .descendant(of: find.byType(AmberButton), matching: find.text('Masuk'))
        .first;
    await tester.ensureVisible(masukButton);
    await tester.pumpAndSettle();
    await tester.tap(masukButton);
    await tester.pumpAndSettle();

    expect(authState.activeUser?.id, 1);
    expect(authState.activeUser?.roleId, 'staff');
  });

  testWidgets('WarehouseHomePage keeps top header pinned while scrolling items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WarehouseHomePage(db: db, user: staffUser),
      ),
    );
    await tester.pumpAndSettle();

    final heroTopBefore = tester.getTopLeft(find.text('Beranda gudang')).dy;

    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();

    final heroTopAfter = tester.getTopLeft(find.text('Beranda gudang')).dy;
    expect(heroTopAfter, heroTopBefore);
  });

  testWidgets('WarehouseHomePage for Staff adjusts stock and hides create/admin UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WarehouseHomePage(db: db, user: staffUser),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah barang'), findsNothing);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    expect(find.byIcon(Icons.person_add_outlined), findsNothing);

    expect(find.text('Sepatu Safety Steel Toe'), findsOneWidget);
    expect(find.textContaining('10 pasang'), findsOneWidget);

    await tester.tap(find.text('Sepatu Safety Steel Toe'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('Ubah Stok'), findsOneWidget);

    await tester.tap(find.text('Ubah Stok'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '14');
    await tester.ensureVisible(find.text('Simpan perubahan'));
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ya, simpan perubahan'));
    await tester.tap(find.text('Ya, simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Stok berhasil diubah'), findsOneWidget);
    await tester.tap(find.text('Kembali ke daftar'));
    await tester.pumpAndSettle();

    expect(find.text('14 pasang'), findsOneWidget);
  });

  testWidgets('WarehouseHomePage for Manager shows Tambah barang & Delete, hides Admin tools', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WarehouseHomePage(db: db, user: managerUser),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah barang'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    expect(find.byIcon(Icons.person_add_outlined), findsNothing);

    await tester.tap(find.text('Sepatu Safety Steel Toe'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.text('Ubah Barang'), findsOneWidget);
  });

  testWidgets('WarehouseHomePage for Admin shows policy & account creation buttons', (
    tester,
  ) async {
    final authState = AuthState(LoginService(db));

    await tester.pumpWidget(
      MaterialApp(
        home: WarehouseHomePage(
          db: db,
          user: adminUser,
          authState: authState,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    expect(find.text('Tambah barang'), findsOneWidget);
  });

  testWidgets('Dynamic RBAC: granting item:create to staff shows Tambah barang', (
    tester,
  ) async {
    await db.insert('role_permissions', {
      'role_id': 'staff',
      'permission_key': AppPermissions.itemCreate,
      'is_active': 1,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: WarehouseHomePage(db: db, user: staffUser),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah barang'), findsOneWidget);
  });

  testWidgets('Dynamic RBAC: revoking stock:adjust hides Ubah Stok button', (
    tester,
  ) async {
    await db.update(
      'role_permissions',
      {'is_active': 0},
      where: 'role_id = ? AND permission_key = ?',
      whereArgs: ['staff', AppPermissions.stockAdjust],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WarehouseHomePage(db: db, user: staffUser),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sepatu Safety Steel Toe'));
    await tester.pumpAndSettle();

    expect(find.text('Ubah Stok'), findsNothing);
    expect(find.text('Ubah Barang'), findsNothing);
  });
}
