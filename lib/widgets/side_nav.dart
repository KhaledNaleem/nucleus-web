import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NavItem { home, settings, profile }

class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final NavItem selected;
  final void Function(NavItem) onSelect;

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Go to AuthGate -> will show LoginPage when signed out
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return Container(
      width: 232,
      // was hardcoded white
      color: theme.canvasColor,
      child: Column(
        children: [
          // Brand header
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'EGUARDIAN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurface),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          // Nav list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavTile(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: selected == NavItem.home,
                  onTap: () => onSelect(NavItem.home),
                ),
                _NavTile(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: selected == NavItem.settings,
                  onTap: () => onSelect(NavItem.settings),
                ),
                _NavTile(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: selected == NavItem.profile,
                  onTap: () => onSelect(NavItem.profile),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Footer: Logout action
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _handleLogout(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('v1.0', style: TextStyle(color: onSurface.withOpacity(.6), fontSize: 12)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? colorScheme.primary.withOpacity(.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: onSurface),
        title: Text(label, style: TextStyle(color: onSurface)),
        onTap: onTap,
      ),
    );
  }
}
