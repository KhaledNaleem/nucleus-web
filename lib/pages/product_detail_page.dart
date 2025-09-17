import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      Navigator.of(context).pushNamedAndRemoveUntil(HomePage.routeName, (r) => false);
    } else if (to == NavItem.settings) {
      Navigator.of(context).pushReplacementNamed(SettingsPage.routeName);
    } else if (to == NavItem.profile) {
      Navigator.of(context).pushReplacementNamed(ProfilePage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docRef = FirebaseFirestore.instance.collection('products').doc(productId);

    return Scaffold(
      body: Row(
        children: [
          SideNav(selected: NavItem.home, onSelect: (i) => _nav(context, i)),
          Expanded(
            child: ColoredBox(
              // was hardcoded light grey
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
                    final dept = (d['departmentDisplay'] ?? d['department'] ?? '').toString();
                    final sku = (d['sku'] ?? '').toString();
                    final segment = (d['segment'] ?? '').toString();
                    final agreement = (d['agreementType'] ?? '').toString();
                    final website = (d['website'] ?? '').toString();
                    final biz = (d['businessSize'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
                    final sales = (d['salesIncharge'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
                    final tech  = (d['technicalIncharge'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
                    final countries = (d['countries'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name.isEmpty ? 'Untitled Product' : name,
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 120, height: 40,
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Back'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 120, height: 40,
                                        child: FilledButton(
                                          onPressed: () {
                                            // ✅ matches main.dart
                                            Navigator.of(context).pushNamed(
                                              '/product/edit',
                                              arguments: productId,
                                            );
                                          },
                                          child: const Text('Edit'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Card
                              Container(
                                decoration: BoxDecoration(
                                  // was Colors.white
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  // add subtle border for dark/light parity
                                  border: Border.all(color: theme.dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        theme.brightness == Brightness.dark ? .35 : .06,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _kv(context, 'Department', dept.isEmpty ? '—' : dept),
                                    _kv(context, 'SKU', sku.isEmpty ? '—' : sku),
                                    _kv(context, 'Segment', segment.isNotEmpty ? segment : '—'),
                                    _kv(context, 'Agreement Status', agreement.isNotEmpty ? agreement : '—'),
                                    _kv(context, 'Website', website.isNotEmpty ? website : '—'),
                                    _kv(context, 'Business Size', biz.isEmpty ? '—' : biz.join(', ')),
                                    _kv(context, 'Sales Incharge', sales.isEmpty ? '—' : sales.join(', ')),
                                    _kv(context, 'Technical Incharge', tech.isEmpty ? '—' : tech.join(', ')),
                                    const SizedBox(height: 10),
                                    Text('Available Countries', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    if (countries.isEmpty)
                                      const Text('—')
                                    else
                                      Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: countries.map((c) => Chip(label: Text(c))).toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _kv(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            k,
            // was fixed black54
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(.7)),
          ),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
