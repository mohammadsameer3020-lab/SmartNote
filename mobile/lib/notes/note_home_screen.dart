import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:mobile/categres/categres.dart';
import 'package:mobile/models/note_model.dart';
import 'package:mobile/notes/addNode.dart';
import 'package:mobile/notes/calendar_notes.dart';
import 'package:mobile/notes/edit_note.dart';
import 'package:mobile/notes/hidden_notes.dart';

import 'package:mobile/services/categories_service.dart';

import 'package:mobile/widgets/category_chip.dart';
import 'package:mobile/widgets/delete_note_dialog.dart';
import 'package:mobile/widgets/move_note_sheet.dart';
import 'package:mobile/widgets/note_card.dart';
import 'package:mobile/widgets/note_options_sheet.dart';

class NoteHomeScreen extends StatefulWidget {
  const NoteHomeScreen({super.key});

  @override
  State<NoteHomeScreen> createState() => _NoteHomeScreenState();
}

class _NoteHomeScreenState extends State<NoteHomeScreen> {
  // ============================================================
  // الألوان
  // ============================================================

  final Color blue = const Color(0xFF00A8FF);
  final Color background = const Color(0xFFF2F2F2);
  final Color textDark = const Color(0xFF222222);

  // ============================================================
  // الخدمات
  // ============================================================

  final CategoriesService _categoriesService = CategoriesService();

  // ============================================================
  // البيانات
  // ============================================================

  List<String> categories = ['الكل', 'الصفحة الرئيسية', 'العمل', 'المدرسة'];

  List<QueryDocumentSnapshot> notes = [];

  int selectedCategoryIndex = 0;

  bool isLoading = true;

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
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      await getCategories();
      await getNotes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل البيانات: $e')),
      );
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // جلب التصنيفات
  // ============================================================

  Future<void> getCategories() async {
    try {
      final List<String> loadedCategories = await _categoriesService
          .getCategories();

      if (!mounted) return;

      setState(() {
        categories = loadedCategories;

        if (selectedCategoryIndex >= categories.length) {
          selectedCategoryIndex = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب التصنيفات: $e')),
      );
    }
  }

  // ============================================================
  // جلب الملاحظات
  // ============================================================

  Future<void> getNotes() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notes')
          .get();

      if (!mounted) return;

      final String selectedCategory =
          categories.isNotEmpty && selectedCategoryIndex < categories.length
          ? categories[selectedCategoryIndex]
          : 'الكل';

      final List<QueryDocumentSnapshot> loadedNotes = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // --------------------------------------------------------
        // إخفاء الملاحظات المخفية
        // --------------------------------------------------------

        final bool isHidden = data['isHidden'] == true;

        if (isHidden) {
          continue;
        }

        // --------------------------------------------------------
        // التصنيف
        // --------------------------------------------------------

        final String noteCategory =
            data['category']?.toString() ?? 'الصفحة الرئيسية';

        // --------------------------------------------------------
        // فلترة التصنيف
        // --------------------------------------------------------

        if (selectedCategory != 'الكل' && noteCategory != selectedCategory) {
          continue;
        }

        loadedNotes.add(doc);
      }

      // ----------------------------------------------------------
      // الملاحظات المثبتة أولًا
      // ----------------------------------------------------------

      loadedNotes.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;

        final dataB = b.data() as Map<String, dynamic>;

        final bool pinnedA = dataA['isPinned'] == true;

        final bool pinnedB = dataB['isPinned'] == true;

        if (pinnedA && !pinnedB) {
          return -1;
        }

        if (!pinnedA && pinnedB) {
          return 1;
        }

        return 0;
      });

      if (!mounted) return;

      setState(() {
        notes = loadedNotes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب الملاحظات: $e')),
      );
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNotePage()),
    );

    if (!mounted) return;

    await getNotes();
  }

  // ============================================================
  // إضافة تصنيف
  // ============================================================

  Future<void> openAddCategory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserAndCategoryPage()),
    );

    if (!mounted) return;

    await getCategories();
    await getNotes();
  }

  // ============================================================
  // حذف التصنيف
  // ============================================================

  Future<void> deleteCategory(String category) async {
    // ----------------------------------------------------------
    // منع حذف التصنيفات الأساسية
    // ----------------------------------------------------------

    if (_categoriesService.defaultCategories.contains(category)) {
      return;
    }

    // ----------------------------------------------------------
    // تأكيد الحذف
    // ----------------------------------------------------------

    final bool? confirmed = await showDialog<bool>(
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
              'حذف التصنيف',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل أنت متأكد من حذف التصنيف "$category"؟',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // ----------------------------------------------------------
    // حفظ التصنيف المحدد قبل الحذف
    // ----------------------------------------------------------

    final String oldSelectedCategory =
        categories.isNotEmpty && selectedCategoryIndex < categories.length
        ? categories[selectedCategoryIndex]
        : 'الكل';

    try {
      setState(() {
        isLoading = true;
      });

      // --------------------------------------------------------
      // حذف التصنيف من Firestore
      // --------------------------------------------------------

      await _categoriesService.deleteCategory(category);

      // --------------------------------------------------------
      // إعادة تحميل التصنيفات
      // --------------------------------------------------------

      await getCategories();

      if (!mounted) return;

      // --------------------------------------------------------
      // تحديد التصنيف الحالي بعد الحذف
      // --------------------------------------------------------

      int newIndex = categories.indexOf(oldSelectedCategory);

      // إذا كان التصنيف المحذوف هو المحدد
      if (oldSelectedCategory == category) {
        newIndex = 0;
      }

      // إذا لم يعد التصنيف موجودًا
      if (newIndex == -1) {
        newIndex = 0;
      }

      if (newIndex >= categories.length) {
        newIndex = 0;
      }

      setState(() {
        selectedCategoryIndex = newIndex;
      });

      // --------------------------------------------------------
      // إعادة تحميل الملاحظات
      // --------------------------------------------------------

      await getNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف التصنيف "$category" بنجاح',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء حذف التصنيف: $e',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // خيارات الملاحظة
  // ============================================================

  void openNoteOptions(QueryDocumentSnapshot note) {
    NoteOptionsSheet.show(
      context: context,
      note: note,
      onRefresh: () {
        getNotes();
      },
      onMove: () {
        openMoveNote(note);
      },
      onDelete: () {
        openDeleteNote(note);
      },
    );
  }

  // ============================================================
  // نقل الملاحظة
  // ============================================================

  void openMoveNote(QueryDocumentSnapshot note) {
    MoveNoteSheet.show(
      context: context,
      note: note,
      categories: categories,
      onRefresh: () {
        getNotes();
      },
    );
  }

  // ============================================================
  // حذف الملاحظة
  // ============================================================

  void openDeleteNote(QueryDocumentSnapshot note) {
    DeleteNoteDialog.show(
      context: context,
      note: note,
      onDeleted: () {
        getNotes();
      },
    );
  }

  // ============================================================
  // تعديل الملاحظة
  // ============================================================

  Future<void> openEditNote(QueryDocumentSnapshot note) async {
    try {
      final NoteModel noteModel = NoteModel.fromFirestore(
        note as DocumentSnapshot<Map<String, dynamic>>,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditNote(note: noteModel)),
      );

      if (!mounted) return;

      await getNotes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء فتح الملاحظة: $e')));
    }
  }

  // ============================================================
  // بناء التصنيفات
  // ============================================================

  Widget buildCategories() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          // ----------------------------------------------------
          // زر إضافة تصنيف
          // ----------------------------------------------------

          if (index == categories.length) {
            return ActionChip(
              onPressed: openAddCategory,
              avatar: Icon(Icons.add, size: 18, color: blue),
              label: const Text('إضافة تصنيف'),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }

          // ----------------------------------------------------
          // التصنيف
          // ----------------------------------------------------

          final String category = categories[index];

          final bool selected = selectedCategoryIndex == index;

          // التصنيفات الأساسية لا تحذف
          final bool canDelete = !_categoriesService.defaultCategories.contains(
            category,
          );

          return CategoryChip(
            label: category,
            selected: selected,

            // الضغط العادي
            onTap: () {
              selectCategory(index);
            },

            // الضغط المطول
            onLongPress: canDelete
                ? () {
                    deleteCategory(category);
                  }
                : null,
          );
        },
      ),
    );
  }

  // ============================================================
  // بناء الملاحظات
  // ============================================================

  Widget buildNotes() {
    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 65,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 15),
              Text(
                'لا توجد ملاحظات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ابدأ بإضافة ملاحظة جديدة',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final QueryDocumentSnapshot note = notes[index];

        return NoteCard(
          note: note,

          // الضغط على الملاحظة
          onTap: () {
            openEditNote(note);
          },

          // الضغط المطول
          onLongPress: () {
            openNoteOptions(note);
          },
        );
      },
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

        // ======================================================
        // AppBar
        // ======================================================
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,

          title: Text(
            'ملاحظاتي',
            style: TextStyle(
              color: textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          actions: [
            // ============================================================
            // البحث
            // ============================================================
            IconButton(
              onPressed: () {
                // سنضع هنا شاشة / وظيفة البحث لاحقًا
              },
              icon: Icon(Icons.search, color: textDark),
              tooltip: 'البحث',
            ),

            // ============================================================
            // التقويم
            // ============================================================
            IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CalendarNotesPage(),
                  ),
                );

                if (!mounted) return;

                await getNotes();
              },
              icon: Icon(Icons.calendar_today_outlined, color: textDark),
              tooltip: 'التقويم',
            ),

            // ============================================================
            // الثلاث نقاط
            // ============================================================
            PopupMenuButton<String>(
              tooltip: 'المزيد',
              icon: Icon(Icons.more_vert, color: textDark),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              offset: const Offset(0, 8),

              onSelected: (value) async {
                // ========================================================
                // الملاحظات المخفية
                // ========================================================

                if (value == 'hidden') {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HiddenNotesPage(),
                    ),
                  );

                  if (!mounted) return;

                  await getNotes();
                }

                // ========================================================
                // الملاحظات المثبتة
                // ========================================================

                if (value == 'pinned') {
                  await Navigator.of(context).pushNamed('PinnedNotesPage');

                  if (!mounted) return;

                  await getNotes();
                }

                // ========================================================
                // تحديث
                // ========================================================

                if (value == 'refresh') {
                  await loadData();
                }
              },

              itemBuilder: (context) => [
                // ========================================================
                // الملاحظات المخفية
                // ========================================================
                const PopupMenuItem<String>(
                  value: 'hidden',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        color: Color(0xFF555555),
                        size: 21,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'الملاحظات المخفية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ========================================================
                // الملاحظات المثبتة
                // ========================================================
                const PopupMenuItem<String>(
                  value: 'pinned',
                  child: Row(
                    children: [
                      Icon(
                        Icons.push_pin_outlined,
                        color: Color(0xFF555555),
                        size: 21,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'الملاحظات المثبتة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ========================================================
                // تحديث
                // ========================================================
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Color(0xFF555555), size: 21),
                      SizedBox(width: 12),
                      Text(
                        'تحديث',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // ======================================================
        // زر إضافة ملاحظة
        // ======================================================
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openAddNote,
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 5,
          icon: const Icon(Icons.add),
          label: const Text(
            'ملاحظة جديدة',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        // ======================================================
        // Body
        // ======================================================
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // ------------------------------------------
                      // التصنيفات
                      // ------------------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'التصنيفات',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      buildCategories(),

                      const SizedBox(height: 20),

                      // ------------------------------------------
                      // عنوان الملاحظات
                      // ------------------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'الملاحظات',
                              style: TextStyle(
                                color: textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notes.length}',
                                style: TextStyle(
                                  color: blue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      // ------------------------------------------
                      // الملاحظات
                      // ------------------------------------------
                      buildNotes(),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
