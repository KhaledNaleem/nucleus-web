import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String department;
  final String segment;
  final List<String> businessSize;
  final String agreementType;
  final List<String> salesIncharge;
  final List<String> technicalIncharge;
  final List<String> countries;

  Product({
    required this.id,
    required this.name,
    required this.department,
    required this.segment,
    required this.businessSize,
    required this.agreementType,
    required this.salesIncharge,
    required this.technicalIncharge,
    required this.countries,
  });

  factory Product.fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    List<String> _strList(key) =>
        (m[key] as List?)?.map((e) => e.toString()).cast<String>().toList() ?? <String>[];

    return Product(
      id: d.id,
      name: (m['name'] ?? '').toString(),
      department: (m['department'] ?? '').toString(),
      segment: (m['segment'] ?? '').toString(),
      businessSize: _strList('businessSize'),
      agreementType: (m['agreementType'] ?? '').toString(),
      salesIncharge: _strList('salesIncharge'),
      technicalIncharge: _strList('technicalIncharge'),
      countries: _strList('countries'),
    );
  }
}

class ProductRepository {
  final _col = FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> watch({
    String? category, // 'Cyber Security' | 'Data Center' | 'Digital Transformation' | null = All
    String? country,  // 'Sri Lanka' | 'India' | ... | null = All
    String? search,   // optional prefix search on nameLower
  }) {
    Query q = _col;

    if (category != null && category.isNotEmpty) {
      q = q.where('department', isEqualTo: category);
    }
    if (country != null && country.isNotEmpty) {
      q = q.where('countries', arrayContains: country);
    }

    if (search != null && search.trim().isNotEmpty) {
      final s = search.toLowerCase();
      q = q.orderBy('nameLower').startAt([s]).endAt(['$s\uf8ff']);
    } else {
      q = q.orderBy('nameLower');
    }

    return q.limit(100).snapshots().map((snap) => snap.docs.map(Product.fromDoc).toList());
  }
}
