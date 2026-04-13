import 'package:easy_localization/easy_localization.dart';

import 'reading_category.dart';

enum SpreadTier { free, premium, pro }

enum SpreadType {
  dailyOne(cardCount: 1, nameKey: 'spreads.dailyOneName', descKey: 'spreads.dailyOneDesc', posKey: 'spreads.dailyOnePositions', category: ReadingCategory.fortune, tier: SpreadTier.free),
  monthlyForecast(cardCount: 4, nameKey: 'spreads.monthlyForecastName', descKey: 'spreads.monthlyForecastDesc', posKey: 'spreads.monthlyForecastPositions', category: ReadingCategory.fortune, tier: SpreadTier.free),
  loveReading(cardCount: 8, nameKey: 'spreads.loveReadingName', descKey: 'spreads.loveReadingDesc', posKey: 'spreads.loveReadingPositions', category: ReadingCategory.love, tier: SpreadTier.free),
  hiddenFeelings(cardCount: 8, nameKey: 'spreads.hiddenFeelingsName', descKey: 'spreads.hiddenFeelingsDesc', posKey: 'spreads.hiddenFeelingsPositions', category: ReadingCategory.love, tier: SpreadTier.free),
  careerReading(cardCount: 6, nameKey: 'spreads.careerReadingName', descKey: 'spreads.careerReadingDesc', posKey: 'spreads.careerReadingPositions', category: ReadingCategory.career, tier: SpreadTier.free),
  generalReading(cardCount: 5, nameKey: 'spreads.generalReadingName', descKey: 'spreads.generalReadingDesc', posKey: 'spreads.generalReadingPositions', category: ReadingCategory.general, tier: SpreadTier.free),
  yesNo(cardCount: 1, nameKey: 'spreads.yesNoName', descKey: 'spreads.yesNoDesc', posKey: 'spreads.yesNoPositions', category: ReadingCategory.decision, tier: SpreadTier.free),
  twoPath(cardCount: 5, nameKey: 'spreads.twoPathName', descKey: 'spreads.twoPathDesc', posKey: 'spreads.twoPathPositions', category: ReadingCategory.decision, tier: SpreadTier.free),
  compatibility(cardCount: 6, nameKey: 'spreads.compatibilityName', descKey: 'spreads.compatibilityDesc', posKey: 'spreads.compatibilityPositions', category: ReadingCategory.love, tier: SpreadTier.free),
  fiveCard(cardCount: 5, nameKey: 'spreads.fiveCardName', descKey: 'spreads.fiveCardDesc', posKey: 'spreads.fiveCardPositions', category: ReadingCategory.general, tier: SpreadTier.free),
  celticCross(cardCount: 10, nameKey: 'spreads.celticCrossName', descKey: 'spreads.celticCrossDesc', posKey: 'spreads.celticCrossPositions', category: ReadingCategory.general, tier: SpreadTier.pro);

  const SpreadType({
    required this.cardCount,
    required String nameKey,
    required String descKey,
    required String posKey,
    required this.category,
    required this.tier,
  })  : _nameKey = nameKey,
        _descKey = descKey,
        _posKey = posKey;

  final int cardCount;
  final String _nameKey;
  final String _descKey;
  final String _posKey;
  final ReadingCategory category;
  final SpreadTier tier;

  String get displayName => _nameKey.tr();
  String get description => _descKey.tr();
  List<String> get positions => _posKey.tr().split('|');

  static List<SpreadType> forCategory(ReadingCategory cat) =>
      values.where((s) => s.category == cat && s.tier == SpreadTier.free).toList();
}
