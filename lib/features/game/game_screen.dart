import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_service.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../data/progress_repository.dart';
import '../../data/reward_service.dart';
import '../../data/settings_repository.dart';
import '../../game/controller/game_controller.dart';
import '../../game/controller/game_state.dart';
import '../../game/engine/hint_engine.dart';
import '../../game/generator/level_generator.dart';
import '../../game/models/arrow_piece.dart';
import '../../game/models/level.dart';
import '../complete/level_complete_screen.dart';
import '../failed/level_failed_dialog.dart';
import '../settings/settings_sheet.dart';
import 'widgets/board_view.dart';
import 'widgets/bottom_actions.dart';
import 'widgets/status_row.dart';
import 'widgets/top_bar.dart';
import 'widgets/tutorial_overlay.dart';

class GameScreen extends StatefulWidget {
  final int levelNumber;
  final bool isDaily;
  final String? dailyDate;
  final ProgressRepository progressRepo;
  final SettingsRepository settingsRepo;
  final RewardService rewardService;

  const GameScreen({
    super.key,
    required this.levelNumber,
    this.isDaily = false,
    this.dailyDate,
    required this.progressRepo,
    required this.settingsRepo,
    required this.rewardService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Level? _level;
  GameController? _controller;
  GameState? _state;
  final TransformationController _transformController =
      TransformationController();

  int _hints = 3;
  int _coins = 0;
  bool _isDark = false;
  bool _loading = true;
  bool _showTutorial = false;
  ArrowPiece? _tutorialArrow;
  ArrowThemeStyle _currentStyle = ArrowThemeStyle.classic;

  bool _showingWonModal = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelNumber != widget.levelNumber ||
        oldWidget.isDaily != widget.isDaily ||
        oldWidget.dailyDate != widget.dailyDate) {
      _initLevel();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _initLevel() async {
    _showingWonModal = false;
    setState(() => _loading = true);

    final h = await widget.progressRepo.getHints();
    final c = await widget.progressRepo.getCoins();
    final dark = await widget.settingsRepo.getDarkMode();
    final safe = await widget.settingsRepo.getSafeTap();
    final grid = await widget.settingsRepo.getGridAssistDefault();
    final rm = await widget.settingsRepo.getReduceMotion();
    final styleIdx = await widget.progressRepo.getArrowStyleIndex();
    final style = ArrowThemeStyle
        .values[styleIdx.clamp(0, ArrowThemeStyle.values.length - 1)];

    final lvl = await LevelGenerator.generateAsync(widget.levelNumber);

    // Pre-generate next level in background
    if (!widget.isDaily) {
      LevelGenerator.generateAsync(widget.levelNumber + 1);
    }

    _controller?.dispose();
    final ctrl = GameController(
      level: lvl,
      gridAssistDefault: grid,
      safeTapEnabled: safe,
      reduceMotion: rm,
      isDaily: widget.isDaily,
      dailyDate: widget.dailyDate,
      arrowStyle: style,
    );

    ctrl.addListener(() {
      if (!mounted) return;
      setState(() => _state = ctrl.state);
      if (ctrl.state.lives != _state?.lives) {
        widget.progressRepo.setSavedLives(ctrl.state.lives);
      }
      _checkGameStatus(ctrl.state);
    });

    // Check if user previously exhausted lives on this level
    final savedLives = await widget.progressRepo.getSavedLives();
    if (savedLives <= 0) {
      // Must restore via rewarded ad or restart after watching ad
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onLevelFailed();
      });
    }
    bool showTut = false;
    ArrowPiece? tutPiece;
    if (widget.levelNumber == 1 && !widget.isDaily) {
      final seen = await widget.progressRepo.getTutorialSeen(1);
      if (!seen) {
        tutPiece = HintEngine.chooseHint(ctrl.boardState);
        if (tutPiece != null) {
          showTut = true;
          ctrl.triggerHint();
        }
      }
    }

    if (mounted) {
      setState(() {
        _level = lvl;
        _controller = ctrl;
        _state = ctrl.state;
        _hints = h;
        _coins = c;
        _isDark = dark;
        _currentStyle = style;
        _showTutorial = showTut;
        _tutorialArrow = tutPiece;
        _loading = false;
      });
    }
  }

  void _checkGameStatus(GameState state) {
    if (state.status == GameStatus.won && !_showingWonModal) {
      _showingWonModal = true;
      _onLevelWon();
    } else if (state.status == GameStatus.failed) {
      _onLevelFailed();
    }
  }

  Future<void> _onLevelWon() async {
    const earnedCoins = 25;
    await widget.progressRepo.setSavedLives(3); // Reset lives on completion
    await widget.progressRepo.addCoins(earnedCoins);
    final updatedCoins = await widget.progressRepo.getCoins();
    if (mounted) {
      setState(() => _coins = updatedCoins);
    }

    if (widget.isDaily && widget.dailyDate != null) {
      await widget.progressRepo.markDailyCompleted(widget.dailyDate!);
      await widget.progressRepo.addHints(1);
      final dt = DateTime.parse(
        '${widget.dailyDate!.substring(0, 4)}-${widget.dailyDate!.substring(4, 6)}-${widget.dailyDate!.substring(6, 8)}',
      );
      final daysInMonth = DateTime(dt.year, dt.month + 1, 0).day;
      final completed = await widget.progressRepo.getCompletedDaily();
      final monthPrefix = widget.dailyDate!.substring(0, 6);
      final countInMonth = completed
          .where((d) => d.startsWith(monthPrefix))
          .length;
      if (countInMonth >= daysInMonth) {
        await widget.progressRepo.addTrophy(monthPrefix);
      }
    } else {
      if (widget.levelNumber == 1) {
        await widget.progressRepo.setTutorialSeen(1);
      }
      final current = await widget.progressRepo.getCurrentLevel();
      if (widget.levelNumber >= current) {
        await widget.progressRepo.setCurrentLevel(widget.levelNumber + 1);
      }
      if (widget.levelNumber % 5 == 0) {
        await widget.progressRepo.addHints(1);
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, _) => LevelCompleteScreen(
          level: _level!,
          earnedCoins: earnedCoins,
          onNewGame: () {
            // Show interstitial ad on level complete when PLAY button is clicked
            AdService.instance.showInterstitial();
            if (widget.isDaily) {
              Navigator.pop(context);
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
              context.go('/game/${widget.levelNumber + 1}');
            }
          },
          onMain: () {
            Navigator.pop(context);
            context.go('/');
          },
        ),
        transitionsBuilder: (context, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    _showingWonModal = false;
  }

  void _onLevelFailed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LevelFailedDialog(
        isDark: _isDark,
        rewardService: widget.rewardService,
        onTryAgain: () async {
          Navigator.pop(ctx);
          await widget.progressRepo.setSavedLives(3);
          _controller?.restartLevel();
        },
        onMain: () {
          Navigator.pop(ctx);
          context.go('/');
        },
        onContinueRewarded: () async {
          Navigator.pop(ctx);
          await widget.progressRepo.setSavedLives(3);
          _controller?.addLife();
          _controller?.addLife();
          _controller?.addLife();
        },
      ),
    );
  }

  void _onHintTap() async {
    if (_state?.hintedArrowId != null) return;

    if (_hints > 0) {
      final success = _controller?.triggerHint() ?? false;
      if (success) {
        await widget.progressRepo.addHints(-1);
        final newH = await widget.progressRepo.getHints();
        setState(() => _hints = newH);
      }
    } else {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: T.accent, size: 28),
              SizedBox(width: 8),
              Text(
                'Out of Hints',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: const Text(
            'You have 0 hints left. Watch a short video ad to get 2 free hints!',
            style: TextStyle(fontSize: 15, height: 1.3),
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
                    final newH = await widget.progressRepo.getHints();
                    if (!mounted) return;
                    setState(() => _hints = newH);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('+2 Hints added!')),
                    );
                    _controller?.triggerHint();
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
  }

  // Working Replay action
  void _onReplay() {
    AudioService.instance.play(Sfx.click);
    Haptics.light();
    AdService.instance.recordActionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart Level?'),
        content: const Text(
          'Reset this puzzle and start with fresh 3 lives and the same board?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: T.accent),
            onPressed: () {
              Navigator.pop(ctx);
              _controller?.restartLevel();
              _transformController.value = Matrix4.identity();
            },
            child: const Text('Restart', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Working Back button with proper confirmation
  void _onBack() {
    AudioService.instance.play(Sfx.click);
    Haptics.light();
    AdService.instance.recordActionClick();
    if (_state != null && _state!.remainingCount < _level!.arrows.length) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Leave Level?'),
          content: const Text('Your progress in this level will be reset.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Resume'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/');
              },
              child: const Text('Exit', style: TextStyle(color: T.error)),
            ),
          ],
        ),
      );
    } else {
      context.go('/');
    }
  }

  // Arrow Color Style Picker Sheet
  void _openStylePicker() {
    AudioService.instance.play(Sfx.click);
    Haptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: _isDark ? T.darkBg : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Arrow Color Style',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? Colors.white : T.title,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ArrowThemeStyle.values.map((style) {
                final isSelected = style == _currentStyle;
                return ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: style.primaryColor,
                    radius: 9,
                  ),
                  label: Text(
                    style.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (_isDark ? Colors.white70 : T.title),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: style.primaryColor,
                  backgroundColor: _isDark ? T.darkChipBg : T.chipBg,
                  onSelected: (selected) async {
                    if (selected) {
                      setState(() => _currentStyle = style);
                      _controller?.setArrowStyle(style);
                      await widget.progressRepo.setArrowStyleIndex(style.index);
                      AudioService.instance.play(Sfx.click);
                      Haptics.selection();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(
        settingsRepo: widget.settingsRepo,
        progressRepo: widget.progressRepo,
        onSettingsChanged: () async {
          final dark = await widget.settingsRepo.getDarkMode();
          setState(() => _isDark = dark);
        },
      ),
    );
  }

  String get _barTitle {
    if (widget.isDaily && widget.dailyDate != null) {
      final y = widget.dailyDate!.substring(0, 4);
      final m = widget.dailyDate!.substring(4, 6);
      final d = widget.dailyDate!.substring(6, 8);
      return '$d/$m/$y';
    }
    return 'Level ${widget.levelNumber}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _level == null || _state == null || _controller == null) {
      return Scaffold(
        backgroundColor: _isDark ? T.darkBg : T.bg,
        body: const Center(child: CircularProgressIndicator(color: T.accent)),
      );
    }

    final bg = _isDark ? T.darkBg : T.bg;

    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                TopBar(
                  title: _barTitle,
                  onBack: _onBack,
                  onReplay: _onReplay,
                  onSettings: _openSettings,
                  coins: _coins,
                  isDark: _isDark,
                ),
                StatusRow(
                  remaining: _state!.remainingCount,
                  lives: _state!.lives,
                  difficulty: _level!.difficulty,
                  isDark: _isDark,
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            BoardView(
                              state: _state!,
                              controller: _controller!,
                              isDark: _isDark,
                              transformController: _transformController,
                            ),
                            if (_showTutorial && _tutorialArrow != null)
                              TutorialOverlay(
                                level: _level!,
                                targetArrow: _tutorialArrow!,
                                onDismiss: () {
                                  setState(() => _showTutorial = false);
                                },
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < 700
                            ? 148
                            : 176,
                        child: Center(
                          child: BottomActions(
                            hintCount: _hints,
                            gridActive: _state!.gridAssist,
                            currentStyle: _currentStyle,
                            onHintTap: () {
                              AdService.instance.recordActionClick();
                              _onHintTap();
                            },
                            onGridToggle: () {
                              AdService.instance.recordActionClick();
                              _controller!.toggleGridAssist();
                            },
                            onStyleTap: () {
                              AdService.instance.recordActionClick();
                              _openStylePicker();
                            },
                            onResetZoomTap: () {
                              AdService.instance.recordActionClick();
                              Haptics.selection();
                              AudioService.instance.play(Sfx.click);
                              _transformController.value = Matrix4.identity();
                            },
                            isDark: _isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with working Back & Replay buttons & Coin indicator
              TopBar(
                title: _barTitle,
                onBack: _onBack,
                onReplay: _onReplay,
                onSettings: _openSettings,
                coins: _coins,
                isDark: _isDark,
              ),

              // Status Row (Arrows count, 3 hearts, Difficulty chip)
              StatusRow(
                remaining: _state!.remainingCount,
                lives: _state!.lives,
                difficulty: _level!.difficulty,
                isDark: _isDark,
              ),

              // Board area with pinch zoom guidance overlay
              Expanded(
                child: Stack(
                  children: [
                    BoardView(
                      state: _state!,
                      controller: _controller!,
                      isDark: _isDark,
                      transformController: _transformController,
                    ),

                    if (_showTutorial && _tutorialArrow != null)
                      TutorialOverlay(
                        level: _level!,
                        targetArrow: _tutorialArrow!,
                        onDismiss: () {
                          setState(() => _showTutorial = false);
                        },
                      ),
                  ],
                ),
              ),

              // Bottom Actions: Color Style, Hint, Grid Assist, Reset Zoom
              BottomActions(
                hintCount: _hints,
                gridActive: _state!.gridAssist,
                currentStyle: _currentStyle,
                onHintTap: () {
                  AdService.instance.recordActionClick();
                  _onHintTap();
                },
                onGridToggle: () {
                  AdService.instance.recordActionClick();
                  _controller!.toggleGridAssist();
                },
                onStyleTap: () {
                  AdService.instance.recordActionClick();
                  _openStylePicker();
                },
                onResetZoomTap: () {
                  AdService.instance.recordActionClick();
                  Haptics.selection();
                  AudioService.instance.play(Sfx.click);
                  _transformController.value = Matrix4.identity();
                },
                isDark: _isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
