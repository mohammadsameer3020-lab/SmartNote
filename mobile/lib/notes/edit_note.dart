import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/note_model.dart';

class EditNote extends StatefulWidget {
  final NoteModel note;

  const EditNote({super.key, required this.note});

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  // =========================
  // الألوان
  // =========================

  static const Color creamyBackground = Color(0xFFFAF6E9);
  static const Color titleColor = Color(0xFF8B8155);
  static const Color hintColor = Color(0xFFB5A882);
  static const Color accentColor = Color(0xFFFFB300);

  // =========================
  // Controllers
  // =========================

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // =========================
  // التصنيفات
  // =========================

  List<String> _categories = [];

  String _selectedCategory = 'غير مصنف';

  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note.title);

    _contentController = TextEditingController(text: widget.note.content);

    // التصنيف الموجود مع الملاحظة
    final String currentCategory = widget.note.category.trim();

    if (currentCategory.isNotEmpty) {
      _selectedCategory = currentCategory;
    } else {
      _selectedCategory = 'غير مصنف';
    }

    // جلب التصنيفات من Firestore
    _fetchCategories();
  }

  // =========================================================
  // جلب التصنيفات من Firestore
  // =========================================================

  Future<void> _fetchCategories() async {
    try {
      debugPrint('==============================');
      debugPrint('بدء جلب التصنيفات...');
      debugPrint('Collection: categories');

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      debugPrint('عدد مستندات التصنيفات: ${snapshot.docs.length}');

      final List<String> loadedCategories = [];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        debugPrint('Category Document: ${doc.id}');

        debugPrint('Category Data: $data');

        // التصنيفات عندك تحفظ في الحقل name
        final dynamic rawName = data['name'];

        if (rawName == null) {
          continue;
        }

        final String name = rawName.toString().trim();

        if (name.isEmpty) {
          continue;
        }

        if (!loadedCategories.contains(name)) {
          loadedCategories.add(name);
        }
      }

      // إضافة "غير مصنف" دائمًا في البداية
      if (!loadedCategories.contains('غير مصنف')) {
        loadedCategories.insert(0, 'غير مصنف');
      }

      // إذا كان تصنيف الملاحظة غير موجود في Firestore
      // نضيفه للقائمة حتى لا يختفي
      if (_selectedCategory != 'غير مصنف' &&
          !loadedCategories.contains(_selectedCategory)) {
        loadedCategories.add(_selectedCategory);
      }

      if (!mounted) return;

      setState(() {
        _categories = loadedCategories;
        _isLoadingCategories = false;
      });

      debugPrint('التصنيفات النهائية: $_categories');

      debugPrint('انتهى جلب التصنيفات');
      debugPrint('==============================');
    } catch (e) {
      debugPrint('ERROR FETCHING CATEGORIES: $e');

      if (!mounted) return;

      setState(() {
        _categories = ['غير مصنف'];

        if (_selectedCategory != 'غير مصنف') {
          _categories.add(_selectedCategory);
        }

        _isLoadingCategories = false;
      });
    }
  }

  // =========================================================
  // تحديث الملاحظة
  // =========================================================

  Future<void> _updateNote() async {
    final String title = _titleController.text.trim();

    final String content = _contentController.text.trim();

    // إذا كانت الملاحظة فارغة
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.note.id)
          .update({
            'title': title,
            'content': content,

            // حفظ التصنيف
            'category': _selectedCategory == 'غير مصنف'
                ? ''
                : _selectedCategory,

            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error updating note: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تعديل الملاحظة',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // اختيار التصنيف
  // =========================================================

  void _showCategoryPicker() {
    if (_isLoadingCategories) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: creamyBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // المقبض العلوي
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // العنوان
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_outlined,
                          color: accentColor,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'اختر التصنيف',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // قائمة التصنيفات
                  if (_categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(25),
                      child: Text(
                        'لا توجد تصنيفات',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 5),
                        itemBuilder: (BuildContext context, int index) {
                          final String category = _categories[index];

                          final bool isSelected = category == _selectedCategory;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });

                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accentColor.withOpacity(0.13)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? accentColor.withOpacity(0.35)
                                        : Colors.black.withOpacity(0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? accentColor.withOpacity(0.18)
                                            : Colors.white.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        category == 'غير مصنف'
                                            ? Icons.folder_off_outlined
                                            : Icons.folder_outlined,
                                        color: isSelected
                                            ? accentColor
                                            : Colors.black54,
                                        size: 21,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),

                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: accentColor,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // التاريخ والوقت
  // =========================================================

  String _getDateTimeText() {
    try {
      final dynamic createdAt = widget.note.createdAt;

      if (createdAt == null) {
        return 'اليوم';
      }

      if (createdAt is Timestamp) {
        final DateTime date = createdAt.toDate();

        final int hour = date.hour;
        final int minute = date.minute;

        final String formattedHour = hour.toString();

        final String formattedMinute = minute.toString().padLeft(2, '0');

        return 'اليوم، $formattedHour:$formattedMinute';
      }

      return 'اليوم';
    } catch (e) {
      debugPrint('Date error: $e');

      return 'اليوم';
    }
  }

  // =========================================================
  // Dispose
  // =========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: creamyBackground,

        // ================================================
        // AppBar
        // ================================================
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,

          automaticallyImplyLeading: false,

          // علامة الصح للحفظ
          leading: IconButton(
            onPressed: _isLoading ? null : _updateNote,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ),

          title: Row(
            children: [
              // زر الرجوع
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black54,
                  size: 20,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context, false);
                      },
              ),

              const SizedBox(width: 4),

              // التصنيف
              GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLoadingCategories
                            ? 'جاري التحميل...'
                            : _selectedCategory,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(width: 4),

                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          actions: [
            // Undo
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.black54, size: 22),
              onPressed: () {},
            ),

            // Redo
            IconButton(
              icon: const Icon(Icons.redo, color: Colors.black54, size: 22),
              onPressed: () {},
            ),

            // Share
            IconButton(
              icon: const Icon(
                Icons.share_outlined,
                color: Colors.black54,
                size: 22,
              ),
              onPressed: () {},
            ),

            // More
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black54),
              onPressed: () {},
            ),
          ],
        ),

        // ================================================
        // Body
        // ================================================
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ======================================
                    // التاريخ والوقت
                    // ======================================
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getDateTimeText(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(width: 4),

                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ======================================
                    // العنوان
                    // ======================================
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'العنوان',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ======================================
                    // المحتوى
                    // ======================================
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'أدخل محتوى الملاحظة هنا',
                          hintStyle: TextStyle(color: hintColor, fontSize: 16),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
