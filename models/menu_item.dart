class MenuItem {
  final int? id;
  final String nama;
  final String kategori;
  final int harga;
  final bool aktif;

  const MenuItem({this.id, required this.nama, required this.kategori, required this.harga, this.aktif = true});

  Map<String, Object?> toMap() => {'id': id, 'nama': nama, 'kategori': kategori, 'harga': harga, 'aktif': aktif ? 1 : 0};
  factory MenuItem.fromMap(Map<String, Object?> map) => MenuItem(
    id: map['id'] as int?, nama: map['nama'] as String, kategori: map['kategori'] as String,
    harga: map['harga'] as int, aktif: (map['aktif'] as int? ?? 1) == 1,
  );
}
