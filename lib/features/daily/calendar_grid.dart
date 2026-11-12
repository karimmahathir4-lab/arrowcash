import 'package:flutter/material.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final Set<String> completedDays;
  final ValueChanged<DateTime> onDaySelected;
  final bool isDark;

  const CalendarGrid({
    super.key,
    required this.currentMonth,
    required this.completedDays,
    required this.onDaySelected,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    // Monday = 1 ... Sunday = 7
    final startOffset = (firstDayOfMonth.weekday - 1) % 7;

    const weekdayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Weekday initials
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdayHeaders.map((day) {
            return SizedBox(
              width: 36,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? T.darkChipText : T.chipText,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Grid of days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) {
              return const SizedBox.shrink();
            }

            final day = index - startOffset + 1;
            final date = DateTime(currentMonth.year, currentMonth.month, day);
            final key =
                '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

            final isCompleted = completedDays.contains(key);
            final isToday =
                now.year == date.year &&
                now.month == date.month &&
                now.day == date.day;
            final isFuture = date.isAfter(
              DateTime(now.year, now.month, now.day),
            );

            return GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                      Haptics.selection();
                      AudioService.instance.play(Sfx.click);
                      onDaySelected(date);
                    },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? T.accent
                      : (isDark
                            ? const Color(0xFF161F38)
                            : const Color(0xFFF2F5FB)),
                  border: isToday
                      ? Border.all(color: T.accent, width: 2.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isFuture
                              ? Colors.grey.withValues(alpha: 0.4)
                              : (isDark ? Colors.white : T.title),
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
