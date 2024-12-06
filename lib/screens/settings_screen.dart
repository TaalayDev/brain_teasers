import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/common.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';

// Providers
final settingsProvider = StreamProvider<Map<String, String>>((ref) async* {
  final database = ref.watch(databaseProvider);
  final settings = await database.select(database.settings).get();
  yield Map.fromEntries(
    settings.map((s) => MapEntry(s.key, s.value)),
  );
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildSettingsList(context),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: CustomPaint(
            painter: SettingsPatternPainter(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Game Settings'),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingItem(
                  context,
                  title: 'Sound Effects',
                  icon: Icons.volume_up_rounded,
                  child: _buildSettingSwitch(context, 'sound_enabled'),
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  title: 'Background Music',
                  icon: Icons.music_note_rounded,
                  child: _buildSettingSwitch(context, 'music_enabled'),
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  title: 'Vibration',
                  icon: Icons.vibration_rounded,
                  child: _buildSettingSwitch(context, 'vibration_enabled'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Display'),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingItem(
                  context,
                  title: 'Theme Mode',
                  icon: Icons.palette_rounded,
                  child: _buildThemeModePicker(context),
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  title: 'Difficulty',
                  icon: Icons.trending_up_rounded,
                  child: _buildDifficultyPicker(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Data'),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingItem(
                  context,
                  title: 'Reset Progress',
                  icon: Icons.restart_alt_rounded,
                  child: _buildResetButton(context),
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  title: 'Clear Cache',
                  icon: Icons.cleaning_services_rounded,
                  child: _buildClearCacheButton(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'About'),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingItem(
                  context,
                  title: 'Version',
                  icon: Icons.info_outline_rounded,
                  child: Text(
                    '1.0.0',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                    ),
                  ),
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_rounded,
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
                _buildDivider(),
                _buildSettingItem(
                  context,
                  title: 'Terms of Service',
                  icon: Icons.description_rounded,
                  onTap: () {
                    // Navigate to terms of service
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                ),
              ),
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(BuildContext context, String settingKey) {
    return Consumer(
      builder: (context, ref, child) {
        final settingsAsync = ref.watch(settingsProvider);

        return settingsAsync.when(
          data: (settings) => Switch(
            value: settings[settingKey] == 'true',
            onChanged: (value) async {
              final database = ref.read(databaseProvider);
              await database.setSetting(settingKey, value.toString());
            },
          ),
          loading: () => const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.error_outline, color: Colors.red),
        );
      },
    );
  }

  Widget _buildThemeModePicker(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settingsAsync = ref.watch(settingsProvider);

        return settingsAsync.when(
          data: (settings) => DropdownButton<String>(
            value: settings['theme_mode'] ?? 'system',
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('System')),
              DropdownMenuItem(value: 'light', child: Text('Light')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
            ],
            onChanged: (value) async {
              if (value != null) {
                final database = ref.read(databaseProvider);
                await database.setSetting('theme_mode', value);
              }
            },
          ),
          loading: () => const CircularProgressIndicator(strokeWidth: 2),
          error: (_, __) => const Icon(Icons.error_outline, color: Colors.red),
        );
      },
    );
  }

  Widget _buildDifficultyPicker(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settingsAsync = ref.watch(settingsProvider);

        return settingsAsync.when(
          data: (settings) => DropdownButton<String>(
            value: settings['difficulty'] ?? 'normal',
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'easy', child: Text('Easy')),
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'hard', child: Text('Hard')),
            ],
            onChanged: (value) async {
              if (value != null) {
                final database = ref.read(databaseProvider);
                await database.setSetting('difficulty', value);
              }
            },
          ),
          loading: () => const CircularProgressIndicator(strokeWidth: 2),
          error: (_, __) => const Icon(Icons.error_outline, color: Colors.red),
        );
      },
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TextButton(
        onPressed: () => _showResetConfirmation(context, ref),
        child: const Text('Reset'),
      ),
    );
  }

  Widget _buildClearCacheButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TextButton(
        onPressed: () => _showClearCacheConfirmation(context, ref),
        child: const Text('Clear'),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Progress',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to reset all progress? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement reset logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cache',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to clear the app cache?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement cache clearing logic
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class SettingsPatternPainter extends CustomPainter {
  final Color color;

  SettingsPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    for (var i = 0.0; i < size.width + spacing; i += spacing) {
      for (var j = 0.0; j < size.height + spacing; j += spacing) {
        final path = Path()
          ..moveTo(i, j)
          ..lineTo(i + 10, j)
          ..moveTo(i, j)
          ..lineTo(i, j + 10);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
