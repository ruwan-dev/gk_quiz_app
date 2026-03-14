import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> iconMap = {
    'public': Icons.public,
    'psychology': Icons.psychology,
    'book': Icons.menu_book,
    'science': Icons.science,
    'language': Icons.translate,
    'history': Icons.history,
    'math': Icons.functions,
    'tech': Icons.laptop_mac,
    'sports': Icons.emoji_events,
    'art': Icons.palette,
    'star': Icons.auto_awesome,
  };

  static IconData getIcon(String? iconName) {
    return iconMap[iconName] ?? Icons.auto_awesome;
  }
}