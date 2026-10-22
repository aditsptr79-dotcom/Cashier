import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'utils/constants.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const KasirBaksoApp()); }
class KasirBaksoApp extends StatelessWidget {
  const KasirBaksoApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Kasir Bakso Mas Gino', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: warnaUtama), scaffoldBackgroundColor: warnaLatar, useMaterial3: true, appBarTheme: const AppBarTheme(centerTitle: false)),
    home: const MainScreen(),
  );
}
