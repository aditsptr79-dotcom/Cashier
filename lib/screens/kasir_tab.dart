import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

class KasirTab extends StatefulWidget {
  final VoidCallback onChanged;
  const KasirTab({super.key, required this.onChanged});
  @override State<KasirTab> createState() => _KasirTabState();
}
class _KasirTabState extends State<KasirTab> {
  List<MenuItem> _menu = [];
  final List<CartItem> _cart = [];
  String _metode = 'Cash';
  final _dibayar = TextEditingController();
  bool _loading = true;
  int get _total => _cart.fold(0, (s, e) => s + e.subtotal);
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _dibayar.dispose(); super.dispose(); }
  Future<void> _load() async { final m = await DatabaseKasir.instance.semuaMenu(aktifSaja: true); if (!mounted) return; setState(() { _menu = m; _loading = false; }); }
  void _add(MenuItem item) { setState(() { final i = _cart.indexWhere((e) => e.menu.id == item.id); if (i >= 0) { _cart[i].jumlah++; } else { _cart.add(CartItem(menu: item)); } }); }
  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final paid = _metode == 'QRIS' ? _total : parseNominal(_dibayar.text);
    if (paid < _total) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang diterima masih kurang.'))); return; }
    final detail = _cart.map((e) => '${e.menu.nama} x${e.jumlah}').join(', ');
    await DatabaseKasir.instance.simpanTransaksi(total: _total, metode: _metode, dibayar: paid, kembalian: paid - _total, rincian: detail);
    if (!mounted) return;
    final total = _total; final kembali = paid - total;
    setState(() { _cart.clear(); _dibayar.clear(); }); widget.onChanged();
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Transaksi tersimpan'), content: Text('Total: ${rupiah(total)}\nMetode: $_metode\nKembalian: ${rupiah(kembali)}'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
  }
  @override Widget build(BuildContext context) => _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
    Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Expanded(child: Text('Kasir Bakso Mas Gino', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),), Text(rupiah(_total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: warnaUtama))])),
    Expanded(child: ListView(children: [for (final item in _menu) ListTile(title: Text(item.nama), subtitle: Text('${item.kategori} • ${rupiah(item.harga)}'), trailing: IconButton(icon: const Icon(Icons.add_circle, color: warnaUtama), onPressed: () => _add(item))])),
    Container(color: Colors.white, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_cart.isNotEmpty) SizedBox(height: 88, child: ListView(children: [for (final c in _cart) ListTile(dense: true, title: Text('${c.menu.nama} x${c.jumlah}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(rupiah(c.subtotal)), IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { c.jumlah--; if (c.jumlah <= 0) _cart.remove(c); }))])]))),
      SegmentedButton<String>(segments: const [ButtonSegment(value: 'Cash', label: Text('Cash'), icon: Icon(Icons.payments)), ButtonSegment(value: 'QRIS', label: Text('QRIS'), icon: Icon(Icons.qr_code))], selected: {_metode}, onSelectionChanged: (s) => setState(() => _metode = s.first)),
      if (_metode == 'Cash') Padding(padding: const EdgeInsets.only(top: 8), child: TextField(controller: _dibayar, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Uang diterima', border: OutlineInputBorder()))),
      const SizedBox(height: 8), FilledButton(onPressed: _cart.isEmpty ? null : _checkout, child: Text('Selesaikan • ${rupiah(_total)}')),
    ]))
  ]);
}
