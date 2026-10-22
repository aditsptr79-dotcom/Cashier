import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class LaporanTab extends StatefulWidget { const LaporanTab({super.key}); @override State<LaporanTab> createState() => _LaporanTabState(); }
class _LaporanTabState extends State<LaporanTab> {
  DateTime _tanggal = DateTime.now();
  Future<void> _pilihTanggal() async { final d = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => _tanggal = d); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Laporan Keuangan'), backgroundColor: warnaUtama, foregroundColor: Colors.white, actions: [IconButton(onPressed: _pilihTanggal, icon: const Icon(Icons.calendar_month))]), body: FutureBuilder<Map<String, Object?>>(
    future: DatabaseKasir.instance.ringkasan(tanggalKey(_tanggal)), builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('Gagal memuat laporan: ${snapshot.error}'));
      final d = snapshot.data!; final cash = d['cash'] as int; final qris = d['qris'] as int; final omzet = d['omzet'] as int; final pengeluaran = d['pengeluaran'] as int;
      Widget rowData(String label, int value, {Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [Expanded(child: Text(label)), Text(rupiah(value), style: TextStyle(fontWeight: FontWeight.w600, color: color))]));
      return RefreshIndicator(onRefresh: () async => setState(() {}), child: ListView(padding: const EdgeInsets.all(16), children: [Text(DateFormatHelper.display(_tanggal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('OMZET HARIAN'), const SizedBox(height: 6), Text(rupiah(omzet), style: const TextStyle(fontSize: 27, color: warnaUtama, fontWeight: FontWeight.bold)), const Divider(), rowData('Omzet Cash', cash), rowData('Omzet QRIS', qris), rowData('Total omzet', omzet)]))), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [rowData('Modal awal Cash', d['modalCash'] as int), rowData('Modal awal QRIS', d['modalQris'] as int), rowData('Total pengeluaran', pengeluaran, color: Colors.red), const Divider(), rowData('Omzet setelah pengeluaran', omzet - pengeluaran, color: warnaUtama)]))), const Padding(padding: EdgeInsets.only(top: 12), child: Text('Catatan: angka omzet setelah pengeluaran belum dikurangi modal awal atau menghitung laba bersih bahan baku.'))]));
    }));
}
class DateFormatHelper { static String display(DateTime d) => '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}'; }
