import 'package:flutter_test/flutter_test.dart';
import 'package:rbac/core/widgets/flow_widgets.dart';
import 'package:rbac/main.dart';

import 'helpers/test_database_helper.dart';

void main() {
  testWidgets(
    'WarehouseStaffApp quick-fill populates form and requires tapping Masuk',
    (tester) async {
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

      // Masuk cepat hanya mengisi form, belum langsung berpindah ke beranda.
      expect(find.text('Masuk cepat sebagai'), findsOneWidget);
      expect(find.text('Sepatu Safety Steel Toe'), findsNothing);

      final masukButton = find
          .descendant(of: find.byType(AmberButton), matching: find.text('Masuk'))
          .first;
      await tester.ensureVisible(masukButton);
      await tester.pumpAndSettle();
      await tester.tap(masukButton);
      await tester.pumpAndSettle();

      expect(find.text('Sepatu Safety Steel Toe'), findsOneWidget);
      expect(find.text('Tambah barang'), findsNothing);
    },
  );
}
