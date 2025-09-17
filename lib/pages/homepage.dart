import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:nucleus/pages/product_detail_page.dart';
// ignore: unused_import
import 'package:nucleus/pages/product_edit_page.dart';
import 'package:nucleus/pages/profile_page.dart';
import 'package:nucleus/pages/settings_page.dart';
import 'package:nucleus/widgets/side_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  static const routeName = '/';

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
    return Scaffold(
      body: Row(
        children: [
          SideNav(selected: NavItem.home, onSelect: (i) => _nav(context, i)),
          const Expanded(child: _ContentArea()),
        ],
      ),
    );
  }
}

class _ContentArea extends StatefulWidget {
  const _ContentArea();
  @override
  State<_ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<_ContentArea> {
  static const List<String> _categories = <String>[
    'All Categories','Cyber Security','Data Center','Digital Transformation',
  ];
  static const List<String> _countries = <String>[
    'All','Sri Lanka','India','Bangladesh','Maldives','UAE','Singapore',
  ];

  String _selectedCategory = _categories.first;
  String _selectedCountry = _countries.first;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  String? _keyForCategory(String label) {
    final norm = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    switch (norm) {
      case 'cybersecurity': return 'cyber';
      case 'datacenter': return 'data-center';
      case 'digitaltransformation': return 'digital-transformation';
      default: return null;
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('products');
    final String? categoryKey = _keyForCategory(_selectedCategory);
    if (categoryKey != null) q = q.where('departmentKey', isEqualTo: categoryKey);
    if (_selectedCountry != 'All') q = q.where('countries', arrayContains: _selectedCountry);

    final s = _searchCtrl.text.trim().toLowerCase();
    if (s.isNotEmpty) {
      q = q.orderBy('nameLower').startAt([s]).endAt(['$s\uf8ff']);
    } else {
      q = q.orderBy('nameLower');
    }
    return q.limit(100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface, // themable background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + Add New
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search products, SKUs, suppliers...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/product/edit'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add New'),
                  ),
                ),
              ],
            ),
          ),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inventory', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Browse and manage products across your catalog.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium!.color!.withOpacity(.75))),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Filter by category'),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: const InputDecoration(labelText: 'Country'),
                    items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCountry = v ?? _selectedCountry),
                  ),
                ),
              ],
            ),
          ),

          // Results (grid)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                final docs = snap.data?.docs ?? const [];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int columns;
                    final w = constraints.maxWidth;
                    if (w >= 1400) columns = 4;
                    else if (w >= 1100) columns = 3;
                    else if (w >= 780) columns = 2;
                    else columns = 1;

                    if (docs.isEmpty) {
                      return const Center(child: Text('No products found'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.55,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final id = docs[i].id;
                        final name = (d['name'] ?? '').toString();
                        final departmentDisplay = (d['departmentDisplay'] ?? d['department'] ?? '').toString();
                        final departmentKey = (d['departmentKey'] ?? '').toString();
                        final segment = (d['segment'] ?? '').toString();
                        final agreement = (d['agreementType'] ?? '').toString();
                        final countries = (d['countries'] as List?)?.map((e) => e.toString()).cast<String>().toList() ?? const <String>[];

                        return _ProductCard(
                          productId: id,
                          title: name,
                          departmentDisplay: departmentDisplay,
                          departmentKey: departmentKey,
                          segment: segment,
                          agreement: agreement,
                          countries: countries,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final String title;
  final String departmentDisplay;
  final String departmentKey;
  final String segment;
  final String agreement;
  final List<String> countries;

  const _ProductCard({
    // ignore: unused_element_parameter
    super.key,
    required this.productId,
    required this.title,
    required this.departmentDisplay,
    required this.departmentKey,
    required this.segment,
    required this.agreement,
    required this.countries,
  });

  Color _chipBg(BuildContext context, String key) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (key) {
      case 'cyber': return dark ? const Color.fromARGB(255, 31, 17, 17) : const Color(0xFFE8EAF6);
      case 'data-center': return dark ? const Color.fromARGB(255, 17, 22, 31) : const Color(0xFFE6F1FF);
      case 'digital-transformation': return dark ? const Color.fromARGB(255, 20, 31, 22) : const Color(0xFFEFF7E8);
      default: return dark ? const Color.fromARGB(255, 31, 17, 17) : const Color(0xFFF0F2F7);
    }
  }
  Color _chipFg(BuildContext context, String key) {
    switch (key) {
      case 'cyber': return const Color.fromARGB(255, 195, 109, 109);
      case 'data-center': return const Color.fromARGB(255, 110, 139, 187);
      case 'digital-transformation': return const Color.fromARGB(255, 116, 161, 115);
      default: return const Color(0xFFBFC7D5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).pushNamed('/product', arguments: productId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? .35 : .06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + category chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _chipBg(context, departmentKey),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    departmentDisplay.isEmpty ? '—' : departmentDisplay,
                    style: TextStyle(
                      color: _chipFg(context, departmentKey),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (segment.isNotEmpty)
              Text(segment, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (agreement.isNotEmpty)
              Text('Agreement Status: $agreement', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(.8))),
            const Spacer(),
            if (countries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: countries.take(6).map((c) => Chip(label: Text(c))).toList(),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/product', arguments: productId),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Learn more'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
