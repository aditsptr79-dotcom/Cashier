import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color warnaUtama = Color(0xFF8B1E1E);
const Color warnaLatar = Color(0xFFF7F5F2);
const Color warnaHijau = Color(0xFF27864B);

String rupiah(num nominal) => NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);

int parseNominal(String nilai) {
  final angka = nilai.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(angka) ?? 0;
}

String tanggalKey(DateTime tanggal) => DateFormat('yyyy-MM-dd').format(tanggal);
String tanggalJam(String nilai) {
  final parsed = DateTime.tryParse(nilai);
  return parsed == null ? nilai : DateFormat('dd-MM-yyyy HH:mm').format(parsed);
}
