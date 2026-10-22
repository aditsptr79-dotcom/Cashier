
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

class KasirTab extends StatefulWidget {
  final VoidCallback onChanged;

  const KasirTab({
    super.key,
    required this.onChanged,
  });

  @override
  State<KasirTab> createState() => _KasirTabState();
}

class _KasirTabState extends State<KasirTab> {
  List<MenuItem> _menu = [];
  final List<CartItem> _cart = [];

  String _metode = 'Cash';

  final TextEditingController _dibayar =
      TextEditingController();

  bool _loading = true;

  int get _total =>
      _cart.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dibayar.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final menu = await DatabaseKasir.instance.semuaMenu(
      aktifSaja: true,
    );

    if (!mounted) return;

    setState(() {
      _menu = menu;
      _loading = false;
    });
  }

  void _add(MenuItem item) {
    setState(() {
      final index = _cart.indexWhere(
        (cartItem) => cartItem.menu.id == item.id,
      );

      if (index >= 0) {
        _cart[index].jumlah++;
      } else {
        _cart.add(CartItem(menu: item));
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final totalTransaksi = _total;
    final metodeTransaksi = _metode;

    final dibayar = metodeTransaksi == 'QRIS'
        ? totalTransaksi
        : parseNominal(_dibayar.text);

    if (dibayar < totalTransaksi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uang diterima masih kurang.'),
        ),
      );
      return;
    }

    final rincian = _cart
        .map((item) => '${item.menu.nama} x${item.jumlah}')
        .join(', ');

    await DatabaseKasir.instance.simpanTransaksi(
      total: totalTransaksi,
      metode: metodeTransaksi,
      dibayar: dibayar,
      kembalian: dibayar - totalTransaksi,
      rincian: rincian,
    );

    if (!mounted) return;

    final kembalian = dibayar - totalTransaksi;

    setState(() {
      _cart.clear();
      _dibayar.clear();
    });

    widget.onChanged();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transaksi tersimpan'),
        content: Text(
          'Total: ${rupiah(totalTransaksi)}\n'
          'Metode: $metodeTransaksi\n'
          'Kembalian: ${rupiah(kembalian)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Judul dan total transaksi
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Kasir Bakso Mas Gino',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                rupiah(_total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: warnaUtama,
                ),
              ),
            ],
          ),
        ),

        // Daftar menu
        Expanded(
          child: ListView(
            children: [
              for (final item in _menu)
                ListTile(
                  title: Text(item.nama),
                  subtitle: Text(
                    '${item.kategori} • ${rupiah(item.harga)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: warnaUtama,
                    ),
                    onPressed: () => _add(item),
                  ),
                ),
            ],
          ),
        ),

        // Keranjang dan pembayaran
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_cart.isNotEmpty)
                SizedBox(
                  height: 88,
                  child: ListView(
                    children: [
                      for (final item in _cart)
                        ListTile(
                          dense: true,
                          title: Text(
                            '${item.menu.nama} x${item.jumlah}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(rupiah(item.subtotal)),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                ),
                                onPressed: () {
                                  setState(() {
                                    item.jumlah--;

                                    if (item.jumlah <= 0) {
                                      _cart.remove(item);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              // Metode pembayaran
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'Cash',
                    label: Text('Cash'),
                    icon: Icon(Icons.payments),
                  ),
                  ButtonSegment<String>(
                    value: 'QRIS',
                    label: Text('QRIS'),
                    icon: Icon(Icons.qr_code),
                  ),
                ],
                selected: {_metode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _metode = selection.first;
                  });
                },
              ),

              // Input uang tunai
              if (_metode == 'Cash')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _dibayar,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Uang diterima',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Tombol checkout
              FilledButton(
                onPressed: _cart.isEmpty ? null : _checkout,
                child: Text(
                  'Selesaikan • ${rupiah(_total)}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
