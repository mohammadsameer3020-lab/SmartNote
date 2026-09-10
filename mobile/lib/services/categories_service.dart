import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // التصنيفات الأساسية
  // ============================================================

  List<String> get defaultCategories {
    return ['الكل', 'الصفحة الرئيسية', 'العمل', 'المدرسة'];
  }

  // ============================================================
  // جلب التصنيفات
  // ============================================================

  Future<List<String>> getCategories() async {
    final QuerySnapshot snapshot = await _firestore
        .collection('categories')
        .get();

    final List<String> loadedCategories = [...defaultCategories];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        continue;
      }

      if (!data.containsKey('name')) {
        continue;
      }

      final String categoryName = data['name']?.toString().trim() ?? '';

      if (categoryName.isNotEmpty && !loadedCategories.contains(categoryName)) {
        loadedCategories.add(categoryName);
      }
    }

    return loadedCategories;
  }

  // ============================================================
  // حذف التصنيف
  // ============================================================

  Future<void> deleteCategory(String categoryName) async {
    final String name = categoryName.trim();

    // ------------------------------------------------------------
    // منع حذف التصنيفات الأساسية
    // ------------------------------------------------------------

    if (defaultCategories.contains(name)) {
      throw Exception('لا يمكن حذف التصنيف الأساسي "$name"');
    }

    // ------------------------------------------------------------
    // البحث عن التصنيف
    // ------------------------------------------------------------

    final QuerySnapshot snapshot = await _firestore
        .collection('categories')
        .where('name', isEqualTo: name)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('التصنيف "$name" غير موجود');
    }

    // ------------------------------------------------------------
    // حذف التصنيف
    // ------------------------------------------------------------

    final WriteBatch batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
