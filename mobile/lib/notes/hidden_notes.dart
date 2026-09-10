import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/note_model.dart';
import 'package:mobile/notes/edit_note.dart';

class HiddenNotesPage extends StatefulWidget {
  const HiddenNotesPage({super.key});

  @override
  State<HiddenNotesPage> createState() => _HiddenNotesPageState();
}

class _HiddenNotesPageState extends State<HiddenNotesPage> {
  // الألوان
  static const Color backgroundColor = Color(0xFFF2F2F2);
  static const Color textDark = Color(0xFF222222);
  static const Color textGrey = Color(0xFF777777);
  static const Color orange = Color(0xFFFF7A00);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> hiddenNotes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getHiddenNotes();
  }

  // ============================================================
  // جلب الملاحظات المخفية
  // ============================================================
  Future<void> getHiddenNotes() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('notes')
              .where('isHidden', isEqualTo: true)
              .get();

      if (!mounted) return;

      final notes = snapshot.docs.where((doc) {
        final data = doc.data();

        // التأكد أن الملاحظة مخفية فعلًا
        return data['isHidden'] == true;
      }).toList();

      // ترتيب الملاحظات حسب آخر تعديل/الإنشاء
      notes.sort((a, b) {
        final aData = a.data();
        final bData = b.data();

        final aDate = _getDate(aData['updatedAt'] ?? aData['createdAt']);
        final bDate = _getDate(bData['updatedAt'] ?? bData['createdAt']);

        return bDate.compareTo(aDate);
      });

      setState(() {
        hiddenNotes = notes;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل الملاحظات المخفية',
            textAlign: TextAlign.right,
          ),
        ),
      );
    }
  }

  // ============================================================
  // تحويل التاريخ
  // ============================================================
  DateTime _getDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ============================================================
  // استخراج عنوان الملاحظة
  // ============================================================
  String _getTitle(Map<String, dynamic> data) {
    final title = data['title'];

    if (title == null) {
      return 'بدون عنوان';
    }

    final value = title.toString().trim();

    if (value.isEmpty) {
      return 'بدون عنوان';
    }

    return value;
  }

  // ============================================================
  // استخراج محتوى الملاحظة
  // ============================================================
  String _getContent(Map<String, dynamic> data) {
    final content = data['content'];

    if (content == null) {
      return '';
    }

    return content.toString().trim();
  }

  // ============================================================
  // استخراج التصنيف
  // ============================================================
  String _getCategory(Map<String, dynamic> data) {
    final category = data['category'];

    if (category == null || category.toString().trim().isEmpty) {
      return 'غير مصنف';
    }

    return category.toString().trim();
  }

  // ============================================================
  // فتح الملاحظة
  // ============================================================
  Future<void> openEditNote(
    QueryDocumentSnapshot<Map<String, dynamic>> note,
  ) async {
    try {
      final NoteModel noteModel = NoteModel.fromFirestore(note);

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditNote(note: noteModel)),
      );

      if (!mounted) return;

      // إعادة تحميل الملاحظات بعد الرجوع
      await getHiddenNotes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء فتح الملاحظة',
            textAlign: TextAlign.right,
          ),
        ),
      );
    }
  }

  // ============================================================
  // إظهار الملاحظة
  // ============================================================
  Future<void> showNote(
    QueryDocumentSnapshot<Map<String, dynamic>> note,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notes').doc(note.id).update({
        'isHidden': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // حذفها من القائمة مباشرة
      setState(() {
        hiddenNotes.removeWhere((item) => item.id == note.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إظهار الملاحظة', textAlign: TextAlign.right),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إظهار الملاحظة',
            textAlign: TextAlign.right,
          ),
        ),
      );
    }
  }

  // ============================================================
  // نافذة تأكيد إظهار الملاحظة
  // ============================================================
  Future<void> showUnhideDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> note,
  ) async {
    final data = note.data();
    final title = _getTitle(data);

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'إظهار الملاحظة',
              style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
            ),
            content: Text(
              'هل تريد إظهار "$title" مرة أخرى في الصفحة الرئيسية؟',
              style: const TextStyle(fontSize: 15, color: textGrey),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('إلغاء', style: TextStyle(color: textGrey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('إظهار'),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      await showNote(note);
    }
  }

  // ============================================================
  // قائمة خيارات الملاحظة
  // ============================================================
  void showNoteOptions(QueryDocumentSnapshot<Map<String, dynamic>> note) {
    final data = note.data();
    final title = _getTitle(data);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الخط العلوي
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // العنوان
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: orange.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.visibility_off_outlined,
                            color: orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Divider(height: 1),

                  // فتح الملاحظة
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: textDark),
                    title: const Text(
                      'فتح الملاحظة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      openEditNote(note);
                    },
                  ),

                  // إظهار الملاحظة
                  ListTile(
                    leading: const Icon(
                      Icons.visibility_outlined,
                      color: Colors.green,
                    ),
                    title: const Text(
                      'إظهار الملاحظة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await showUnhideDialog(note);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // بطاقة الملاحظة
  // ============================================================
  Widget buildNoteCard(QueryDocumentSnapshot<Map<String, dynamic>> note) {
    final data = note.data();

    final title = _getTitle(data);
    final content = _getContent(data);
    final category = _getCategory(data);

    return GestureDetector(
      onTap: () => openEditNote(note),
      onLongPress: () => showNoteOptions(note),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة الإخفاء
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.visibility_off_outlined,
                      size: 20,
                      color: orange,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showUnhideDialog(note),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        size: 19,
                        color: textGrey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // العنوان
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),

              // المحتوى
              if (content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: textGrey,
                  ),
                ),
              ],

              const Spacer(),

              const SizedBox(height: 12),

              // التصنيف
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 16, color: textGrey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: textGrey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // الحالة الفارغة
  // ============================================================
  Widget buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: orange.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility_off_outlined,
                size: 45,
                color: orange,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'لا توجد ملاحظات مخفية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'الملاحظات التي تقوم بإخفائها ستظهر هنا',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textGrey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // واجهة التحميل
  // ============================================================
  Widget buildLoading() {
    return const Center(child: CircularProgressIndicator(color: orange));
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,

          leading: IconButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.arrow_back, color: textDark),
          ),

          title: const Text(
            'الملاحظات المخفية',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          actions: [
            IconButton(
              onPressed: getHiddenNotes,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: textDark),
            ),
          ],
        ),

        body: isLoading
            ? buildLoading()
            : hiddenNotes.isEmpty
            ? buildEmptyState()
            : RefreshIndicator(
                color: orange,
                onRefresh: getHiddenNotes,
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: hiddenNotes.length,
                  itemBuilder: (context, index) {
                    return buildNoteCard(hiddenNotes[index]);
                  },
                ),
              ),
      ),
    );
  }
}
