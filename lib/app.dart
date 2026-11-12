import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'data/progress_repository.dart';
import 'data/reward_service.dart';
import 'data/settings_repository.dart';
import 'features/daily/daily_screen.dart';
import 'features/daily/trophies_screen.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';

class ArrowApp extends StatelessWidget {
  final ProgressRepository progressRepo;
  final SettingsRepository settingsRepo;
  final RewardService rewardService;

  const ArrowApp({
    super.key,
    required this.progressRepo,
    required this.settingsRepo,
    required this.rewardService,
  });

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(
            progressRepo: progressRepo,
            settingsRepo: settingsRepo,
            rewardService: rewardService,
          ),
        ),
        GoRoute(
          path: '/game/:n',
          builder: (context, state) {
            final nStr = state.pathParameters['n'] ?? '1';
            final n = int.tryParse(nStr) ?? 1;
            return GameScreen(
              key: ValueKey('game_$n'),
              levelNumber: n,
              progressRepo: progressRepo,
              settingsRepo: settingsRepo,
              rewardService: rewardService,
            );
          },
        ),
        GoRoute(
          path: '/daily',
          builder: (context, state) => DailyScreen(
            progressRepo: progressRepo,
            settingsRepo: settingsRepo,
          ),
        ),
        GoRoute(
          path: '/daily/:date',
          builder: (context, state) {
            final dateStr = state.pathParameters['date'] ?? '20261111';
            final seed = dateStr.hashCode.abs() % 10000 + 1;
            return GameScreen(
              levelNumber: seed,
              isDaily: true,
              dailyDate: dateStr,
              progressRepo: progressRepo,
              settingsRepo: settingsRepo,
              rewardService: rewardService,
            );
          },
        ),
        GoRoute(
          path: '/trophies',
          builder: (context, state) => TrophiesScreen(
            progressRepo: progressRepo,
            settingsRepo: settingsRepo,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Arrow Cash Clear Rush',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
