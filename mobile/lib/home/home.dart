import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile/categres/categres.dart';
import 'package:mobile/models/note_model.dart';
import 'package:mobile/notes/addNode.dart';
import 'package:mobile/notes/edit_note.dart';

class NoteHomeScreen extends StatefulWidget {
  const NoteHomeScreen({super.key});

  @override
  State<NoteHomeScreen> createState() => _NoteHomeScreenState();
}

class _NoteHomeScreenState extends State<NoteHomeScreen> {
  // ============================================================
  // الألوان
  // ============================================================

  static const Color blue = Color(0xFF00A8FF);
  static const Color background = Color(0xFFF2F2F2);
  static const Color textDark = Color(0xFF222222);

  // ============================================================
  // التصنيفات
  // ============================================================

  List<String> categories = ['الكل', 'الصفحة الرئيسية', 'العمل', 'المدرسة'];

  int selectedCategoryIndex = 0;

  // ============================================================
  // الملاحظات
  // ============================================================

  List<QueryDocumentSnapshot> notesList = [];

  bool isLoadingNotes = true;
  bool isLoadingCategories = true;

  // ============================================================
  // بداية الصفحة
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ============================================================
  // تحميل البيانات
  // ============================================================

  Future<void> loadData() async {
    await getCategories();
    await getNotes();
  }

  // ============================================================
  // جلب التصنيفات
  // ============================================================

  Future<void> getCategories() async {
    try {
      if (mounted) {
        setState(() {
          isLoadingCategories = true;
        });
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      if (!mounted) return;

      final List<String> loadedCategories = [
        'الكل',
        'الصفحة الرئيسية',
        'العمل',
        'المدرسة',
      ];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('name')) {
          final String categoryName = data['name']?.toString().trim() ?? '';

          if (categoryName.isNotEmpty &&
              !loadedCategories.contains(categoryName)) {
            loadedCategories.add(categoryName);
          }
        }
      }

      setState(() {
        categories = loadedCategories;

        if (selectedCategoryIndex >= categories.length) {
          selectedCategoryIndex = 0;
        }

        isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('ERROR GETTING CATEGORIES: $e');

      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // ============================================================
  // جلب الملاحظات
  // ============================================================

  Future<void> getNotes() async {
    try {
      if (mounted) {
        setState(() {
          isLoadingNotes = true;
        });
      }

      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .get();

      List<QueryDocumentSnapshot> filteredList = [];

      // ==========================================================
      // فلترة حسب التصنيف
      // ==========================================================

      if (selectedCategoryIndex == 0) {
        filteredList = querySnapshot.docs.toList();
      } else if (selectedCategoryIndex < categories.length) {
        final String selectedCategory = categories[selectedCategoryIndex]
            .trim()
            .toLowerCase();

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;

          if (data == null) continue;

          final String noteCategory =
              data['category']?.toString().trim().toLowerCase() ?? '';

          if (noteCategory == selectedCategory) {
            filteredList.add(doc);
          }
        }
      }

      // ==========================================================
      // إخفاء الملاحظات المخفية
      // ==========================================================

      filteredList = filteredList.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data == null) return false;

        return data['isHidden'] != true;
      }).toList();

      // ==========================================================
      // ترتيب المثبتة أولًا
      // ==========================================================

      filteredList.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;

        final bool pinnedA = dataA['isPinned'] == true;
        final bool pinnedB = dataB['isPinned'] == true;

        if (pinnedA && !pinnedB) return -1;
        if (!pinnedA && pinnedB) return 1;

        return 0;
      });

      if (!mounted) return;

      setState(() {
        notesList = filteredList;
        isLoadingNotes = false;
      });

      debugPrint('التصنيف الحالي: ${categories[selectedCategoryIndex]}');

      debugPrint('عدد الملاحظات: ${notesList.length}');
    } catch (e) {
      debugPrint('ERROR GETTING NOTES: $e');

      if (!mounted) return;

      setState(() {
        isLoadingNotes = false;
      });
    }
  }

  // ============================================================
  // اختيار التصنيف
  // ============================================================

  Future<void> selectCategory(int index) async {
    if (index < 0 || index >= categories.length) {
      return;
    }

    setState(() {
      selectedCategoryIndex = index;
    });

    await getNotes();
  }

  // ============================================================
  // إضافة ملاحظة
  // ============================================================

  Future<void> openAddNote() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddNotePage()));

    await getNotes();
  }

  // ============================================================
  // إضافة تصنيف
  // ============================================================

  Future<void> openAddCategory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddUserAndCategoryPage()),
    );

    await getCategories();
    await getNotes();
  }

  // ============================================================
  // الضغط المطول على الملاحظة
  // ============================================================

  void showNoteOptions(QueryDocumentSnapshot note) {
    final data = note.data() as Map<String, dynamic>;

    final bool isPinned = data['isPinned'] == true;
    final bool isHidden = data['isHidden'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // المؤشر
                // ------------------------------------------------
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // عنوان الملاحظة
                // ------------------------------------------------
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE7D2),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.note_alt_outlined,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        data['title']?.toString() ?? 'بدون عنوان',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // ------------------------------------------------
                // تثبيت
                // ------------------------------------------------
                ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: _optionIcon(
                    icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: blue,
                    background: const Color(0xFFEAF6FF),
                  ),

                  title: Text(
                    isPinned ? 'إلغاء تثبيت الملاحظة' : 'تثبيت الملاحظة',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  onTap: () async {
                    Navigator.pop(context);

                    try {
                      await FirebaseFirestore.instance
                          .collection('notes')
                          .doc(note.id)
                          .update({'isPinned': !isPinned});

                      await getNotes();
                    } catch (e) {
                      debugPrint('ERROR PINNING NOTE: $e');
                    }
                  },
                ),

                // ------------------------------------------------
                // إخفاء
                // ------------------------------------------------
                ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: _optionIcon(
                    icon: isHidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade700,
                    background: Colors.grey.shade100,
                  ),

                  title: Text(
                    isHidden ? 'إظهار الملاحظة' : 'إخفاء الملاحظة',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  onTap: () async {
                    Navigator.pop(context);

                    try {
                      await FirebaseFirestore.instance
                          .collection('notes')
                          .doc(note.id)
                          .update({'isHidden': !isHidden});

                      await getNotes();
                    } catch (e) {
                      debugPrint('ERROR HIDING NOTE: $e');
                    }
                  },
                ),

                // ------------------------------------------------
                // نقل
                // ------------------------------------------------
                ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: _optionIcon(
                    icon: Icons.drive_file_move_outlined,
                    color: Colors.orange,
                    background: const Color(0xFFFFF4E8),
                  ),

                  title: const Text(
                    'نقل إلى',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  onTap: () {
                    Navigator.pop(context);
                    showMoveNoteDialog(note);
                  },
                ),

                // ------------------------------------------------
                // حذف
                // ------------------------------------------------
                ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: _optionIcon(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    background: const Color(0xFFFFEEEE),
                  ),

                  title: const Text(
                    'حذف الملاحظة',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(context);
                    showDeleteNoteDialog(note);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // أيقونة خيار
  // ============================================================

  Widget _optionIcon({
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  // ============================================================
  // نقل الملاحظة
  // ============================================================

  void showMoveNoteDialog(QueryDocumentSnapshot note) {
    final data = note.data() as Map<String, dynamic>;

    final String currentCategory = data['category']?.toString() ?? '';

    final List<String> moveCategories = categories
        .where((category) => category != 'الكل' && category != currentCategory)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'نقل الملاحظة إلى',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (moveCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لا توجد تصنيفات أخرى',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...moveCategories.map((category) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,

                      leading: _optionIcon(
                        icon: Icons.folder_outlined,
                        color: blue,
                        background: const Color(0xFFEAF6FF),
                      ),

                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      onTap: () async {
                        Navigator.pop(context);

                        try {
                          await FirebaseFirestore.instance
                              .collection('notes')
                              .doc(note.id)
                              .update({'category': category});

                          await getNotes();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم نقل الملاحظة إلى $category',
                                textAlign: TextAlign.right,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          debugPrint('ERROR MOVING NOTE: $e');
                        }
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // حذف الملاحظة
  // ============================================================

  void showDeleteNoteDialog(QueryDocumentSnapshot note) {
    final data = note.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'حذف الملاحظة',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: Text(
            'هل أنت متأكد من حذف "${data['title']?.toString() ?? 'هذه الملاحظة'}"؟',
            textAlign: TextAlign.right,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              onPressed: () async {
                Navigator.pop(context);

                try {
                  await FirebaseFirestore.instance
                      .collection('notes')
                      .doc(note.id)
                      .delete();

                  await getNotes();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم حذف الملاحظة بنجاح',
                        textAlign: TextAlign.right,
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  debugPrint('ERROR DELETING NOTE: $e');
                }
              },

              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // فتح الملاحظة للتعديل
  // ============================================================

  Future<void> openEditNote(QueryDocumentSnapshot note) async {
    try {
      final NoteModel noteModel = NoteModel.fromFirestore(
        note as DocumentSnapshot<Map<String, dynamic>>,
      );

      final bool? updated = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditNote(note: noteModel)),
      );

      if (updated == true) {
        await getNotes();
      }
    } catch (e) {
      debugPrint('ERROR OPENING EDIT NOTE: $e');
    }
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
          backgroundColor: Colors.transparent,
          elevation: 0,

          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {},
          ),

          actions: [
            IconButton(
              icon: const Icon(Icons.star, color: Color(0xFFFFB300)),
              onPressed: () {},
            ),

            IconButton(
              icon: const Icon(Icons.search, color: Colors.black87),
              onPressed: () {},
            ),

            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.black87),
              onPressed: () {},
            ),

            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onPressed: () {},
            ),
          ],
        ),

        // ========================================================
        // زر إضافة
        // ========================================================
        floatingActionButton: FloatingActionButton(
          onPressed: openAddNote,

          backgroundColor: blue,

          child: const Icon(Icons.add, color: Colors.white),
        ),

        // ========================================================
        // Body
        // ========================================================
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ====================================================
            // التصنيفات
            // ====================================================
            SizedBox(
              height: 60,

              child: isLoadingCategories
                  ? const Center(
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          color: blue,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),

                      itemCount: categories.length + 1,

                      itemBuilder: (context, index) {
                        // ==========================================
                        // إضافة تصنيف
                        // ==========================================

                        if (index == categories.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),

                            child: ActionChip(
                              avatar: const Icon(Icons.add, size: 18),

                              label: const Text('إضافة تصنيف'),

                              backgroundColor: Colors.white,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),

                              onPressed: openAddCategory,
                            ),
                          );
                        }

                        final bool isSelected = selectedCategoryIndex == index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),

                          child: ChoiceChip(
                            label: Text(categories[index]),

                            selected: isSelected,

                            selectedColor: blue,

                            backgroundColor: Colors.white,

                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,

                              fontWeight: FontWeight.bold,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),

                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                            ),

                            onSelected: (selected) async {
                              if (!selected) {
                                return;
                              }

                              await selectCategory(index);
                            },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),

            // ====================================================
            // عنوان التصنيف
            // ====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),

              child: Row(
                children: [
                  Text(
                    categories.isNotEmpty
                        ? categories[selectedCategoryIndex]
                        : 'الملاحظات',

                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(width: 8),

                  if (!isLoadingNotes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Text(
                        '${notesList.length}',

                        style: const TextStyle(
                          color: blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ====================================================
            // الملاحظات
            // ====================================================
            Expanded(
              child: isLoadingNotes
                  ? const Center(child: CircularProgressIndicator(color: blue))
                  : notesList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 65,
                            color: Colors.grey.shade400,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            selectedCategoryIndex == 0
                                ? 'لا توجد ملاحظات حالياً'
                                : 'لا توجد ملاحظات في تصنيف "${categories[selectedCategoryIndex]}"',

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),

                      itemCount: notesList.length,

                      itemBuilder: (context, index) {
                        final note = notesList[index];

                        final data = note.data() as Map<String, dynamic>;

                        final String title = data['title']?.toString() ?? '';

                        final String content =
                            data['content']?.toString() ?? '';

                        final String category =
                            data['category']?.toString() ?? '';

                        final bool isPinned = data['isPinned'] == true;

                        String createdDate = '';

                        if (data['createdAt'] is Timestamp) {
                          final Timestamp timestamp =
                              data['createdAt'] as Timestamp;

                          final DateTime date = timestamp.toDate();

                          createdDate =
                              '${date.year}-'
                              '${date.month.toString().padLeft(2, '0')}-'
                              '${date.day.toString().padLeft(2, '0')}';
                        }

                        // ==================================================
                        // بطاقة الملاحظة
                        // ==================================================

                        return GestureDetector(
                          // ----------------------------------------------
                          // الضغط العادي
                          // ----------------------------------------------
                          onTap: () async {
                            await openEditNote(note);
                          },

                          // ----------------------------------------------
                          // الضغط المطول
                          // ----------------------------------------------
                          onLongPress: () {
                            showNoteOptions(note);
                          },

                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFE7D2),

                              borderRadius: BorderRadius.circular(16),

                              border: isPinned
                                  ? Border.all(color: blue, width: 1.5)
                                  : null,
                            ),

                            padding: const EdgeInsets.all(12),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                // =========================================
                                // رأس البطاقة
                                // =========================================
                                Row(
                                  children: [
                                    if (isPinned)
                                      const Icon(
                                        Icons.push_pin,
                                        color: blue,
                                        size: 17,
                                      ),

                                    if (isPinned) const SizedBox(width: 5),

                                    Expanded(
                                      child: Text(
                                        title.isEmpty ? 'بدون عنوان' : title,

                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),

                                        maxLines: 2,

                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // =========================================
                                // المحتوى
                                // =========================================
                                Expanded(
                                  child: Text(
                                    content,

                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      height: 1.4,
                                    ),

                                    maxLines: 6,

                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // =========================================
                                // التصنيف والتاريخ
                                // =========================================
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
                                      ),

                                    if (createdDate.isNotEmpty)
                                      Text(
                                        createdDate,

                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
