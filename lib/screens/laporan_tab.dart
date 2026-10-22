
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../utils/constants.dart';

class LaporanTab extends StatefulWidget {
  const LaporanTab({super.key});

  @override
  State<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<LaporanTab> {
  DateTime _tanggal = DateTime.now();

  static const Color _background = Color(0xFFFFF8F0);
  static const Color _textColor = Color(0xFF292524);
  static const Color _mutedColor = Color(0xFF78716C);
  static const Color _greenColor = Color(0xFF16805D);
  static const Color _redColor = Color(0xFFB42318);

  Future<void> _pilihTanggal() async {
    final tanggal = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (tanggal != null && mounted) {
      setState(() {
        _tanggal = tanggal;
      });
    }
  }

  Future<void> _resetDatabase() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 44,
          color: _redColor,
        ),
        title: const Text('Reset data operasional?'),
        content: const Text(
          'Tindakan ini akan menghapus SEMUA:\n\n'
          '• Riwayat transaksi\n'
          '• Omzet awal seluruh tanggal\n'
          '• Data pengeluaran\n'
          '• Data modal awal\n\n'
          'Data menu tetap dipertahankan. '
          'Data yang dihapus tidak dapat dipulihkan melalui aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _redColor,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, reset data'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) {
      return;
    }

    try {
      await DatabaseKasir.instance.resetDataOperasional();

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data operasional berhasil direset. Menu tetap tersimpan.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mereset data: $e'),
        ),
      );
    }
  }

  Widget _kartu({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFEDE7E2),
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _barisData(
    String label,
    int nilai, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? _textColor : _mutedColor,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              rupiah(nilai),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color ?? _textColor,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuOmzet({
    required String judul,
    required int nilai,
    required IconData ikon,
    required Color warna,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warna.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: warna, size: 24),
          const SizedBox(height: 12),
          Text(
            judul,
            style: const TextStyle(
              color: _mutedColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            rupiah(nilai),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }

  Widget _isiLaporan(Map<String, Object?> data) {
    final cash = data['cash'] as int;
    final qris = data['qris'] as int;
    final omzet = data['omzet'] as int;

    final omzetAwalCash = data['omzetAwalCash'] as int;
    final omzetAwalQris = data['omzetAwalQris'] as int;

    final transaksiCash = data['penjualanTransaksiCash'] as int;
    final transaksiQris = data['penjualanTransaksiQris'] as int;

    final modalCash = data['modalCash'] as int;
    final modalQris = data['modalQris'] as int;

    final pengeluaran = data['pengeluaran'] as int;
    final jumlahTransaksi = data['transaksi'] as int;

    final sisaSetelahPengeluaran = omzet - pengeluaran;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future<void>.delayed(
          const Duration(milliseconds: 300),
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ringkasan penjualan',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Pilih tanggal',
                onPressed: _pilihTanggal,
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  color: warnaUtama,
                ),
              ),
            ],
          ),
          Text(
            DateFormatHelper.display(_tanggal),
            style: const TextStyle(color: _mutedColor),
          ),
          const SizedBox(height: 16),

          // Total omzet harian.
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: warnaUtama,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'TOTAL OMZET HARIAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rupiah(omzet),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$jumlahTransaksi transaksi tercatat melalui aplikasi',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Kartu omzet Cash dan QRIS.
          Row(
            children: [
              Expanded(
                child: _kartuOmzet(
                  judul: 'Total Cash',
                  nilai: cash,
                  ikon: Icons.payments_outlined,
                  warna: _greenColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kartuOmzet(
                  judul: 'Total QRIS',
                  nilai: qris,
                  ikon: Icons.qr_code_rounded,
                  warna: const Color(0xFF315FC4),
                ),
              ),
            ],
          ),

          // Rincian omzet awal dan transaksi aplikasi.
          _kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian omzet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Omzet sebelum kasir datang',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: warnaUtama,
                  ),
                ),
                _barisData('Cash', omzetAwalCash),
                _barisData('QRIS', omzetAwalQris),
                _barisData(
                  'Total omzet awal',
                  omzetAwalCash + omzetAwalQris,
                  bold: true,
                ),
                const Divider(height: 24),
                const Text(
                  'Transaksi melalui aplikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: warnaUtama,
                  ),
                ),
                _barisData('Cash', transaksiCash),
                _barisData('QRIS', transaksiQris),
                const Divider(height: 24),
                _barisData(
                  'Total omzet Cash',
                  cash,
                  bold: true,
                ),
                _barisData(
                  'Total omzet QRIS',
                  qris,
                  bold: true,
                ),
                const Divider(height: 16),
                _barisData(
                  'TOTAL OMZET',
                  omzet,
                  bold: true,
                  color: warnaUtama,
                ),
              ],
            ),
          ),

          // Modal dan pengeluaran.
          _kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modal dan pengeluaran',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _barisData('Modal awal Cash', modalCash),
                _barisData('Modal awal QRIS', modalQris),
                _barisData(
                  'Total modal awal',
                  modalCash + modalQris,
                  bold: true,
                ),
                const Divider(height: 24),
                _barisData(
                  'Total pengeluaran',
                  pengeluaran,
                  color: _redColor,
                  bold: true,
                ),
                const Divider(height: 16),
                _barisData(
                  'Omzet dikurangi pengeluaran',
                  sisaSetelahPengeluaran,
                  color: warnaUtama,
                  bold: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Angka terakhir merupakan omzet dikurangi pengeluaran '
                  'yang dicatat. Ini bukan laba bersih dan belum '
                  'memperhitungkan modal bahan baku, stok, atau biaya '
                  'lain yang belum dimasukkan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),

          // Reset manual.
          _kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.settings_backup_restore_rounded,
                      color: _redColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pengelolaan data',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reset menghapus data operasional dari semua tanggal, '
                  'tetapi daftar menu tetap tersimpan.',
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetDatabase,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Reset data operasional'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _redColor,
                      side: const BorderSide(color: _redColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
    final tanggal = tanggalKey(_tanggal);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: warnaUtama,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Pilih tanggal',
            onPressed: _pilihTanggal,
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, Object?>>(
        key: ValueKey(tanggal),
        future: DatabaseKasir.instance.ringkasan(tanggal),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal memuat laporan:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Data laporan tidak tersedia.'),
            );
          }

          return _isiLaporan(snapshot.data!);
        },
      ),
    );
  }
}

class DateFormatHelper {
  static String display(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }
}
