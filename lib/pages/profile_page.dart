import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nucleus/pages/homepage.dart';
import 'package:nucleus/pages/settings_page.dart';
import 'package:nucleus/widgets/side_nav.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  static const routeName = '/profile';

  void _nav(BuildContext context, NavItem to) {
    if (to == NavItem.profile) return;
    if (to == NavItem.home) {
      Navigator.of(context).pushNamedAndRemoveUntil(HomePage.routeName, (r) => false);
    } else if (to == NavItem.settings) {
      Navigator.of(context).pushReplacementNamed(SettingsPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Row(
        children: [
          SideNav(selected: NavItem.profile, onSelect: (i) => _nav(context, i)),
          Expanded(
            child: ColoredBox(
              color: cs.surface,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Profile', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 16),
                              _kv(context, 'Name', user?.displayName ?? '—'),
                              _kv(context, 'Email', user?.email ?? '—'),
                              _kv(context, 'UID', user?.uid ?? '—'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 180, child: Text(k, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(.7)))),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
