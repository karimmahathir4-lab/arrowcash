import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../data/progress_repository.dart';
import '../../data/settings_repository.dart';

class SettingsSheet extends StatefulWidget {
  final SettingsRepository settingsRepo;
  final ProgressRepository progressRepo;
  final VoidCallback onSettingsChanged;

  const SettingsSheet({
    super.key,
    required this.settingsRepo,
    required this.progressRepo,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool sound = true;
  bool music = true;
  bool haptics = true;
  bool darkMode = false;
  bool safeTap = false;
  bool gridAssist = false;
  bool reduceMotion = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await widget.settingsRepo.getSound();
    final m = await widget.settingsRepo.getMusic();
    final h = await widget.settingsRepo.getHaptics();
    final d = await widget.settingsRepo.getDarkMode();
    final st = await widget.settingsRepo.getSafeTap();
    final g = await widget.settingsRepo.getGridAssistDefault();
    final rm = await widget.settingsRepo.getReduceMotion();

    if (mounted) {
      setState(() {
        sound = s;
        music = m;
        haptics = h;
        darkMode = d;
        safeTap = st;
        gridAssist = g;
        reduceMotion = rm;
        loading = false;
      });
    }
  }

  void _onToggle(String key, bool val) async {
    setState(() {
      switch (key) {
        case 'sound':
          sound = val;
          AudioService.instance.soundEnabled = val;
          widget.settingsRepo.setSound(val);
          break;
        case 'music':
          music = val;
          AudioService.instance.musicEnabled = val;
          widget.settingsRepo.setMusic(val);
          break;
        case 'haptics':
          haptics = val;
          Haptics.enabled = val;
          widget.settingsRepo.setHaptics(val);
          break;
        case 'darkMode':
          darkMode = val;
          widget.settingsRepo.setDarkMode(val);
          break;
        case 'safeTap':
          safeTap = val;
          widget.settingsRepo.setSafeTap(val);
          break;
        case 'gridAssist':
          gridAssist = val;
          widget.settingsRepo.setGridAssistDefault(val);
          break;
        case 'reduceMotion':
          reduceMotion = val;
          widget.settingsRepo.setReduceMotion(val);
          break;
      }
    });
    widget.onSettingsChanged();
  }

  void _confirmResetProgress() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will reset your current level, hints, and challenge history back to Level 1. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.progressRepo.resetProgress();
              widget.onSettingsChanged();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress has been reset.')),
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: T.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = darkMode;
    final bg = isDark ? T.darkBg : Colors.white;
    final titleColor = isDark ? Colors.white : T.title;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              _buildSwitch(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects',
                value: sound,
                onChanged: (v) => _onToggle('sound', v),
                isDark: isDark,
              ),
              _buildSwitch(
                icon: Icons.music_note_rounded,
                title: 'Music',
                value: music,
                onChanged: (v) => _onToggle('music', v),
                isDark: isDark,
              ),
              _buildSwitch(
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                value: haptics,
                onChanged: (v) => _onToggle('haptics', v),
                isDark: isDark,
              ),
              _buildSwitch(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Theme',
                value: darkMode,
                onChanged: (v) => _onToggle('darkMode', v),
                isDark: isDark,
              ),
              _buildSwitch(
                icon: Icons.check_circle_outline_rounded,
                title: 'Safe Tap (Confirm selection)',
                value: safeTap,
                onChanged: (v) => _onToggle('safeTap', v),
                isDark: isDark,
              ),
              _buildSwitch(
                icon: Icons.grid_on_rounded,
                title: 'Grid Assist Default',
                value: gridAssist,
                onChanged: (v) => _onToggle('gridAssist', v),
                isDark: isDark,
              ),
              _buildSwitch(
                icon: Icons.motion_photos_off_rounded,
                title: 'Reduce Motion',
                value: reduceMotion,
                onChanged: (v) => _onToggle('reduceMotion', v),
                isDark: isDark,
              ),

              const SizedBox(height: 12),
              const Divider(height: 24),

              // Privacy Policy
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: T.accent,
                ),
                title: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: isDark ? Colors.white : T.title,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final uri = Uri.parse(
                    'https://handcraft-studios.blogspot.com/p/privacy-policy.html',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),

              // Reset progress
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: T.error,
                ),
                title: const Text(
                  'Reset Progress',
                  style: TextStyle(color: T.error, fontWeight: FontWeight.w600),
                ),
                onTap: _confirmResetProgress,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: T.accent),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : T.title,
        ),
      ),
      activeThumbColor: T.accent,
      value: value,
      onChanged: onChanged,
    );
  }
}
