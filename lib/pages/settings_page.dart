import 'package:flutter/material.dart';
import 'package:nucleus/pages/homepage.dart';
import 'package:nucleus/pages/profile_page.dart';
import 'package:nucleus/widgets/side_nav.dart';
import 'package:nucleus/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  static const routeName = '/settings';

  void _nav(BuildContext context, NavItem to) {
    if (to == NavItem.settings) return;
    if (to == NavItem.home) {
      Navigator.of(context).pushNamedAndRemoveUntil(HomePage.routeName, (r) => false);
    } else if (to == NavItem.profile) {
      Navigator.of(context).pushReplacementNamed(ProfilePage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final controller = ThemeControllerScope.of(context);
    final isDark = controller.mode == ThemeMode.dark;

    return Scaffold(
      body: Row(
        children: [
          SideNav(selected: NavItem.settings, onSelect: (i) => _nav(context, i)),
          Expanded(
            child: ColoredBox(
              color: cs.surface,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Appearance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Dark Mode'),
                                    subtitle: const Text('Use a dark, high-contrast theme'),
                                    value: isDark,
                                    onChanged: (v) => controller.toggle(v),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
