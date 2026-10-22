import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class PengeluaranTab extends StatefulWidget {
  final VoidCallback onChanged;
  const PengeluaranTab({super.key, required this.onChanged});
  @override State<PengeluaranTab> createState() => _PengeluaranTabState();
}
class _PengeluaranTabState extends State<PengeluaranTab> {
  final _keterangan = TextEditingController(); final _nominal = TextEditingController();
  List<Map<String, Object?>> _items = [];
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _keterangan.dispose(); _nominal.dispose(); super.dispose(); }
  Future<void> _load() async { final list = await DatabaseKasir.instance.daftarPengeluaran(tanggalKey(DateTime.now())); if (mounted) setState(() => _items = list); }
  Future<void> _add() async {
    final nominal = parseNominal(_nominal.text); if (_keterangan.text.trim().isEmpty || nominal <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi keterangan dan nominal yang benar.'))); return; }
    await DatabaseKasir.instance.tambahPengeluaran(_keterangan.text.trim(), nominal, 'Operasional'); _keterangan.clear(); _nominal.clear(); await _load(); widget.onChanged();
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pengeluaran Hari Ini'), backgroundColor: warnaUtama, foregroundColor: Colors.white), body: Column(children: [Padding(padding: const EdgeInsets.all(12), child: Column(children: [TextField(controller: _keterangan, decoration: const InputDecoration(labelText: 'Keterangan', border: OutlineInputBorder())), const SizedBox(height: 8), TextField(controller: _nominal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder())), const SizedBox(height: 8), SizedBox(width: double.infinity, child: FilledButton(onPressed: _add, child: const Text('Simpan Pengeluaran')))])), Expanded(child: ListView(children: [for (final e in _items) ListTile(title: Text(e['keterangan'] as String), subtitle: Text(tanggalJam(e['waktu'] as String)), trailing: Text('- ${rupiah(e['nominal'] as int)}', style: const TextStyle(color: Colors.red))) ]))]));
}
