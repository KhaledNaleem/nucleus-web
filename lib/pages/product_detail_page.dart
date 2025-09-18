import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nucleus/pages/homepage.dart';
import 'package:nucleus/pages/profile_page.dart';
import 'package:nucleus/pages/settings_page.dart';
import 'package:nucleus/widgets/side_nav.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});
  static const routeName = '/product';

  final String productId;

  void _nav(BuildContext context, NavItem to) {
    if (to == NavItem.home) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(HomePage.routeName, (r) => false);
    } else if (to == NavItem.settings) {
      Navigator.of(context).pushReplacementNamed(SettingsPage.routeName);
    } else if (to == NavItem.profile) {
      Navigator.of(context).pushReplacementNamed(ProfilePage.routeName);
    }
  }

  // You already use custom claims in rules. This shows/hides Edit.
  Future<bool> _isAdmin() async {
    // ignore: unused_local_variable
    final user = FirebaseFirestore.instance.app.options.projectId; // dummy read avoids lint
    final result =
        await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
    final claims = result?.claims ?? {};
    return claims['role'] == 'admin' || claims['isAdmin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docRef =
        FirebaseFirestore.instance.collection('products').doc(productId);

    return Scaffold(
      body: Row(
        children: [
          SideNav(selected: NavItem.home, onSelect: (i) => _nav(context, i)),
          Expanded(
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: docRef.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (!snap.hasData || !snap.data!.exists) {
                      return const Center(child: Text('Product not found'));
                    }

                    final d = snap.data!.data()!;
                    final name = (d['name'] ?? '').toString();
                    final dept =
                        (d['departmentDisplay'] ?? d['department'] ?? '')
                            .toString();
                    final sku = (d['sku'] ?? '').toString();
                    final website = (d['website'] ?? '').toString();
                    final tagline = (d['tagline'] ?? '').toString();
                    final logoUrl = (d['logoUrl'] ?? '').toString();

                    // Product Information block (flat fields)
                    final category = (d['category'] ?? '').toString();
                    final vendor = (d['vendor'] ?? '').toString();
                    final licenseType = (d['licenseType'] ?? '').toString();
                    final supportLevel = (d['supportLevel'] ?? '').toString();

                    // Agreement block (nested)
                    final Map<String, dynamic>? agreement =
                        (d['agreement'] as Map?)?.cast<String, dynamic>();
                    final String contractStatus =
                        (agreement?['contractStatus'] ?? '').toString();
                    final String contractValue =
                        (agreement?['contractValue'] ?? '').toString();
                    final String paymentTerms =
                        (agreement?['paymentTerms'] ?? '').toString();
                    final dynamic renewalRaw = agreement?['renewalDate'];
                    final String renewalDate = _formatDateMaybe(renewalRaw);

                    // Usage block (nested)
                    final Map<String, dynamic>? usage =
                        (d['usage'] as Map?)?.cast<String, dynamic>();
                    final String activeUsers =
                        (usage?['activeUsers'] ?? '').toString();
                    final String deploymentStatus =
                        (usage?['deploymentStatus'] ?? '').toString();
                    final String implementationTimeline =
                        (usage?['implementationTimeline'] ?? '').toString();
                    final String trainingRequired =
                        (usage?['trainingRequired'] ?? '').toString();

                    // Recent Activity
                    final List<dynamic> recent =
                        (d['recentActivity'] as List?) ?? const [];
                    final recentItems = recent
                        .map((e) => (e as Map).cast<String, dynamic>())
                        .toList();

                    // Gartner timeline
                    final List<dynamic> gartner =
                        (d['gartner'] as List?) ?? const [];
                    final gartnerItems = gartner
                        .map((e) => (e as Map).cast<String, dynamic>())
                        .toList();

                    return LayoutBuilder(
                      builder: (context, c) {
                        final isMobile = c.maxWidth < 800;

                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                              isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- Top bar (Back) ---
                                  SizedBox(
                                    height: 44,
                                    child: TextButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                          Icons.arrow_back_rounded),
                                      label: const Text('Back to Inventory'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // --- Hero card ---
                                  _Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // logo (optional)
                                          if (logoUrl.isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                logoUrl,
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const SizedBox(width: 56),
                                              ),
                                            )
                                          else
                                            const SizedBox(width: 0),
                                          if (logoUrl.isNotEmpty)
                                            const SizedBox(width: 16),
                                          // Title block
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name.isEmpty
                                                      ? 'Untitled Product'
                                                      : name,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                if (sku.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text('SKU: $sku',
                                                      style: TextStyle(
                                                          color: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodyMedium!
                                                              .color!
                                                              .withOpacity(
                                                                  .7))),
                                                ],
                                                if (tagline.isNotEmpty) ...[
                                                  const SizedBox(height: 10),
                                                  Text(tagline,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium),
                                                ],
                                              ],
                                            ),
                                          ),

                                          // Right side actions
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: [
                                              if (website.isNotEmpty)
                                                SizedBox(
                                                  height: 40,
                                                  child: FilledButton.icon(
                                                    onPressed: () =>
                                                        _openWebsite(website),
                                                    icon: const Icon(
                                                        Icons.open_in_new),
                                                    label: const Text(
                                                        'Visit Website'),
                                                  ),
                                                ),
                                              FutureBuilder<bool>(
                                                future: _isAdmin(),
                                                builder: (context, s) {
                                                  final showEdit =
                                                      s.data == true;
                                                  if (!showEdit) {
                                                    return const SizedBox();
                                                  }
                                                  return SizedBox(
                                                    height: 40,
                                                    child: OutlinedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pushNamed(
                                                          '/product/edit',
                                                          arguments:
                                                              productId,
                                                        );
                                                      },
                                                      child:
                                                          const Text('Edit'),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- Two-column grids (collapse to 1 on mobile) ---
                                  _Grid(
                                    isMobile: isMobile,
                                    left: _Card(
                                      child: _Section(
                                        icon: Icons.view_in_ar_rounded,
                                        title: 'Product Information',
                                        children: [
                                          _kv(context, 'Category',
                                              _orDash(category)),
                                          _kv(context, 'Vendor',
                                              _orDash(vendor)),
                                          _kv(context, 'License Type',
                                              _orDash(licenseType)),
                                          _kv(context, 'Support Level',
                                              _orDash(supportLevel)),
                                          _kv(context, 'Department',
                                              _orDash(dept)),
                                        ],
                                      ),
                                    ),
                                    right: _Card(
                                      child: _Section(
                                        icon: Icons.shield_outlined,
                                        title: 'Agreement Details',
                                        children: [
                                          _kv(context, 'Contract Status',
                                              _orDash(contractStatus)),
                                          _kv(context, 'Renewal Date',
                                              _orDash(renewalDate)),
                                          _kv(context, 'Contract Value',
                                              _orDash(contractValue)),
                                          _kv(context, 'Payment Terms',
                                              _orDash(paymentTerms)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _Grid(
                                    isMobile: isMobile,
                                    left: _Card(
                                      child: _Section(
                                        icon: Icons.group_outlined,
                                        title: 'Usage & Deployment',
                                        children: [
                                          _kv(context, 'Active Users',
                                              _orDash(activeUsers)),
                                          _kv(context, 'Deployment Status',
                                              _orDash(deploymentStatus)),
                                          _kv(context, 'Implementation Timeline',
                                              _orDash(implementationTimeline)),
                                          _kv(context, 'Training Required',
                                              _orDash(trainingRequired)),
                                        ],
                                      ),
                                    ),
                                    right: _Card(
                                      child: _Section(
                                        icon: Icons.event_note_outlined,
                                        title: 'Recent Activity',
                                        children: [
                                          if (recentItems.isEmpty)
                                            const Text('—')
                                          else
                                            ...recentItems.map((item) {
                                              final date =
                                                  (item['date'] ?? '')
                                                      .toString();
                                              final title =
                                                  (item['title'] ?? '')
                                                      .toString();
                                              return _TimelineRow(
                                                title: title.isEmpty
                                                    ? '—'
                                                    : title,
                                                subtitle: date.isEmpty
                                                    ? null
                                                    : date,
                                              );
                                            }),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _Card(
                                    child: _Section(
                                      icon: Icons.grade_outlined,
                                      title: 'Gartner',
                                      children: [
                                        if (gartnerItems.isEmpty)
                                          const Text('—')
                                        else
                                          ...gartnerItems.map((g) {
                                            final int? year = g['year'] is int
                                                ? g['year'] as int
                                                : null;
                                            final String tier =
                                                (g['tier'] ?? '').toString();
                                            final String note =
                                                (g['note'] ?? '').toString();
                                            return _GartnerRow(
                                              year: year?.toString() ?? '—',
                                              tier: tier,
                                              note: note,
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers ---------------------------------------------------------------

  static String _formatDateMaybe(dynamic v) {
    if (v == null) return '';
    if (v is Timestamp) {
      final d = v.toDate();
      return '${_month(d.month)} ${d.day}, ${d.year}';
    }
    // string passthrough (importer keeps original if parsing failed)
    return v.toString();
  }

  static String _month(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return (m >= 1 && m <= 12) ? names[m - 1] : '';
  }

  static String _orDash(String s) => s.isEmpty ? '—' : s;

  Future<void> _openWebsite(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: Text(
                k,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .color!
                      .withOpacity(.7),
                ),
              ),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );
}

// UI bits -----------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? .35 : .06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: child,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary.withOpacity(.8)),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.isMobile, required this.left, required this.right});
  final bool isMobile;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 3, height: 24, color: cs.primary.withOpacity(.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(.7),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GartnerRow extends StatelessWidget {
  const _GartnerRow({required this.year, required this.tier, required this.note});
  final String year;
  final String tier;
  final String note;

  @override
  Widget build(BuildContext context) {
    final chipBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF14202A)
        : const Color(0xFFF0F2F7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // year badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: chipBg,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            alignment: Alignment.center,
            child: Text(year,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          if (tier.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(tier,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 12),
          Expanded(child: Text(note.isEmpty ? '—' : note)),
        ],
      ),
    );
  }
}
