import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/features/auth/auth.dart';
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email atau Username'),
      'staff@gudang.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'demo123',
    );
    await tester.tap(find.text('Masuk'));
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

    await tester.tap(find.text('Petugas Gudang (staff)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
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
          activeUserId: 1,
          activeUserName: 'Petugas Gudang',
          activeRoleLabel: 'staff',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sepatu Safety Steel Toe'), findsOneWidget);
    expect(find.textContaining('SKU-1001'), findsOneWidget);
    expect(find.text('10 unit'), findsOneWidget);

    // Buka lembar detail barang dari kartu, lalu tekan "Ubah stok".
    await tester.tap(find.text('Sepatu Safety Steel Toe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah stok'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Jumlah perubahan'),
      '4',
    );
    await tester.tap(find.text('Koreksi stok'));
    await tester.pump();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Stok berhasil diperbarui.'), findsWidgets);
    expect(find.text('14 unit'), findsOneWidget);
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
        home: StaffInventoryView(service: service, activeUserId: 1),
      ),
    );
    await tester.pumpAndSettle();

    // Buka lembar detail barang dari kartu, lalu tekan "Ubah stok";
    // penolakan izin tetap muncul saat dialog disimpan.
    await tester.tap(find.text('Sepatu Safety Steel Toe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah stok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Akses ditolak: Anda tidak memiliki izin stock:adjust.'),
      findsWidgets,
    );
  });
}
