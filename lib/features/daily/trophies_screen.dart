import 'package:flutter/material.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../data/progress_repository.dart';
import '../../data/settings_repository.dart';

class TrophiesScreen extends StatefulWidget {
  final ProgressRepository progressRepo;
  final SettingsRepository settingsRepo;

  const TrophiesScreen({
    super.key,
    required this.progressRepo,
    required this.settingsRepo,
  });

  @override
  State<TrophiesScreen> createState() => _TrophiesScreenState();
}

class _TrophiesScreenState extends State<TrophiesScreen> {
  List<String> _earnedTrophies = [];
  bool _isDark = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await widget.progressRepo.getTrophies();
    final d = await widget.settingsRepo.getDarkMode();
    if (mounted) {
      setState(() {
        _earnedTrophies = t;
        _isDark = d;
        _loading = false;
      });
    }
  }

  // Generate list of recent 12 months
  List<DateTime> _getRecentMonths() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });
  }

  String _formatMonth(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _keyFor(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}';
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

    final months = _getRecentMonths();

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
          'Monthly Trophies',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete all daily puzzles in a month to earn its exclusive trophy.',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDark ? T.darkChipText : T.chipText,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final dt = months[index];
                    final key = _keyFor(dt);
                    final earned = _earnedTrophies.contains(key);

                    return GestureDetector(
                      onTap: () {
                        Haptics.selection();
                        AudioService.instance.play(Sfx.click);
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  color: earned
                                      ? const Color(0xFFFFB800)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(_formatMonth(dt)),
                              ],
                            ),
                            content: Text(
                              earned
                                  ? 'Trophy unlocked! Congratulations on conquering every daily puzzle of ${_formatMonth(dt)}.'
                                  : 'Solve the remaining daily challenges for ${_formatMonth(dt)} to unlock this trophy!',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isDark
                              ? const Color(0xFF161F38)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: earned
                                ? const Color(0xFFFFB800).withValues(alpha: 0.5)
                                : (_isDark ? Colors.white12 : Colors.black12),
                            width: earned ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: earned
                                  ? const Color(
                                      0xFFFFB800,
                                    ).withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: 44,
                              color: earned
                                  ? const Color(0xFFFFB800)
                                  : (_isDark
                                        ? Colors.white24
                                        : Colors.grey.shade400),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatMonth(dt),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: earned
                                    ? (_isDark ? Colors.white : T.title)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
