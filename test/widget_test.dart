import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/main.dart';

import 'helpers/test_database_helper.dart';

void main() {
  testWidgets('WarehouseStaffApp renders login screen and navigates to Staff view', (
    tester,
  ) async {
    final db = await openTestWarehouseDb();
    addTearDown(db.close);

    await tester.pumpWidget(WarehouseStaffApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('Masuk Gudang RBAC'), findsOneWidget);
    await tester.tap(find.text('Petugas Gudang (staff)'));
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Stok Gudang'), findsOneWidget);
    expect(find.text('Penyesuaian stok'), findsOneWidget);
    expect(find.text('Sepatu Safety Steel Toe'), findsOneWidget);
  });
}
