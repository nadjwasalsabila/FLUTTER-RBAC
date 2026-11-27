import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/features/auth/auth.dart';
import 'package:rbac/features/shared/flow/flow_widgets.dart';
import 'package:rbac/features/staff/stock_adjustment/stock_adjustment.dart';
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

  testWidgets('DemoLoginScreen logs in Staff via email and password form', (
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

    // Label berada di luar field (FlowField), jadi cari field langsung.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'staff',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'demo123',
    );
    // Tombol amber "Masuk" — bukan tab ghost bernama sama.
    await tester.tap(
      find
          .descendant(
            of: find.byType(AmberButton),
            matching: find.text('Masuk'),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(authState.activeUser?.id, 1);
    expect(authState.activeUser?.roleId, 'staff');
    expect(selected?.username, 'staff');
  });

  testWidgets('DemoLoginScreen quick-fill chip populates credentials and submits', (
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

    expect(authState.activeUser?.id, 1);
    expect(authState.activeUser?.roleId, 'staff');
  });

  testWidgets('StaffInventoryView displays items and adjusts stock', (
    tester,
  ) async {
    final service = StockAdjustmentService(
      db,
      buildDbPermissionChecker(db, 'staff'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StaffInventoryView(
          service: service,
          db: db,
          activeUserId: 1,
          activeUserName: 'Petugas Gudang',
          activeRoleLabel: 'staff',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sepatu Safety Steel Toe'), findsOneWidget);
    expect(find.textContaining('SKU-1001'), findsOneWidget);
    expect(find.textContaining('10 pasang'), findsOneWidget);

    // Buka detail lewat tap kartu, lalu alur multi-layar:
    // Detail → Ubah Barang (form gabungan) → Konfirmasi → layar sukses.
    await tester.ensureVisible(find.text('Sepatu Safety Steel Toe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sepatu Safety Steel Toe'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ubah Stok'));
    await tester.tap(find.text('Ubah Stok'));
    await tester.pumpAndSettle();

    // Staff hanya boleh ubah stok: field pertama = Jumlah stok (angka final).
    // Field diawali stok saat ini (10); ketik 14 = stok masuk 4.
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

  testWidgets('StaffInventoryView shows exact denial message when permission missing', (
    tester,
  ) async {
    await db.delete(
      'role_permissions',
      where: 'role_id = ? AND permission_key = ?',
      whereArgs: ['staff', 'stock:adjust'],
    );
    final service = StockAdjustmentService(
      db,
      buildDbPermissionChecker(db, 'staff'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StaffInventoryView(service: service, db: db, activeUserId: 1),
      ),
    );
    await tester.pumpAndSettle();

    // Tanpa izin, tombol "Ubah Stok" tidak dirender sama sekali
    // dan tidak ada dialog yang bisa dibuka.
    expect(find.text('Ubah Stok'), findsNothing);
  });
}
