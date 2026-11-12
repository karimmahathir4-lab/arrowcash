import 'package:flutter/material.dart';

enum ArrowThemeStyle {
  classic('Classic Navy', Color(0xFF0B1340), Color(0xFF0A84FF)),
  neonPurple('Neon Purple', Color(0xFF6200EA), Color(0xFFB388FF)),
  emerald('Emerald Ocean', Color(0xFF004D40), Color(0xFF00E676)),
  sunset('Sunset Blaze', Color(0xFFBF360C), Color(0xFFFF9100)),
  crimson('Midnight Ruby', Color(0xFF880E4F), Color(0xFFFF4081));

  final String label;
  final Color primaryColor;
  final Color accentColor;
  const ArrowThemeStyle(this.label, this.primaryColor, this.accentColor);
}

class T {
  static const bg = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0B1340); // arrows (dark navy)
  static const title = Color(0xFF4A5470); // slate headline text
  static const accent = Color(
    0xFF0A84FF,
  ); // buttons, icons, hint glow, selected
  static const chipBg = Color(0xFFEEF2F9); // top status chips
  static const chipText = Color(0xFF4A5578);
  static const heart = Color(0xFFFF2D3F);
  static const ghostDot = Color(0xFFBDBDBD);
  static const error = Color(0xFFFF3B30);
  static const success = Color(0xFF34C759); // Green for correct arrow escape

  // Completion gradient (top -> bottom)
  static const winTop = Color(0xFF0A7CF5);
  static const winBottom = Color(0xFF2BB8FF);

  static const confetti = [
    Color(0xFFFFE600),
    Color(0xFFFF7BD5),
    Color(0xFF7DF9C7),
    Color(0xFF3DE0FF),
    Color(0xFFB69CFF),
    Color(0xFFFFB86B),
  ];

  // Dark mode tokens
  static const darkBg = Color(0xFF0B1020);
  static const darkInk = Color(0xFFE8ECFF);
  static const darkAccent = Color(0xFF4DA3FF);
  static const darkChipBg = Color(0xFF1B233D);
  static const darkChipText = Color(0xFFB0BDD9);
}
