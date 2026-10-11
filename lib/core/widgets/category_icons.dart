import 'package:flutter/material.dart';

const Map<String, IconData> categoryIcons = {
  'sell': Icons.sell_outlined,
  'handyman': Icons.handyman_outlined,
  'add': Icons.add_circle_outline,
  'inventory': Icons.inventory_2_outlined,
  'tax': Icons.account_balance_outlined,
  'home': Icons.home_work_outlined,
  'bill': Icons.receipt_long_outlined,
  'car': Icons.directions_car_outlined,
  'food': Icons.restaurant_outlined,
  'campaign': Icons.campaign_outlined,
  'tools': Icons.build_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'health': Icons.favorite_border,
  'school': Icons.school_outlined,
  'phone': Icons.smartphone_outlined,
  'payments': Icons.payments_outlined,
  'other': Icons.more_horiz,
};

const List<int> categoryColors = [
  0xFF2E7D32,
  0xFF00897B,
  0xFF0277BD,
  0xFF3949AB,
  0xFF5E35B1,
  0xFFAD1457,
  0xFFD84315,
  0xFFEF6C00,
  0xFF6D4C41,
  0xFF455A64,
  0xFF757575,
  0xFF558B2F,
];

IconData iconForKey(String key) => categoryIcons[key] ?? Icons.more_horiz;
