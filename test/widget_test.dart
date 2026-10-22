import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_bakso_lokal/main.dart';

void main() {
  testWidgets('Aplikasi kasir menampilkan navigasi utama', (WidgetTester tester) async {
    await tester.pumpWidget(const KasirBaksoApp());
    expect(find.text('Kasir Bakso Mas Gino'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
  });
}
