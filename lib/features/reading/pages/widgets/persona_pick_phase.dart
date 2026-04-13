import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/oracle_persona.dart';
import 'dramatic_text.dart';
import 'persona_selector.dart';

class PersonaPickPhase extends StatelessWidget {
  const PersonaPickPhase({
    super.key,
    required this.question,
    required this.selectedPersona,
    required this.onPersonaChanged,
    required this.onConfirm,
  });

  final String question;
  final OraclePersona selectedPersona;
  final ValueChanged<OraclePersona> onPersonaChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),

            // User's question — dramatic quote with decorative marks
            DramaticText(
              text: '\u201C$question\u201D',
              fontSize: 26,
              delay: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 20),

            // Decorative line
            FadeIn(
              delay: const Duration(milliseconds: 500),
              child: Container(
                width: 40,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      TaroColors.gold.withAlpha(100),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Instruction — violet tint
            DramaticText(
              text: 'reading.choosePersona'.tr(),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: TaroColors.violet.withAlpha(160),
              delay: const Duration(milliseconds: 700),
              height: 1.6,
            ),
            const SizedBox(height: 24),

            // Persona selector — 2x2 grid with unique gradients
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: PersonaSelector(
                selected: selectedPersona,
                onChanged: onPersonaChanged,
              ),
            ),

            const SizedBox(height: 32),

            // Start button — glass-morphism with gold glow
            FadeIn(
              delay: const Duration(milliseconds: 1300),
              child: SizedBox(
                width: 260,
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TaroColors.gold.withAlpha(25),
                          TaroColors.gold.withAlpha(10),
                        ],
                      ),
                      border: Border.all(color: TaroColors.gold.withAlpha(80)),
                      boxShadow: [
                        BoxShadow(
                          color: TaroColors.gold.withAlpha(15),
                          blurRadius: 20,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.style_outlined,
                              color: TaroColors.gold, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'reading.startCards'.tr(),
                            style: const TextStyle(
                              color: TaroColors.gold,
                              fontSize: 16,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
