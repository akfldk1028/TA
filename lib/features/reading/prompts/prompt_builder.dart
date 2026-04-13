import '../../../models/reading_category.dart';
import '../../../models/spread_type.dart';
import '../models/oracle_persona.dart';
import 'base_prompt.dart';
import 'love_prompt.dart';
import 'career_prompt.dart';
import 'fortune_prompt.dart';
import 'general_prompt.dart';
import 'decision_prompt.dart';

class PromptBuilder {
  const PromptBuilder._();

  static String build({
    required ReadingCategory category,
    required SpreadType spread,
    required OraclePersona persona,
  }) {
    return [
      basePrompt,
      'PERSONA:\n${persona.aiPrompt}',
      _categoryContext(category),
      _spreadContext(spread),
      a2uiRules,
    ].join('\n\n');
  }

  static String _categoryContext(ReadingCategory category) {
    return switch (category) {
      ReadingCategory.love => loveContext,
      ReadingCategory.career => careerContext,
      ReadingCategory.fortune => fortuneContext,
      ReadingCategory.general => generalContext,
      ReadingCategory.decision => decisionContext,
    };
  }

  static String _spreadContext(SpreadType spread) {
    // Use enum name for AI (locale-independent) to avoid mixing languages
    return 'CURRENT SPREAD: ${spread.name} (${spread.cardCount} cards)';
  }
}
