import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../data/progress_repository.dart';
import '../../data/settings_repository.dart';
import 'calendar_grid.dart';

class DailyScreen extends StatefulWidget {
  final ProgressRepository progressRepo;
  final SettingsRepository settingsRepo;

  const DailyScreen({
    super.key,
    required this.progressRepo,
    required this.settingsRepo,
  });

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  Set<String> _completedDays = {};
  bool _isDark = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.progressRepo.getCompletedDaily();
    final d = await widget.settingsRepo.getDarkMode();
    if (mounted) {
      setState(() {
        _completedDays = list.toSet();
        _isDark = d;
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    Haptics.selection();
    AudioService.instance.play(Sfx.click);
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month >= now.month) {
      return; // Can't go to future month
    }
    Haptics.selection();
    AudioService.instance.play(Sfx.click);
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? T.darkBg : T.bg;
    final titleColor = _isDark ? Colors.white : T.title;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    int completedInThisMonth = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final key =
          '${_currentMonth.year}${_currentMonth.month.toString().padLeft(2, '0')}${d.toString().padLeft(2, '0')}';
      if (_completedDays.contains(key)) completedInThisMonth++;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 34,
            color: T.accent,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Challenge',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // Monthly Trophy Preview Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      T.accent.withValues(alpha: 0.12),
                      T.winBottom.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: T.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFB800),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatMonthYear(_currentMonth),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedInThisMonth / $daysInMonth completed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isDark ? T.darkChipText : T.chipText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Month Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 30,
                      color: T.accent,
                    ),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    _formatMonthYear(_currentMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 30,
                      color: T.accent,
                    ),
                    onPressed: _nextMonth,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Calendar Grid
              CalendarGrid(
                currentMonth: _currentMonth,
                completedDays: _completedDays,
                isDark: _isDark,
                onDaySelected: (date) async {
                  final key =
                      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
                  await context.push('/daily/$key');
                  _load();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
