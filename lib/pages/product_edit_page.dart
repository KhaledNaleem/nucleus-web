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

  static const _departments = <String>[
    'Cyber Security','Data Center','Digital Transformation'
  ];
  static const _countries = <String>[
    'Sri Lanka','India','Bangladesh','Maldives','UAE','Singapore'
  ];

  // ---- Basics (existing) ----
  final _nameCtrl     = TextEditingController();
  final _skuCtrl      = TextEditingController();
  final _segmentCtrl  = TextEditingController();
  final _agreementCtrl= TextEditingController(); // legacy text (kept)
  final _websiteCtrl  = TextEditingController();
  final _salesCtrl    = TextEditingController();
  final _techCtrl     = TextEditingController();

  String? _departmentDisplay;
  String _principalInvolvement = 'None';
  final Set<String> _countriesSelected = {};
  bool _bizEnt = false, _bizMid = false, _bizSmall = false;

  // ---- Product Information (new) ----
  final _categoryCtrl     = TextEditingController();
  final _vendorCtrl       = TextEditingController();
  final _licenseTypeCtrl  = TextEditingController();
  final _supportLevelCtrl = TextEditingController();

  // ---- Agreement (new) ----
  final _contractStatusCtrl = TextEditingController();
  final _contractValueCtrl  = TextEditingController();
  final _paymentTermsCtrl   = TextEditingController();
  Timestamp? _renewalDate;

  // ---- Usage (new) ----
  final _activeUsersCtrl          = TextEditingController();
  final _deploymentStatusCtrl     = TextEditingController();
  final _implementationTimelineCtrl = TextEditingController();
  final _trainingRequiredCtrl     = TextEditingController();

  // ---- Recent Activity (new: list editor) ----
  final List<_KVRow> _recent = [];

  // ---- Gartner (new: list editor) ----
  final List<_GartnerRowModel> _gartner = [];

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

    // Basics
    _nameCtrl.text      = (d['name'] ?? '') as String;
    _skuCtrl.text       = (d['sku'] ?? '') as String;
    _segmentCtrl.text   = (d['segment'] ?? '') as String;
    _agreementCtrl.text = (d['agreementType'] ?? '') as String; // legacy
    _websiteCtrl.text   = (d['website'] ?? '') as String;
    _departmentDisplay  = (d['departmentDisplay'] ?? d['department'] ?? '') as String;

    final biz = (d['businessSize'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    _bizEnt = biz.contains('Ent');
    _bizMid = biz.contains('Mid');
    _bizSmall = biz.contains('Small');

    _principalInvolvement = (d['principalInvolvement'] ?? 'None') as String;

    final sales = (d['salesIncharge'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final tech  = (d['technicalIncharge'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    _salesCtrl.text = sales.join(', ');
    _techCtrl.text  = tech.join(', ');

    final countries = (d['countries'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    _countriesSelected..clear()..addAll(countries);

    // Product Information
    _categoryCtrl.text     = (d['category'] ?? '').toString();
    _vendorCtrl.text       = (d['vendor'] ?? '').toString();
    _licenseTypeCtrl.text  = (d['licenseType'] ?? '').toString();
    _supportLevelCtrl.text = (d['supportLevel'] ?? '').toString();

    // Agreement
    final Map<String, dynamic>? agreement = (d['agreement'] as Map?)?.cast<String, dynamic>();
    if (agreement != null) {
      _contractStatusCtrl.text = (agreement['contractStatus'] ?? '').toString();
      _contractValueCtrl.text  = (agreement['contractValue'] ?? '').toString();
      _paymentTermsCtrl.text   = (agreement['paymentTerms'] ?? '').toString();
      final rd = agreement['renewalDate'];
      if (rd is Timestamp) _renewalDate = rd;
    }

    // Usage
    final Map<String, dynamic>? usage = (d['usage'] as Map?)?.cast<String, dynamic>();
    if (usage != null) {
      _activeUsersCtrl.text = (usage['activeUsers'] ?? '').toString();
      _deploymentStatusCtrl.text = (usage['deploymentStatus'] ?? '').toString();
      _implementationTimelineCtrl.text = (usage['implementationTimeline'] ?? '').toString();
      _trainingRequiredCtrl.text = (usage['trainingRequired'] ?? '').toString();
    }

    // Recent Activity
    final List<dynamic> rec = (d['recentActivity'] as List?) ?? const [];
    _recent.clear();
    for (final e in rec) {
      final m = (e as Map).cast<String, dynamic>();
      _recent.add(_KVRow(
        dateCtrl: TextEditingController(text: (m['date'] ?? '').toString()),
        titleCtrl: TextEditingController(text: (m['title'] ?? '').toString()),
      ));
    }

    // Gartner
    final List<dynamic> ga = (d['gartner'] as List?) ?? const [];
    _gartner.clear();
    for (final e in ga) {
      final m = (e as Map).cast<String, dynamic>();
      _gartner.add(_GartnerRowModel(
        yearCtrl: TextEditingController(text: (m['year']?.toString() ?? '')),
        tierCtrl: TextEditingController(text: (m['tier'] ?? '').toString()),
        noteCtrl: TextEditingController(text: (m['note'] ?? '').toString()),
      ));
    }

    if (mounted) setState(() {});
  }

  @override
  void initState() { super.initState(); _loadIfEditing(); }

  @override
  void dispose() {
    // Basics
    _nameCtrl.dispose(); _skuCtrl.dispose(); _segmentCtrl.dispose();
    _agreementCtrl.dispose(); _websiteCtrl.dispose();
    _salesCtrl.dispose(); _techCtrl.dispose();
    // Product info
    _categoryCtrl.dispose(); _vendorCtrl.dispose();
    _licenseTypeCtrl.dispose(); _supportLevelCtrl.dispose();
    // Agreement
    _contractStatusCtrl.dispose(); _contractValueCtrl.dispose(); _paymentTermsCtrl.dispose();
    // Usage
    _activeUsersCtrl.dispose(); _deploymentStatusCtrl.dispose();
    _implementationTimelineCtrl.dispose(); _trainingRequiredCtrl.dispose();
    // Lists
    for (final r in _recent) { r.dispose(); }
    for (final g in _gartner) { g.dispose(); }
    super.dispose();
  }

  // ---------- Save helpers ----------

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('products');

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col.doc(id);

  Future<void> _updatePartial(Map<String, dynamic> data) async {
    if (widget.productId == null) {
      // If creating, first create doc with basics minimal name
      final baseName = _nameCtrl.text.trim();
      if (baseName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter Product Name before saving a section.')),
        );
        return;
      }
      final createData = {
        'name': baseName,
        'nameLower': baseName.toLowerCase(),
        'namePrefixes': _prefixes(baseName),
        'createdAt': FieldValue.serverTimestamp(),
        ...data,
      };
      final ref = await _col.add(createData);
      if (mounted) {
        setState(() { /* lock id for further edits */ });
        Navigator.of(context).pushReplacementNamed(
          ProductEditPage.routeName,
          arguments: ref.id,
        );
      }
      return;
    }
    await _doc(widget.productId!).set(data, SetOptions(merge: true));
  }

  Future<void> _saveBasics() async {
    final f = _formKey.currentState;
    if (f == null || !f.validate()) return;
    setState(() => _loading = true);

    final name = _nameCtrl.text.trim();
    final departmentDisplay = _departmentDisplay ?? '';
    final departmentKey = _deptKeyFor(departmentDisplay);

    final data = <String, dynamic>{
      'name': name,
      'sku': _skuCtrl.text.trim(),
      'departmentDisplay': departmentDisplay,
      'departmentKey': departmentKey,
      'segment': _segmentCtrl.text.trim(),
      'agreementType': _agreementCtrl.text.trim(), // legacy/free text
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
    };

    try {
      await _updatePartial(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Basics saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProductInfo() async {
    final data = {
      'category': _categoryCtrl.text.trim(),
      'vendor': _vendorCtrl.text.trim(),
      'licenseType': _licenseTypeCtrl.text.trim(),
      'supportLevel': _supportLevelCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => (v is String && v.isEmpty));
    try {
      await _updatePartial(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Information saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _saveAgreement() async {
    final Map<String, dynamic> agreement = {
      'contractStatus': _contractStatusCtrl.text.trim(),
      'contractValue': _contractValueCtrl.text.trim(),
      'paymentTerms': _paymentTermsCtrl.text.trim(),
      if (_renewalDate != null) 'renewalDate': _renewalDate,
    }..removeWhere((k, v) => (v is String && v.isEmpty));

    final data = {
      'agreement': agreement.isEmpty ? FieldValue.delete() : agreement,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _updatePartial(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agreement Details saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _saveUsage() async {
    final Map<String, dynamic> usage = {
      'activeUsers': _activeUsersCtrl.text.trim(),
      'deploymentStatus': _deploymentStatusCtrl.text.trim(),
      'implementationTimeline': _implementationTimelineCtrl.text.trim(),
      'trainingRequired': _trainingRequiredCtrl.text.trim(),
    }..removeWhere((k, v) => (v is String && v.isEmpty));

    final data = {
      'usage': usage.isEmpty ? FieldValue.delete() : usage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _updatePartial(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usage & Deployment saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _saveRecent() async {
    final list = _recent
        .map((r) => {
              'date': r.dateCtrl.text.trim(),
              'title': r.titleCtrl.text.trim(),
            })
        .where((m) => (m['date'] as String).isNotEmpty || (m['title'] as String).isNotEmpty)
        .toList();

    final data = {
      if (list.isEmpty) 'recentActivity': FieldValue.delete() else 'recentActivity': list,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _updatePartial(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recent Activity saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _saveGartner() async {
    final list = _gartner
        .map((g) {
          final yearStr = g.yearCtrl.text.trim();
          final year = int.tryParse(yearStr);
          return {
            if (year != null) 'year': year,
            'tier': g.tierCtrl.text.trim(),
            'note': g.noteCtrl.text.trim(),
          };
        })
        .where((m) =>
            m.containsKey('year') || (m['tier'] as String).isNotEmpty || (m['note'] as String).isNotEmpty)
        .toList();

    final data = {
      if (list.isEmpty) 'gartner': FieldValue.delete() else 'gartner': list,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _updatePartial(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gartner timeline saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
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
      await _doc(widget.productId!).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
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

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          SideNav(selected: NavItem.home, onSelect: (i) => _nav(context, i)),
          Expanded(
            child: ColoredBox(
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
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // --------- Basics & Catalog (existing fields) ----------
                          _Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Basics & Catalog',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 14),
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

                                          _w(width: wide ? 260 : c.maxWidth, child: _Labeled('Agreement Status (legacy, optional)',
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
                                              value: _principalInvolvement,
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

                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        width: 170, height: 40,
                                        child: FilledButton(
                                          onPressed: _loading ? null : _saveBasics,
                                          child: _loading
                                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Text('Save Basics'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --------- Product Information ----------
                          _Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Product Information',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  LayoutBuilder(builder: (context, c) {
                                    final wide = c.maxWidth >= 900;
                                    return Wrap(
                                      spacing: 18, runSpacing: 16,
                                      children: [
                                        _w(width: wide ? 360 : c.maxWidth, child: _Labeled('Category',
                                          TextFormField(controller: _categoryCtrl))),
                                        _w(width: wide ? 360 : c.maxWidth, child: _Labeled('Vendor',
                                          TextFormField(controller: _vendorCtrl))),
                                        _w(width: wide ? 320 : c.maxWidth, child: _Labeled('License Type',
                                          TextFormField(controller: _licenseTypeCtrl))),
                                        _w(width: wide ? 320 : c.maxWidth, child: _Labeled('Support Level',
                                          TextFormField(controller: _supportLevelCtrl))),
                                      ],
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 180, height: 40,
                                      child: FilledButton(
                                        onPressed: _saveProductInfo,
                                        child: const Text('Save Product Info'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --------- Agreement Details ----------
                          _Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Agreement Details',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  LayoutBuilder(builder: (context, c) {
                                    final wide = c.maxWidth >= 900;
                                    return Wrap(
                                      spacing: 18, runSpacing: 16,
                                      children: [
                                        _w(width: wide ? 320 : c.maxWidth, child: _Labeled('Contract Status',
                                          TextFormField(controller: _contractStatusCtrl))),
                                        _w(width: wide ? 320 : c.maxWidth, child: _Labeled('Contract Value',
                                          TextFormField(controller: _contractValueCtrl))),
                                        _w(width: wide ? 320 : c.maxWidth, child: _Labeled('Payment Terms',
                                          TextFormField(controller: _paymentTermsCtrl))),
                                        _w(width: wide ? 320 : c.maxWidth, child: _Labeled('Renewal Date', _RenewalPicker(
                                          value: _renewalDate,
                                          onChanged: (ts) => setState(() => _renewalDate = ts),
                                        ))),
                                      ],
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 170, height: 40,
                                      child: FilledButton(
                                        onPressed: _saveAgreement,
                                        child: const Text('Save Agreement'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --------- Usage & Deployment ----------
                          _Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Usage & Deployment',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  LayoutBuilder(builder: (context, c) {
                                    final wide = c.maxWidth >= 900;
                                    return Wrap(
                                      spacing: 18, runSpacing: 16,
                                      children: [
                                        _w(width: wide ? 300 : c.maxWidth, child: _Labeled('Active Users',
                                          TextFormField(controller: _activeUsersCtrl))),
                                        _w(width: wide ? 340 : c.maxWidth, child: _Labeled('Deployment Status',
                                          TextFormField(controller: _deploymentStatusCtrl))),
                                        _w(width: wide ? 360 : c.maxWidth, child: _Labeled('Implementation Timeline',
                                          TextFormField(controller: _implementationTimelineCtrl))),
                                        _w(width: wide ? 320 : c.maxWidth, child: _Labeled('Training Required',
                                          TextFormField(controller: _trainingRequiredCtrl))),
                                      ],
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 180, height: 40,
                                      child: FilledButton(
                                        onPressed: _saveUsage,
                                        child: const Text('Save Usage'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --------- Recent Activity ----------
                          _Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Recent Activity',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      TextButton.icon(
                                        onPressed: () => setState(() => _recent.add(_KVRow.newEmpty())),
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Add Row'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ..._recent.asMap().entries.map((e) {
                                    final idx = e.key;
                                    final row = e.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: _Labeled('Date',
                                                TextFormField(controller: row.dateCtrl, decoration: const InputDecoration(hintText: 'Dec 10, 2024'))),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 4,
                                            child: _Labeled('Title',
                                                TextFormField(controller: row.titleCtrl, decoration: const InputDecoration(hintText: 'Vendor Proposal Received'))),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Remove',
                                            onPressed: () => setState(() => _recent.removeAt(idx)),
                                            icon: const Icon(Icons.close_rounded),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 180, height: 40,
                                      child: FilledButton(
                                        onPressed: _saveRecent,
                                        child: const Text('Save Activity'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --------- Gartner ----------
                          _Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Gartner',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      TextButton.icon(
                                        onPressed: () => setState(() => _gartner.add(_GartnerRowModel.newEmpty())),
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Add Year'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ..._gartner.asMap().entries.map((e) {
                                    final idx = e.key;
                                    final g = e.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 90,
                                            child: _Labeled('Year',
                                                TextFormField(controller: g.yearCtrl, keyboardType: TextInputType.number)),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 160,
                                            child: _Labeled('Tier',
                                                TextFormField(controller: g.tierCtrl, decoration: const InputDecoration(hintText: 'Leader / Challenger / …'))),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _Labeled('Note',
                                                TextFormField(controller: g.noteCtrl)),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Remove',
                                            onPressed: () => setState(() => _gartner.removeAt(idx)),
                                            icon: const Icon(Icons.close_rounded),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 180, height: 40,
                                      child: FilledButton(
                                        onPressed: _saveGartner,
                                        child: const Text('Save Gartner'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
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

// -------- Small UI helpers --------

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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
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
      child: child,
    );
  }
}

// Renewal date picker input
class _RenewalPicker extends StatelessWidget {
  const _RenewalPicker({required this.value, required this.onChanged});
  final Timestamp? value;
  final ValueChanged<Timestamp?> onChanged;

  String _format(Timestamp? ts) {
    if (ts == null) return 'Pick a date';
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month-1]} ${d.day}, ${d.year}';
    }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final current = value?.toDate() ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: current,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onChanged(Timestamp.fromDate(picked));
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_format(value)),
            const Icon(Icons.calendar_today_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

// list-row models
class _KVRow {
  final TextEditingController dateCtrl;
  final TextEditingController titleCtrl;
  _KVRow({required this.dateCtrl, required this.titleCtrl});
  factory _KVRow.newEmpty() => _KVRow(dateCtrl: TextEditingController(), titleCtrl: TextEditingController());
  void dispose() { dateCtrl.dispose(); titleCtrl.dispose(); }
}

class _GartnerRowModel {
  final TextEditingController yearCtrl;
  final TextEditingController tierCtrl;
  final TextEditingController noteCtrl;
  _GartnerRowModel({required this.yearCtrl, required this.tierCtrl, required this.noteCtrl});
  factory _GartnerRowModel.newEmpty() => _GartnerRowModel(
    yearCtrl: TextEditingController(),
    tierCtrl: TextEditingController(),
    noteCtrl: TextEditingController(),
  );
  void dispose() { yearCtrl.dispose(); tierCtrl.dispose(); noteCtrl.dispose(); }
}
