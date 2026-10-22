import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

class DatabaseKasir {
  DatabaseKasir._();
  static final DatabaseKasir instance = DatabaseKasir._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'kasir_bakso_mas_gino.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE menu(id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT NOT NULL, kategori TEXT NOT NULL, harga INTEGER NOT NULL, aktif INTEGER NOT NULL DEFAULT 1)''');
      await db.execute('''CREATE TABLE transaksi(id INTEGER PRIMARY KEY AUTOINCREMENT, waktu TEXT NOT NULL, total INTEGER NOT NULL, metode TEXT NOT NULL, dibayar INTEGER NOT NULL, kembalian INTEGER NOT NULL, rincian TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE pengeluaran(id INTEGER PRIMARY KEY AUTOINCREMENT, waktu TEXT NOT NULL, keterangan TEXT NOT NULL, nominal INTEGER NOT NULL, kategori TEXT NOT NULL DEFAULT 'Operasional')''');
      await db.execute('''CREATE TABLE modal(id INTEGER PRIMARY KEY AUTOINCREMENT, tanggal TEXT NOT NULL UNIQUE, cash INTEGER NOT NULL DEFAULT 0, qris INTEGER NOT NULL DEFAULT 0)''');
      final defaults = <MenuItem>[
        const MenuItem(nama:'Bakso Urat', kategori:'Bakso', harga:22000),
        const MenuItem(nama:'Bakso Daging', kategori:'Bakso', harga:22000),
        const MenuItem(nama:'Bakso Telur', kategori:'Bakso', harga:22000),
        const MenuItem(nama:'Bakso Biasa', kategori:'Bakso', harga:22000),
        const MenuItem(nama:'Mie Ayam Biasa', kategori:'Mie Ayam', harga:16000),
        const MenuItem(nama:'Mie Ayam Bakso Kecil', kategori:'Mie Ayam', harga:25000),
        const MenuItem(nama:'Mie Ayam Bakso Besar', kategori:'Mie Ayam', harga:28000),
        const MenuItem(nama:'Indomie Bakso', kategori:'Mie Ayam', harga:28000),
        const MenuItem(nama:'Air Mineral', kategori:'Minuman', harga:5000),
        const MenuItem(nama:'Teh Botol / S-Tee', kategori:'Minuman', harga:7000),
        const MenuItem(nama:'Es Jeruk', kategori:'Minuman', harga:10000),
      ];
      for (final item in defaults) { await db.insert('menu', item.toMap()); }
    });
    return _db!;
  }

  Future<List<MenuItem>> semuaMenu({bool aktifSaja = false}) async {
    final db = await database;
    final rows = await db.query('menu', where: aktifSaja ? 'aktif = 1' : null, orderBy: 'kategori, nama');
    return rows.map(MenuItem.fromMap).toList();
  }

  Future<void> simpanMenu(MenuItem item) async {
    final db = await database;
    if (item.id == null) { await db.insert('menu', item.toMap()..remove('id')); }
    else { await db.update('menu', item.toMap(), where: 'id = ?', whereArgs: [item.id]); }
  }

  Future<void> simpanTransaksi({required int total, required String metode, required int dibayar, required int kembalian, required String rincian}) async {
    final db = await database;
    await db.insert('transaksi', {'waktu': DateTime.now().toIso8601String(), 'total': total, 'metode': metode, 'dibayar': dibayar, 'kembalian': kembalian, 'rincian': rincian});
  }

  Future<void> tambahPengeluaran(String keterangan, int nominal, String kategori) async {
    final db = await database;
    await db.insert('pengeluaran', {'waktu': DateTime.now().toIso8601String(), 'keterangan': keterangan, 'nominal': nominal, 'kategori': kategori});
  }

  Future<void> simpanModalHariIni(int cash, int qris) async {
    final db = await database;
    await db.insert('modal', {'tanggal': tanggalKey(DateTime.now()), 'cash': cash, 'qris': qris}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>> ringkasan(String tanggal) async {
    final db = await database;
    final transaksi = await db.query('transaksi', where: "substr(waktu,1,10) = ?", whereArgs: [tanggal]);
    final pengeluaran = await db.query('pengeluaran', where: "substr(waktu,1,10) = ?", whereArgs: [tanggal]);
    final modal = await db.query('modal', where: 'tanggal = ?', whereArgs: [tanggal], limit: 1);
    int cash = 0, qris = 0;
    for (final t in transaksi) { if (t['metode'] == 'Cash') cash += t['total'] as int; else if (t['metode'] == 'QRIS') qris += t['total'] as int; }
    final totalPengeluaran = pengeluaran.fold<int>(0, (sum, e) => sum + (e['nominal'] as int));
    final cashModal = modal.isEmpty ? 0 : modal.first['cash'] as int;
    final qrisModal = modal.isEmpty ? 0 : modal.first['qris'] as int;
    return {'cash': cash, 'qris': qris, 'omzet': cash + qris, 'pengeluaran': totalPengeluaran, 'modalCash': cashModal, 'modalQris': qrisModal, 'transaksi': transaksi.length};
  }

  Future<List<Map<String, Object?>>> daftarPengeluaran(String tanggal) async {
    final db = await database;
    return db.query('pengeluaran', where: 'substr(waktu,1,10) = ?', whereArgs: [tanggal], orderBy: 'waktu DESC');
  }

  Future<List<Map<String, Object?>>> daftarTransaksi(String tanggal) async {
    final db = await database;
    return db.query('transaksi', where: 'substr(waktu,1,10) = ?', whereArgs: [tanggal], orderBy: 'waktu DESC');
  }
}
