import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_service.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../data/progress_repository.dart';
import '../../data/reward_service.dart';
import '../../data/settings_repository.dart';
import '../settings/settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  final ProgressRepository progressRepo;
  final SettingsRepository settingsRepo;
  final RewardService rewardService;

  const HomeScreen({
    super.key,
    required this.progressRepo,
    required this.settingsRepo,
    required this.rewardService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentLevel = 1;
  int _hints = 3;
  bool _isDark = false;
  bool _todayCompleted = false;
  bool _loading = true;
  late final AnimationController _miniAnimController;

  @override
  void initState() {
    super.initState();
    _miniAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _refresh();
  }

  @override
  void dispose() {
    _miniAnimController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final lvl = await widget.progressRepo.getCurrentLevel();
    final h = await widget.progressRepo.getHints();
    final dark = await widget.settingsRepo.getDarkMode();
    final completed = await widget.progressRepo.getCompletedDaily();

    final now = DateTime.now();
    final todayKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final isDone = completed.contains(todayKey);

    if (mounted) {
      setState(() {
        _currentLevel = lvl;
        _hints = h;
        _isDark = dark;
        _todayCompleted = isDone;
        _loading = false;
      });
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(
        settingsRepo: widget.settingsRepo,
        progressRepo: widget.progressRepo,
        onSettingsChanged: () {
          _refresh();
        },
      ),
    );
  }

  void _showGetHintsDialog() {
    AudioService.instance.play(Sfx.click);
    Haptics.light();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: T.accent, size: 28),
            SizedBox(width: 8),
            Text(
              'Get Free Hints',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          _hints == 0
              ? 'You have 0 hints. Watch a short video ad to earn 2 free hints!'
              : 'You currently have $_hints hints. Watch a short video ad to get 2 more hints!',
          style: const TextStyle(fontSize: 15, height: 1.3),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Watch Ad (+2 Hints)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: T.accent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              AdService.instance.showRewardedAd(
                onRewardEarned: () async {
                  await widget.progressRepo.addHints(2);
                  await _refresh();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('+2 Hints added!')),
                  );
                },
                onFailure: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ad not ready yet. Please try again shortly.',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDebugMenu() {
    final textController = TextEditingController(text: '$_currentLevel');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Debug / Jump Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jump to Level'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await widget.progressRepo.addHints(10);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _refresh();
                }
              },
              child: const Text('Add 10 Hints'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final target = int.tryParse(textController.text) ?? _currentLevel;
              widget.progressRepo.setCurrentLevel(target);
              Navigator.pop(ctx);
              _refresh();
              if (mounted) {
                context.push('/game/$target');
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bg = _isDark ? T.darkBg : T.bg;
    final titleColor = _isDark ? Colors.white : T.title;

    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final logoSize = compact ? 88.0 : 112.0;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 24,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _showGetHintsDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _isDark ? T.darkChipBg : T.chipBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 18,
                                  color: T.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_hints hints',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isDark
                                        ? T.darkChipText
                                        : T.chipText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: T.accent,
                            size: 26,
                          ),
                          onPressed: _openSettings,
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onLongPress: _showDebugMenu,
                                        child: Text(
                                          'Arrow Cash\nClear Rush',
                                          style: TextStyle(
                                            fontSize: compact ? 27 : 34,
                                            fontWeight: FontWeight.w900,
                                            color: titleColor,
                                            letterSpacing: -0.5,
                                            height: 1.05,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Escape the maze, arrow by arrow',
                                        style: TextStyle(
                                          fontSize: compact ? 13 : 16,
                                          color: _isDark
                                              ? T.darkChipText
                                              : T.chipText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: compact ? 8 : 20),
                                SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: AnimatedBuilder(
                                    animation: _miniAnimController,
                                    builder: (context, _) => CustomPaint(
                                      painter: _AnimatedLogoPainter(
                                        t: _miniAnimController.value,
                                        isDark: _isDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: compact ? 12 : 28),
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: T.accent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () async {
                                      AudioService.instance.play(Sfx.click);
                                      Haptics.light();
                                      await context.push(
                                        '/game/$_currentLevel',
                                      );
                                      _refresh();
                                    },
                                    child: Text(
                                      'PLAY  ·  LEVEL $_currentLevel',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: T.accent,
                                        ),
                                        label: const Text('Daily'),
                                        onPressed: () async {
                                          AudioService.instance.play(Sfx.click);
                                          Haptics.light();
                                          await context.push('/daily');
                                          _refresh();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.emoji_events_rounded,
                                          color: T.accent,
                                        ),
                                        label: const Text('Trophies'),
                                        onPressed: () async {
                                          AudioService.instance.play(Sfx.click);
                                          Haptics.light();
                                          await context.push('/trophies');
                                          _refresh();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar with settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _showGetHintsDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _isDark ? T.darkChipBg : T.chipBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hints == 0
                              ? T.accent.withValues(alpha: 0.6)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: T.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_hints hints',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isDark ? T.darkChipText : T.chipText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: T.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: T.accent,
                      size: 28,
                    ),
                    onPressed: _openSettings,
                    tooltip: 'Settings',
                  ),
                ],
              ),

              // Title and Animated Mini-Board Logo
              Column(
                children: [
                  GestureDetector(
                    onLongPress: _showDebugMenu,
                    child: Text(
                      'Arrow Cash\nClear Rush',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Escape the maze, arrow by arrow',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isDark ? T.darkChipText : T.chipText,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mini animated maze logo
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: AnimatedBuilder(
                      animation: _miniAnimController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _AnimatedLogoPainter(
                            t: _miniAnimController.value,
                            isDark: _isDark,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Column(
                children: [
                  // Primary "Play" button with Level {currentLevel}
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: T.accent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      onPressed: () async {
                        AudioService.instance.play(Sfx.click);
                        Haptics.light();
                        await context.push('/game/$_currentLevel');
                        _refresh();
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'PLAY',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Level $_currentLevel',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary Buttons (Daily Challenge & Trophies)
                  Row(
                    children: [
                      // Daily Challenge
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isDark ? Colors.white24 : Colors.black12,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            AudioService.instance.play(Sfx.click);
                            Haptics.light();
                            await context.push('/daily');
                            _refresh();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: T.accent,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Daily',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _isDark ? Colors.white : T.title,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_todayCompleted)
                                const Positioned(
                                  top: -4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: T.heart,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Trophies
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isDark ? Colors.white24 : Colors.black12,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            AudioService.instance.play(Sfx.click);
                            Haptics.light();
                            await context.push('/trophies');
                            _refresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: T.accent,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Trophies',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _isDark ? Colors.white : T.title,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoPainter extends CustomPainter {
  final double t;
  final bool isDark;

  _AnimatedLogoPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = isDark ? T.darkInk : T.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = isDark ? T.darkInk : T.ink
      ..style = PaintingStyle.fill;

    // Center 4-arrow pinwheel
    final center = Offset(size.width / 2, size.height / 2);
    final arm = size.width * 0.32;

    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i * 3.141592653589793 / 2) + (t * 0.1));

      final slide = (i == 0)
          ? (t < 0.5 ? t * 2 * 12 : (1.0 - t) * 2 * 12)
          : 0.0;

      final p = Path();
      p.moveTo(0, 0);
      p.lineTo(arm + slide, 0);
      canvas.drawPath(p, stroke);

      final head = Path();
      head.moveTo(arm + slide + 8, 0);
      head.lineTo(arm + slide - 6, -7);
      head.lineTo(arm + slide - 6, 7);
      head.close();
      canvas.drawPath(head, fill);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedLogoPainter oldDelegate) => true;
}
