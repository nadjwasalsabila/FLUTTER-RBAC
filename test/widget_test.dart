import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/main.dart';

import 'helpers/test_database_helper.dart';

void main() {
  testWidgets('WarehouseStaffApp renders login screen and navigates to Staff view', (
    tester,
  ) async {
    final db = await openTestWarehouseDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      WarehouseStaffApp(database: db, showOnboarding: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gudang RBAC'), findsOneWidget);
    await tester.ensureVisible(find.text('Petugas Gudang · staff'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Petugas Gudang · staff'));
    await tester.pumpAndSettle();

    expect(find.text('Sepatu Safety Steel Toe'), findsOneWidget);
    expect(find.text('Sepatu Safety Steel Toe'), findsOneWidget);
  });
}
