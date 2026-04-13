import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/oracle_persona.dart';

class PersonaSelector extends StatelessWidget {
  const PersonaSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final OraclePersona selected;
  final ValueChanged<OraclePersona> onChanged;

  /// Each persona gets a unique gradient for visual distinction.
  List<Color> _gradientFor(OraclePersona persona) => switch (persona) {
    OraclePersona.mystic => [const Color(0xFF2D1B69), const Color(0xFF1A0A3E)],
    OraclePersona.analyst => [const Color(0xFF1B2A5C), const Color(0xFF0D1530)],
    OraclePersona.friend => [const Color(0xFF3D1B42), const Color(0xFF1E0D28)],
    OraclePersona.direct => [const Color(0xFF3D2B14), const Color(0xFF1E1408)],
  };

  @override
  Widget build(BuildContext context) {
    final personas = OraclePersona.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: personas.map((persona) {
          final isSelected = persona == selected;
          final gradient = _gradientFor(persona);

          return GestureDetector(
            onTap: () => onChanged(persona),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                border: Border.all(
                  color: isSelected
                      ? TaroColors.gold
                      : TaroColors.gold.withAlpha(30),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: TaroColors.gold.withAlpha(30),
                        blurRadius: 16,
                        spreadRadius: -2,
                      )]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    persona.icon,
                    size: 24,
                    color: isSelected
                        ? TaroColors.gold
                        : TaroColors.gold.withAlpha(140),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    persona.displayName,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      color: isSelected
                          ? TaroColors.gold
                          : Colors.white.withAlpha(200),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
