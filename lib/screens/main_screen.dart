import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'kasir_tab.dart';
import 'menu_tab.dart';
import 'pengeluaran_tab.dart';
import 'laporan_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  void _refresh() => setState(() {});
  @override Widget build(BuildContext context) {
    final pages = [KasirTab(onChanged: _refresh), MenuTab(onChanged: _refresh), PengeluaranTab(onChanged: _refresh), const LaporanTab()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index, onDestinationSelected: (v) => setState(() => _index = v),
        indicatorColor: warnaUtama.withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.money_off), label: 'Pengeluaran'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }
}
