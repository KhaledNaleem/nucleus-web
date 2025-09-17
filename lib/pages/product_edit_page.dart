import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nucleus/pages/homepage.dart';
import 'package:nucleus/pages/profile_page.dart';
import 'package:nucleus/pages/settings_page.dart';
import 'package:nucleus/widgets/side_nav.dart';

class ProductEditArgs {
  final String? productId; // null => Add New
  ProductEditArgs([this.productId]);
}

class ProductEditPage extends StatefulWidget {
  const ProductEditPage({super.key, this.productId});
  static const routeName = '/product/edit';

  final String? productId;

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();

  static const _departments = <String>['Cyber Security','Data Center','Digital Transformation'];
  static const _countries = <String>['Sri Lanka','India','Bangladesh','Maldives','UAE','Singapore'];

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _segmentCtrl = TextEditingController();
  final _agreementCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();
  final _techCtrl = TextEditingController();

  String? _departmentDisplay;
  String _principalInvolvement = 'None';
  final Set<String> _countriesSelected = {};
  bool _bizEnt = false, _bizMid = false, _bizSmall = false;

  bool _loading = false;

  String _deptKeyFor(String? display) {
    final s = (display ?? '').toLowerCase().replaceAll(' ', '');
    if (s == 'cybersecurity') return 'cyber';
    if (s == 'datacenter') return 'data-center';
    if (s == 'digitaltransformation') return 'digital-transformation';
    return 'other';
  }

  List<String> _prefixes(String name) {
    final v = name.toLowerCase();
    return [for (var i = 1; i <= (v.length < 20 ? v.length : 20); i++) v.substring(0, i)];
  }

  Map<String, String> _availabilityFromCountries(Iterable<String> countries) {
    final set = countries.toSet();
    return {for (final c in _countries) c: set.contains(c) ? 'Yes' : 'No'};
  }

  List<String> _splitList(String raw) =>
      raw.split(RegExp(r'[,&]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _loadIfEditing() async {
    if (widget.productId == null) return;
    final doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    if (!doc.exists) return;

    final d = doc.data()!;
    _nameCtrl.text = (d['name'] ?? '') as String;
    _skuCtrl.text = (d['sku'] ?? '') as String;
    _segmentCtrl.text = (d['segment'] ?? '') as String;
    _agreementCtrl.text = (d['agreementType'] ?? '') as String;
    _websiteCtrl.text = (d['website'] ?? '') as String;
    _departmentDisplay = (d['departmentDisplay'] ?? d['department'] ?? '') as String;

    final biz = (d['businessSize'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    _bizEnt = biz.contains('Ent');
    _bizMid = biz.contains('Mid');
    _bizSmall = biz.contains('Small');

    _principalInvolvement = (d['principalInvolvement'] ?? 'None') as String;

    final sales = (d['salesIncharge'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final tech  = (d['technicalIncharge'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    _salesCtrl.text = sales.join(', ');
    _techCtrl.text = tech.join(', ');

    final countries = (d['countries'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    _countriesSelected..clear()..addAll(countries);

    if (mounted) setState(() {});
  }

  @override
  void initState() { super.initState(); _loadIfEditing(); }

  @override
  void dispose() {
    _nameCtrl.dispose(); _skuCtrl.dispose(); _segmentCtrl.dispose();
    _agreementCtrl.dispose(); _websiteCtrl.dispose();
    _salesCtrl.dispose(); _techCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final f = _formKey.currentState;
    if (f == null || !f.validate()) return;
    setState(() => _loading = true);

    final name = _nameCtrl.text.trim();
    final departmentDisplay = _departmentDisplay ?? '';
    final departmentKey = _deptKeyFor(departmentDisplay);

    final doc = <String, dynamic>{
      'name': name,
      'sku': _skuCtrl.text.trim(),
      'departmentDisplay': departmentDisplay,
      'departmentKey': departmentKey,
      'segment': _segmentCtrl.text.trim(),
      'agreementType': _agreementCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'businessSize': [if (_bizEnt) 'Ent', if (_bizMid) 'Mid', if (_bizSmall) 'Small'],
      'salesIncharge': _splitList(_salesCtrl.text),
      'technicalIncharge': _splitList(_techCtrl.text),
      'principalInvolvement': _principalInvolvement,
      'countries': _countriesSelected.toList(),
      'availability': _availabilityFromCountries(_countriesSelected),
      'nameLower': name.toLowerCase(),
      'namePrefixes': _prefixes(name),
      'updatedAt': FieldValue.serverTimestamp(),
      if (widget.productId == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final col = FirebaseFirestore.instance.collection('products');
      if (widget.productId == null) {
        await col.add(doc);
      } else {
        await col.doc(widget.productId).set(doc, SetOptions(merge: true));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productId == null ? 'Product created' : 'Product saved')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.productId == null) return;
    final approve = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This will permanently remove this product document.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (approve != true) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cancel() => Navigator.of(context).maybePop();

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

    return Scaffold(
      body: Row(
        children: [
          SideNav(selected: NavItem.home, onSelect: (i) => _nav(context, i)),
          Expanded(
            child: ColoredBox(
              // was hardcoded light grey
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.productId == null ? 'Add New Product' : 'Edit Product',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.productId != null) ...[
                                    SizedBox(
                                      width: 110, height: 40,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: BorderSide(color: Colors.red.shade300),
                                        ),
                                        onPressed: _loading ? null : _confirmDelete,
                                        child: const Text('Delete'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  SizedBox(
                                    width: 120, height: 40,
                                    child: OutlinedButton(
                                      onPressed: _loading ? null : _cancel,
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 160, height: 40,
                                    child: FilledButton(
                                      onPressed: _loading ? null : _save,
                                      child: _loading
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Card + form
                          Container(
                            decoration: BoxDecoration(
                              // was Colors.white
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
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
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LayoutBuilder(builder: (context, c) {
                                    final wide = c.maxWidth >= 900;
                                    return Wrap(
                                      spacing: 18, runSpacing: 16,
                                      children: [
                                        _w(width: wide ? 480 : c.maxWidth, child: _Labeled('Product Name',
                                          TextFormField(controller: _nameCtrl, textInputAction: TextInputAction.next,
                                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null))),
                                        _w(width: wide ? 280 : c.maxWidth, child: _Labeled('SKU',
                                          TextFormField(controller: _skuCtrl, textInputAction: TextInputAction.next))),
                                        _w(width: wide ? 300 : c.maxWidth, child: _Labeled('Department',
                                          DropdownButtonFormField<String>(
                                            value: _departmentDisplay,
                                            items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                            onChanged: (v) => setState(() => _departmentDisplay = v),
                                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                          ))),
                                        _w(width: wide ? 360 : c.maxWidth, child: _Labeled('Segment',
                                          TextFormField(controller: _segmentCtrl, textInputAction: TextInputAction.next))),
                                        _w(width: wide ? 260 : c.maxWidth, child: _Labeled('Agreement Status',
                                          TextFormField(controller: _agreementCtrl, textInputAction: TextInputAction.next))),
                                        _w(width: wide ? 420 : c.maxWidth, child: _Labeled('Website',
                                          TextFormField(controller: _websiteCtrl, keyboardType: TextInputType.url))),
                                      ],
                                    );
                                  }),
                                  const SizedBox(height: 10),

                                  _SectionTitle('Business Size'),
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      FilterChip(label: const Text('Ent'), selected: _bizEnt, onSelected: (v) => setState(() => _bizEnt = v)),
                                      FilterChip(label: const Text('Mid'), selected: _bizMid, onSelected: (v) => setState(() => _bizMid = v)),
                                      FilterChip(label: const Text('Small'), selected: _bizSmall, onSelected: (v) => setState(() => _bizSmall = v)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  _SectionTitle('Available Countries'),
                                  Wrap(
                                    spacing: 10, runSpacing: 10,
                                    children: _countries.map((c) => FilterChip(
                                      label: Text(c),
                                      selected: _countriesSelected.contains(c),
                                      onSelected: (v) => setState(() => v ? _countriesSelected.add(c) : _countriesSelected.remove(c)),
                                    )).toList(),
                                  ),
                                  const SizedBox(height: 16),

                                  _SectionTitle('Ownership & Contacts'),
                                  LayoutBuilder(builder: (context, c) {
                                    final wide = c.maxWidth >= 900;
                                    return Wrap(
                                      spacing: 18, runSpacing: 16,
                                      children: [
                                        _w(width: wide ? 420 : c.maxWidth, child: _Labeled(
                                          'Sales Incharge (comma separated)', TextFormField(controller: _salesCtrl))),
                                        _w(width: wide ? 420 : c.maxWidth, child: _Labeled(
                                          'Technical Incharge (comma separated)', TextFormField(controller: _techCtrl))),
                                        _w(width: wide ? 260 : c.maxWidth, child: _Labeled(
                                          'Principal Involvement',
                                          DropdownButtonFormField<String>(
                                            initialValue: _principalInvolvement,
                                            items: const [
                                              DropdownMenuItem(value: 'None', child: Text('None')),
                                              DropdownMenuItem(value: 'Low', child: Text('Low')),
                                              DropdownMenuItem(value: 'High', child: Text('High')),
                                            ],
                                            onChanged: (v) => setState(() => _principalInvolvement = v ?? 'None'),
                                          ),
                                        )),
                                      ],
                                    );
                                  }),

                                  const SizedBox(height: 18),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.productId != null) ...[
                                        SizedBox(
                                          width: 110, height: 40,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: BorderSide(color: Colors.red.shade300),
                                            ),
                                            onPressed: _loading ? null : _confirmDelete,
                                            child: const Text('Delete'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      SizedBox(
                                        width: 120, height: 40,
                                        child: OutlinedButton(
                                          onPressed: _loading ? null : _cancel,
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 170, height: 40,
                                        child: FilledButton(
                                          onPressed: _loading ? null : _save,
                                          child: _loading
                                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Text('Save Changes'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
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

  Widget _w({required double width, required Widget child}) => SizedBox(width: width, child: child);
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);
  final String label; final Widget child;
  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 10),
        child: Text(text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      );
}
