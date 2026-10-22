import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

class MenuTab extends StatefulWidget {
  final VoidCallback onChanged;
  const MenuTab({super.key, required this.onChanged});
  @override State<MenuTab> createState() => _MenuTabState();
}
class _MenuTabState extends State<MenuTab> {
  List<MenuItem> _items = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final rows = await DatabaseKasir.instance.semuaMenu(); if (mounted) setState(() => _items = rows); }
  Future<void> _edit([MenuItem? item]) async {
    final nama = TextEditingController(text: item?.nama ?? '');
    final kategori = TextEditingController(text: item?.kategori ?? 'Bakso');
    final harga = TextEditingController(text: item?.harga.toString() ?? '');
    bool aktif = item?.aktif ?? true;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: Text(item == null ? 'Tambah menu' : 'Edit menu'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama menu')), TextField(controller: kategori, decoration: const InputDecoration(labelText: 'Kategori')), TextField(controller: harga, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')), SwitchListTile(title: const Text('Menu aktif'), value: aktif, onChanged: (v) => setD(() => aktif = v))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan'))])));
    if (ok == true && nama.text.trim().isNotEmpty && parseNominal(harga.text) > 0) {
      await DatabaseKasir.instance.simpanMenu(MenuItem(id: item?.id, nama: nama.text.trim(), kategori: kategori.text.trim().isEmpty ? 'Lainnya' : kategori.text.trim(), harga: parseNominal(harga.text), aktif: aktif));
      await _load(); widget.onChanged();
    }
    nama.dispose(); kategori.dispose(); harga.dispose();
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Daftar Menu'), backgroundColor: warnaUtama, foregroundColor: Colors.white, actions: [IconButton(onPressed: () => _edit(), icon: const Icon(Icons.add))]), body: ListView(children: [for (final p in _items) ListTile(title: Text(p.nama), subtitle: Text('${p.kategori} • ${rupiah(p.harga)}${p.aktif ? '' : ' • Nonaktif'}'), trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(p)))]), floatingActionButton: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)));
}
