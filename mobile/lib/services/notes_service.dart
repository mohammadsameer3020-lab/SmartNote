import 'package:cloud_firestore/cloud_firestore.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // جلب جميع الملاحظات
  // ============================================================

  Future<List<QueryDocumentSnapshot>> getAllNotes() async {
    final QuerySnapshot snapshot = await _firestore.collection('notes').get();

    return snapshot.docs;
  }

  // ============================================================
  // تحديث الملاحظة
  // ============================================================

  Future<void> updateNote(String noteId, Map<String, dynamic> data) async {
    await _firestore.collection('notes').doc(noteId).update(data);
  }

  // ============================================================
  // تثبيت / إلغاء تثبيت
  // ============================================================

  Future<void> togglePin(String noteId, bool isPinned) async {
    await _firestore.collection('notes').doc(noteId).update({
      'isPinned': !isPinned,
    });
  }

  // ============================================================
  // إخفاء / إظهار
  // ============================================================

  Future<void> toggleHidden(String noteId, bool isHidden) async {
    await _firestore.collection('notes').doc(noteId).update({
      'isHidden': !isHidden,
    });
  }

  // ============================================================
  // نقل الملاحظة
  // ============================================================

  Future<void> moveNote(String noteId, String category) async {
    await _firestore.collection('notes').doc(noteId).update({
      'category': category,
    });
  }

  // ============================================================
  // حذف الملاحظة
  // ============================================================

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('notes').doc(noteId).delete();
  }
}
