import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:mobile/models/note_model.dart';
import 'package:mobile/notes/edit_note.dart';

class PinnedNotesPage extends StatefulWidget {
  const PinnedNotesPage({super.key});

  @override
  State<PinnedNotesPage> createState() => _PinnedNotesPageState();
}

class _PinnedNotesPageState extends State<PinnedNotesPage> {
  static const Color blue = Color(0xFF00A8FF);
  static const Color background = Color(0xFFF2F2F2);
  static const Color textDark = Color(0xFF222222);

  bool isLoading = true;

  List<QueryDocumentSnapshot> pinnedNotes = [];

  @override
  void initState() {
    super.initState();
    getPinnedNotes();
  }

  // ============================================================
  // جلب الملاحظات المثبتة
  // ============================================================

  Future<void> getPinnedNotes() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('isPinned', isEqualTo: true)
          .get();

      if (!mounted) return;

      setState(() {
        pinnedNotes = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR GETTING PINNED NOTES: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل الملاحظات المثبتة',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // فتح شاشة تعديل الملاحظة
  // ============================================================

  Future<void> openEditNote(QueryDocumentSnapshot note) async {
    try {
      // تحويل بيانات Firestore إلى NoteModel
      final NoteModel noteModel = NoteModel.fromFirestore(
        note as DocumentSnapshot<Map<String, dynamic>>,
      );

      // فتح شاشة EditNote وتمرير الملاحظة الحالية
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditNote(note: noteModel)),
      );

      if (!mounted) return;

      // إعادة تحميل الملاحظات بعد الرجوع
      await getPinnedNotes();
    } catch (e) {
      debugPrint('ERROR OPENING EDIT NOTE: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء فتح الملاحظة: $e',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // إلغاء تثبيت الملاحظة
  // ============================================================

  Future<void> unpinNote(QueryDocumentSnapshot note) async {
    try {
      await FirebaseFirestore.instance.collection('notes').doc(note.id).update({
        'isPinned': false,
      });

      if (!mounted) return;

      setState(() {
        pinnedNotes.removeWhere((item) => item.id == note.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء تثبيت الملاحظة', textAlign: TextAlign.right),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('ERROR UNPINNING NOTE: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إلغاء التثبيت',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // تأكيد إلغاء التثبيت
  // ============================================================

  void showUnpinDialog(QueryDocumentSnapshot note) {
    final data = note.data() as Map<String, dynamic>;

    final String title = data['title']?.toString().trim().isNotEmpty == true
        ? data['title'].toString()
        : 'بدون عنوان';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'إلغاء تثبيت الملاحظة',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
            ),
            content: Text(
              'هل تريد إلغاء تثبيت "$title"؟',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  unpinNote(note);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('إلغاء التثبيت'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // بطاقة الملاحظة
  // ============================================================

  Widget buildNoteCard(QueryDocumentSnapshot note) {
    final data = note.data() as Map<String, dynamic>;

    final String title = data['title']?.toString() ?? '';
    final String content = data['content']?.toString() ?? '';
    final String category = data['category']?.toString() ?? '';

    String createdDate = '';

    if (data['createdAt'] is Timestamp) {
      final Timestamp timestamp = data['createdAt'] as Timestamp;
      final DateTime date = timestamp.toDate();

      createdDate =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      // ==========================================================
      // الضغط على البطاقة → EditNote
      // ==========================================================
      onTap: () {
        openEditNote(note);
      },

      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFE7D2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: blue, width: 1.5),
        ),
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------
            // العنوان + علامة التثبيت
            // ------------------------------------------------------
            Row(
              children: [
                const Icon(Icons.push_pin, color: blue, size: 17),
                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    title.isEmpty ? 'بدون عنوان' : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ------------------------------------------------------
            // محتوى الملاحظة
            // ------------------------------------------------------
            Expanded(
              child: Text(
                content.isEmpty ? 'لا يوجد محتوى' : content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ------------------------------------------------------
            // التصنيف + التاريخ + إلغاء التثبيت
            // ------------------------------------------------------
            Row(
              children: [
                if (category.isNotEmpty)
                  Expanded(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Spacer(),

                if (createdDate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      createdDate,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),

                const SizedBox(width: 4),

                // زر إلغاء التثبيت
                IconButton(
                  tooltip: 'إلغاء التثبيت',
                  onPressed: () {
                    showUnpinDialog(note);
                  },
                  icon: const Icon(Icons.push_pin, color: blue, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // حالة عدم وجود ملاحظات مثبتة
  // ============================================================

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.push_pin_outlined, color: blue, size: 42),
            ),

            const SizedBox(height: 20),

            const Text(
              'لا توجد ملاحظات مثبتة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'عندما تقوم بتثبيت ملاحظة ستظهر هنا',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // واجهة الصفحة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,

        // ========================================================
        // AppBar
        // ========================================================
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,

          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: textDark,
              size: 20,
            ),
          ),

          title: const Text(
            'الملاحظات المثبتة',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: getPinnedNotes,
              icon: const Icon(Icons.refresh_rounded, color: textDark),
            ),
          ],
        ),

        // ========================================================
        // Body
        // ========================================================
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: blue))
            : pinnedNotes.isEmpty
            ? buildEmptyState()
            : RefreshIndicator(
                color: blue,
                onRefresh: getPinnedNotes,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: pinnedNotes.length,
                  itemBuilder: (context, index) {
                    return buildNoteCard(pinnedNotes[index]);
                  },
                ),
              ),
      ),
    );
  }
}
