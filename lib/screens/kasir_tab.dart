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
  static const Color _background = Color(0xFFFFF8F0);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF292524);
  static const Color _mutedColor = Color(0xFF78716C);
  static const Color _greenColor = Color(0xFF16805D);

  List<MenuItem> _menu = [];
  final List<CartItem> _cart = [];

  String _metode = 'Cash';
  String _kategori = 'Semua';

  bool _loading = true;
  bool _saving = false;

  int _omzetAwalCash = 0;
  int _omzetAwalQris = 0;

  final TextEditingController _dibayar = TextEditingController();
  
  // State setter khusus agar UI di dalam BottomSheet (HP) ikut terupdate
  StateSetter? _bottomSheetStateSetter;

  int get _total =>
      _cart.fold<int>(0, (sum, item) => sum + item.subtotal);

  int get _jumlahItem =>
      _cart.fold<int>(0, (sum, item) => sum + item.jumlah);

  int get _totalOmzetAwal => _omzetAwalCash + _omzetAwalQris;

  List<String> get _kategoriList {
    final hasil = _menu.map((item) => item.kategori).toSet().toList();
    hasil.sort();

    return ['Semua', ...hasil];
  }

  List<MenuItem> get _menuTerfilter {
    if (_kategori == 'Semua') {
      return _menu;
    }
    return _menu.where((item) => item.kategori == _kategori).toList();
  }

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

  // Fungsi helper agar set state utama & modal sinkron
  void _updateState(VoidCallback fn) {
    setState(fn);
    _bottomSheetStateSetter?.call(fn);
  }

  Future<void> _load() async {
    try {
      final db = DatabaseKasir.instance;

      final menu = await db.semuaMenu(aktifSaja: true);
      final omzet = await db.ambilOmzetAwal(
        tanggalKey(DateTime.now()),
      );

      if (!mounted) return;

      setState(() {
        _menu = menu;
        _omzetAwalCash = omzet['cash'] ?? 0;
        _omzetAwalQris = omzet['qris'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  Future<void> _refreshOmzetAwal() async {
    final omzet = await DatabaseKasir.instance.ambilOmzetAwal(
      tanggalKey(DateTime.now()),
    );

    if (!mounted) return;

    setState(() {
      _omzetAwalCash = omzet['cash'] ?? 0;
      _omzetAwalQris = omzet['qris'] ?? 0;
    });
  }

  void _add(MenuItem item) {
    _updateState(() {
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

  void _kurangi(CartItem item) {
    _updateState(() {
      item.jumlah--;

      if (item.jumlah <= 0) {
        _cart.remove(item);
      }
    });
  }

  void _tambahJumlah(CartItem item) {
    _updateState(() {
      item.jumlah++;
    });
  }

  Future<void> _inputOmzetAwal() async {
    final cashController = TextEditingController(
      text: _omzetAwalCash == 0 ? '' : '$_omzetAwalCash',
    );

    final qrisController = TextEditingController(
      text: _omzetAwalQris == 0 ? '' : '$_omzetAwalQris',
    );

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool menyimpan = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Input omzet awal'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catat penjualan yang terjadi sebelum '
                          'kasir mulai bertugas.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cashController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Omzet awal Cash',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          validator: (value) {
                            final nominal = parseNominal(value ?? '');
                            if (nominal < 0) {
                              return 'Nominal tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: qrisController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Omzet awal QRIS',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                          validator: (value) {
                            final nominal = parseNominal(value ?? '');
                            if (nominal < 0) {
                              return 'Nominal tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nilai yang disimpan menggantikan omzet awal '
                          'sebelumnya untuk tanggal hari ini, bukan '
                          'menambahkan nilai baru.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: menyimpan
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: menyimpan
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() {
                              menyimpan = true;
                            });

                            try {
                              await DatabaseKasir.instance.simpanOmzetAwal(
                                tanggal: tanggalKey(DateTime.now()),
                                cash: parseNominal(cashController.text),
                                qris: parseNominal(qrisController.text),
                              );

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              await _refreshOmzetAwal();
                              widget.onChanged();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Omzet awal berhasil disimpan.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  menyimpan = false;
                                });
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal menyimpan omzet awal: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Simpan omzet'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      cashController.dispose();
      qrisController.dispose();
    }
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty || _saving) return;

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

    _updateState(() {
      _saving = true;
    });

    try {
      await DatabaseKasir.instance.simpanTransaksi(
        total: totalTransaksi,
        metode: metodeTransaksi,
        dibayar: dibayar,
        kembalian: dibayar - totalTransaksi,
        rincian: rincian,
      );

      if (!mounted) return;

      final kembalian = dibayar - totalTransaksi;

      _updateState(() {
        _cart.clear();
        _dibayar.clear();
        _saving = false;
      });

      widget.onChanged();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: _greenColor,
            size: 44,
          ),
          title: const Text('Transaksi berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _barisRingkas('Total', rupiah(totalTransaksi)),
              _barisRingkas('Metode', metodeTransaksi),
              _barisRingkas('Dibayar', rupiah(dibayar)),
              _barisRingkas('Kembalian', rupiah(kembalian)),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _updateState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi gagal disimpan: $e')),
      );
    }
  }

  Widget _barisRingkas(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      color: _cardColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warnaUtama.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: warnaUtama,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bakso Mas Gino',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kasir penjualan',
                  style: TextStyle(color: _mutedColor),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _omzetAwalCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1D5B0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: warnaUtama,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Omzet sebelum kasir datang',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(_totalOmzetAwal),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: warnaUtama,
                  ),
                ),
                Text(
                  'Cash ${rupiah(_omzetAwalCash)}  •  '
                  'QRIS ${rupiah(_omzetAwalQris)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Input omzet awal',
            onPressed: _inputOmzetAwal,
            icon: const Icon(
              Icons.edit_note_rounded,
              color: warnaUtama,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kategoriBar() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final kategori in _kategoriList)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(kategori),
                selected: _kategori == kategori,
                selectedColor: warnaUtama,
                labelStyle: TextStyle(
                  color: _kategori == kategori ? Colors.white : _textColor,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() {
                    _kategori = kategori;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuGrid() {
    final items = _menuTerfilter;

    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada menu dalam kategori ini.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return Material(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _add(item),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEDE7E2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0DB),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _ikonKategori(item.kategori),
                          color: warnaUtama,
                          size: 31,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rupiah(item.harga),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: warnaUtama,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: warnaUtama,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _ikonKategori(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'bakso':
        return Icons.ramen_dining_rounded;
      case 'mie ayam':
        return Icons.soup_kitchen_rounded;
      case 'minuman':
        return Icons.local_drink_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Widget _cartPanel() {
    return Container(
      color: _cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: warnaUtama),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pesanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0DB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_jumlahItem item',
                    style: const TextStyle(
                      color: warnaUtama,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 46,
                            color: Color(0xFFBDB5AE),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada pesanan',
                            style: TextStyle(color: _mutedColor),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pilih menu untuk mulai.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 18),
                    itemBuilder: (context, index) {
                      final item = _cart[index];

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menu.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rupiah(item.subtotal),
                                  style: const TextStyle(
                                    color: warnaUtama,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _kurangi(item),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '${item.jumlah}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _tambahJumlah(item),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: warnaUtama,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBF7),
              border: Border(
                top: BorderSide(color: Color(0xFFEDE7E2)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Metode pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'Cash',
                      label: Text('Cash'),
                      icon: Icon(Icons.payments_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'QRIS',
                      label: Text('QRIS'),
                      icon: Icon(Icons.qr_code_rounded),
                    ),
                  ],
                  selected: {_metode},
                  onSelectionChanged: (selection) {
                    _updateState(() {
                      _metode = selection.first;
                    });
                  },
                ),
                if (_metode == 'Cash') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dibayar,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateState(() {}), // Agar nominal kembalian real-time
                    decoration: const InputDecoration(
                      labelText: 'Uang diterima',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      // Clamp nilai kembalian manual agar aman dari overflow limit JS/Web
                      int kembalian = parseNominal(_dibayar.text) - _total;
                      if (kembalian < 0) kembalian = 0;
                      
                      return Text(
                        'Kembalian: ${rupiah(kembalian)}',
                        style: const TextStyle(
                          color: _greenColor,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _mutedColor,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        rupiah(_total),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: warnaUtama,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _cart.isEmpty || _saving ? null : _checkout,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _saving ? 'Menyimpan...' : 'Selesaikan pembayaran',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: warnaUtama,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

    return Container(
      color: _background,
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            _omzetAwalCard(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Mode Tablet/Desktop
                  if (constraints.maxWidth >= 760) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _kategoriBar(),
                              Expanded(child: _menuGrid()),
                            ],
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: Color(0xFFEDE7E2),
                        ),
                        SizedBox(
                          width: 350,
                          child: _cartPanel(),
                        ),
                      ],
                    );
                  }

                  // Mode Layar Kecil (Mobile)
                  return Column(
                    children: [
                      _kategoriBar(),
                      Expanded(child: _menuGrid()),
                      Container(
                        width: double.infinity,
                        color: _cardColor,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_jumlahItem item'),
                                  Text(
                                    rupiah(_total),
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: warnaUtama,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) => StatefulBuilder(
                                    builder: (context, bottomSheetSetState) {
                                      // Simpan state setter khusus bottom sheet
                                      _bottomSheetStateSetter = bottomSheetSetState;
                                      
                                      return SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.85,
                                        child: _cartPanel(),
                                      );
                                    },
                                  ),
                                ).whenComplete(() {
                                  // Bersihkan setter saat sheet ditutup
                                  _bottomSheetStateSetter = null;
                                });
                              },
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('Pesanan'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
