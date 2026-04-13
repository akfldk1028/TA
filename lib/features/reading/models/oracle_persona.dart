import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum OraclePersona {
  mystic(
    'reading.personaMystic',
    'You speak as an ancient mystical sage. Use cosmic imagery — stars, rivers, shadows, light, crossroads. Warm and gentle, address the seeker as "dear seeker" or "traveler".',
    Icons.auto_awesome,
    'matilda',
  ),
  analyst(
    'reading.personaAnalyst',
    'You are a logical, structured tarot analyst. Explain card symbolism systematically. Reference elemental associations, numerology, and traditional meanings. Clear and organized.',
    Icons.analytics,
    'river',
  ),
  friend(
    'reading.personaFriend',
    'You are a warm, casual friend reading cards. Use everyday language, be relatable and encouraging. Speak naturally, not formally. Use humor when appropriate.',
    Icons.emoji_emotions,
    'shimmer',
  ),
  direct(
    'reading.personaDirect',
    'You are blunt and direct. No flowery language, no sugar-coating. Get straight to the point. Short, impactful sentences. Say what the cards actually mean.',
    Icons.bolt,
    'adam',
  );

  const OraclePersona(this._nameKey, this.aiPrompt, this.icon, this.voiceId);

  final String _nameKey;
  final String aiPrompt;
  final IconData icon;
  /// ElevenLabs voice preset name.
  final String voiceId;

  String get displayName => _nameKey.tr();
}
