import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

class BottomActions extends StatelessWidget {
  final int hintCount;
  final bool gridActive;
  final VoidCallback onHintTap;
  final VoidCallback onGridToggle;
  final VoidCallback onStyleTap;
  final VoidCallback onResetZoomTap;
  final bool isDark;
  final ArrowThemeStyle currentStyle;

  const BottomActions({
    super.key,
    required this.hintCount,
    required this.gridActive,
    required this.onHintTap,
    required this.onGridToggle,
    required this.onStyleTap,
    required this.onResetZoomTap,
    this.isDark = false,
    this.currentStyle = ArrowThemeStyle.classic,
  });

  @override
  Widget build(BuildContext context) {
    final buttonBg = isDark ? const Color(0xFF1B233D) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Color Palette / Style button
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: buttonBg,
              shape: BoxShape.circle,
              border: Border.all(color: currentStyle.primaryColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.palette_outlined,
                color: currentStyle.primaryColor,
                size: 26,
              ),
              onPressed: onStyleTap,
              tooltip: 'Arrow Color Style (${currentStyle.label})',
            ),
          ),

          const SizedBox(width: 14),

          // 2. Hint Button (Main action button)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: buttonBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: T.accent.withValues(alpha: 0.85),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: T.accent.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: T.accent,
                    size: 34,
                  ),
                  onPressed: onHintTap,
                  tooltip: 'Hint',
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: T.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hintCount > 0 ? '$hintCount' : '+',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // 3. Grid Assist Toggle
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: buttonBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: gridActive
                    ? T.accent
                    : (isDark ? Colors.white24 : Colors.black12),
                width: gridActive ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gridActive
                      ? T.accent.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.tag_rounded,
                color: gridActive
                    ? T.accent
                    : (isDark ? T.darkChipText : T.chipText),
                size: 26,
              ),
              onPressed: onGridToggle,
              tooltip: 'Grid Assist',
            ),
          ),

          const SizedBox(width: 14),

          // 4. Reset Zoom / Center button
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: buttonBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.fit_screen_rounded,
                color: isDark ? T.darkChipText : T.chipText,
                size: 24,
              ),
              onPressed: onResetZoomTap,
              tooltip: 'Reset Zoom & Center',
            ),
          ),
        ],
      ),
    );
  }
}
