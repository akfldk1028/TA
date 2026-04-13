import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum ReadingCategory {
  fortune(Icons.auto_awesome, 'menu.categoryFortune', 'menu.categoryFortuneDesc'),
  love(Icons.favorite, 'menu.categoryLove', 'menu.categoryLoveDesc'),
  career(Icons.work_outline, 'menu.categoryCareer', 'menu.categoryCareerDesc'),
  general(Icons.blur_on, 'menu.categoryGeneral', 'menu.categoryGeneralDesc'),
  decision(Icons.call_split, 'menu.categoryDecision', 'menu.categoryDecisionDesc');

  const ReadingCategory(this.icon, this._labelKey, this._subtitleKey);
  final IconData icon;
  final String _labelKey;
  final String _subtitleKey;

  String get label => _labelKey.tr();
  String get subtitle => _subtitleKey.tr();
}
