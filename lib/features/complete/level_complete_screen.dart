import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../game/models/level.dart';
import 'mini_board_thumbnail.dart';

class LevelCompleteScreen extends StatefulWidget {
  final Level level;
  final int earnedCoins;
  final VoidCallback onNewGame;
  final VoidCallback onMain;

  const LevelCompleteScreen({
    super.key,
    required this.level,
    this.earnedCoins = 25,
    required this.onNewGame,
    required this.onMain,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _cardAnimController;
  late final AnimationController _coinAnimController;
  late final AnimationController _playPulseController;
  bool _playPressed = false;

  static const List<String> _headlines = [
    'Train Your Brain',
    'Nice Flow',
    'Sharp Mind',
    'Great Job',
    'Spectacular!',
  ];

  late final String _headline;

  @override
  void initState() {
    super.initState();
    _headline = _headlines[widget.level.number % _headlines.length];

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    )..play();

    // Clean, simple gentle fade & subtle scale-in for the completed level image
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // Coin collection animation
    _coinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Smooth breathing pulse animation for the Play button
    _playPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    AudioService.instance.play(Sfx.win);
    Haptics.medium();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cardAnimController.dispose();
    _coinAnimController.dispose();
    _playPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextLevelNumber = widget.level.number + 1;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [T.winTop, T.winBottom],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > constraints.maxHeight) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _headline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Level Completed!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 14),
                              AnimatedBuilder(
                                animation: _coinAnimController,
                                builder: (context, _) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    '+${(widget.earnedCoins * _coinAnimController.value).round()} Coins',
                                    style: const TextStyle(
                                      color: Color(0xFFD48800),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _cardAnimController,
                                curve: Curves.easeOut,
                              ),
                              child: MiniBoardThumbnail(
                                level: widget.level,
                                size: math.min(
                                  constraints.maxHeight * 0.62,
                                  220,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'UP NEXT: LEVEL $nextLevelNumber',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: math.min(
                                  constraints.maxWidth / 3 - 28,
                                  280,
                                ),
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: T.accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_playPressed) return;
                                    _playPressed = true;
                                    Haptics.light();
                                    widget.onNewGame();
                                  },
                                  child: const Text(
                                    'PLAY NEXT',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onMain,
                                child: const Text(
                                  'Main Menu',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top motivational headline and Completed title
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            _headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Level Completed!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Animated coin reward badge
                          AnimatedBuilder(
                            animation: _coinAnimController,
                            builder: (context, _) {
                              final t = CurvedAnimation(
                                parent: _coinAnimController,
                                curve: Curves.elasticOut,
                              ).value;
                              final displayedCoins =
                                  (widget.earnedCoins *
                                          _coinAnimController.value)
                                      .round();

                              return Transform.scale(
                                scale: 0.8 + 0.2 * t,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.monetization_on_rounded,
                                        color: Color(0xFFFFB800),
                                        size: 26,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+$displayedCoins Coins',
                                        style: const TextStyle(
                                          color: Color(0xFFD48800),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Solved board thumbnail card: Simple, smooth, elegant fade and subtle scale
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _cardAnimController,
                          curve: Curves.easeOut,
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _cardAnimController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: MiniBoardThumbnail(
                            level: widget.level,
                            size: math.min(
                              MediaQuery.of(context).size.width * 0.65,
                              260,
                            ),
                          ),
                        ),
                      ),

                      // Bottom action buttons and next level indicator
                      Column(
                        children: [
                          // Smooth animated level indicator
                          AnimatedBuilder(
                            animation: _playPulseController,
                            builder: (context, child) {
                              final pulse = _playPulseController.value;
                              return Transform.translate(
                                offset: Offset(0, -3.0 * pulse),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    'UP NEXT: LEVEL $nextLevelNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Smooth animated "PLAY" button with instant response on first tap
                          // Raised higher and smaller from sides per user request
                          AnimatedBuilder(
                            animation: _playPulseController,
                            builder: (context, child) {
                              final scale =
                                  1.0 + 0.03 * _playPulseController.value;
                              return Transform.scale(
                                scale: scale,
                                child: SizedBox(
                                  width: math.min(
                                    MediaQuery.of(context).size.width * 0.72,
                                    280.0,
                                  ),
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: T.accent,
                                      elevation: 8,
                                      shadowColor: Colors.black26,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (_playPressed) return;
                                      _playPressed = true;
                                      Haptics.light();
                                      widget.onNewGame();
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_arrow_rounded,
                                          size: 32,
                                          color: T.accent,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'PLAY',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                            color: T.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // "Main" text button link
                          TextButton(
                            onPressed: widget.onMain,
                            child: const Text(
                              'Main Menu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Confetti overlay falling from top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: T.confetti,
              numberOfParticles: 45,
              emissionFrequency: 0.06,
              gravity: 0.22,
            ),
          ),
        ],
      ),
    );
  }
}
