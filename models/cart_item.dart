import 'menu_item.dart';

class CartItem {
  final MenuItem menu;
  int jumlah;
  CartItem({required this.menu, this.jumlah = 1});
  int get subtotal => menu.harga * jumlah;
}
