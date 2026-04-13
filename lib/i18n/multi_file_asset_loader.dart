import 'dart:convert';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class MultiFileAssetLoader extends AssetLoader {
  static const List<String> _fileNames = [
    'common',
    'home',
    'card_selection',
    'reading',
    'splash',
    'menu',
    'spreads',
    'purchase',
  ];

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final merged = <String, dynamic>{};
    for (final fileName in _fileNames) {
      try {
        final jsonStr = await rootBundle.loadString(
          '$path/${locale.languageCode}/$fileName.json',
        );
        final Map<String, dynamic> data = json.decode(jsonStr);
        merged[fileName] = data;
      } catch (_) {}
    }
    return merged;
  }
}
