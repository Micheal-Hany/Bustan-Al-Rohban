import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/strings.dart';
import '../../app/theme/app_icons.dart';
import '../../app/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final main = <({String key, String title, IconData icon, String path})>[
      (
        key: 'nav-library',
        title: AppStrings.library,
        icon: AppIcons.library,
        path: AppRoutes.library
      ),
      (
        key: 'nav-search',
        title: AppStrings.search,
        icon: AppIcons.search,
        path: AppRoutes.search
      ),
      (
        key: 'nav-bookmarks',
        title: AppStrings.bookmarks,
        icon: AppIcons.bookmarkOn,
        path: AppRoutes.bookmarks
      ),
      (
        key: 'nav-chat',
        title: AppStrings.chat,
        icon: AppIcons.chat,
        path: AppRoutes.chat
      ),
      (
        key: 'nav-settings',
        title: AppStrings.settings,
        icon: AppIcons.settings,
        path: AppRoutes.settings
      ),
    ];
    final debug = <({String key, String title, IconData icon, String path})>[
      if (kDebugMode)
        (
          key: 'nav-content-preview',
          title: AppStrings.contentPreview,
          icon: AppIcons.preview,
          path: AppRoutes.contentPreview
        ),
      if (kDebugMode)
        (
          key: 'nav-tts-spike',
          title: AppStrings.ttsSpike,
          icon: AppIcons.voice,
          path: AppRoutes.ttsSpike
        ),
    ];

    return Scaffold(
      key: const Key('home-screen'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _Hero(),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                for (final e in main)
                  _FeatureTile(
                    key: Key(e.key),
                    title: e.title,
                    icon: e.icon,
                    onTap: () => context.push(e.path),
                  ),
              ],
            ),
            for (final e in debug)
              Card(
                child: ListTile(
                  key: Key(e.key),
                  leading: Icon(e.icon),
                  title: Text(e.title),
                  onTap: () => context.push(e.path),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? AppTheme.heroDark : AppTheme.heroLight,
        ),
        border: dark
            ? Border.all(color: const Color(0x66E2B965))
            : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x33E2B965) : const Color(0x4D5B3A29),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _SanctuaryPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 150, 24, 28),
            child: Column(
              children: [
                const Text(
                  AppStrings.appTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bookFontFamily,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldBright,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.homeTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('hero-start'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.goldBright,
                    foregroundColor: AppTheme.ink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 44, vertical: 14),
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.library),
                  child: const Text(AppStrings.startNow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Original line-art: a glowing halo, a dome-and-arch sanctuary and a cross.
class _SanctuaryPainter extends CustomPainter {
  const _SanctuaryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x66E2B965), Color(0x00E2B965)],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, 80), radius: size.width * 0.55));
    canvas.drawCircle(Offset(cx, 80), size.width * 0.55, glow);

    final line = Paint()
      ..color = const Color(0xCCE2B965)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // cross
    canvas.drawLine(Offset(cx, 14), Offset(cx, 56), line);
    canvas.drawLine(Offset(cx - 14, 30), Offset(cx + 14, 30), line);
    // dome
    final dome = Rect.fromCenter(center: Offset(cx, 98), width: 84, height: 84);
    canvas.drawArc(dome, 3.14159, 3.14159, false, line);
    // base + arch door
    canvas.drawLine(Offset(cx - 60, 140), Offset(cx + 60, 140), line);
    canvas.drawLine(Offset(cx - 42, 98), Offset(cx - 42, 140), line);
    canvas.drawLine(Offset(cx + 42, 98), Offset(cx + 42, 140), line);
    final door = Rect.fromCenter(center: Offset(cx, 124), width: 26, height: 32);
    canvas.drawArc(door, 3.14159, 3.14159, false, line);
    canvas.drawLine(Offset(cx - 13, 124), Offset(cx - 13, 140), line);
    canvas.drawLine(Offset(cx + 13, 124), Offset(cx + 13, 140), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BustanColors.of(context);
    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.quoteSurface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border, width: 1.4),
              ),
              child: Icon(icon, color: colors.accent, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
