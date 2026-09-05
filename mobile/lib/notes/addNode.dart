import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  // ============================================================
  // الألوان
  // ============================================================

  static const Color paperColor = Color(0xFFFFFBE6);
  static const Color textColor = Color(0xFF292929);
  static const Color secondaryText = Color(0xFF817A60);
  static const Color accentColor = Color(0xFFFFA000);

  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final FocusNode titleFocusNode = FocusNode();
  final FocusNode contentFocusNode = FocusNode();

  // ============================================================
  // بيانات الملاحظة
  // ============================================================

  final DateTime createdAt = DateTime.now();

  String? selectedCategory;

  List<String> categories = [];

  bool isLoadingCategories = true;
  bool isSaving = false;

  // ============================================================
  // Undo / Redo
  // ============================================================

  String _redoTitle = '';
  String _redoContent = '';

  // ============================================================
  // Helpers
  // ============================================================

  bool get hasTitle {
    return titleController.text.trim().isNotEmpty;
  }

  bool get hasContent {
    return contentController.text.trim().isNotEmpty;
  }

  bool get hasAnyText {
    return hasTitle || hasContent;
  }

  bool get canRedo {
    return _redoTitle.isNotEmpty || _redoContent.isNotEmpty;
  }

  // ============================================================
  // initState
  // ============================================================

  @override
  void initState() {
    super.initState();

    fetchCategories();

    titleController.addListener(_onTextChanged);
    contentController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      titleFocusNode.requestFocus();
    });
  }

  // ============================================================
  // مراقبة الكتابة
  // ============================================================

  void _onTextChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // جلب التصنيفات
  // ============================================================

  Future<void> fetchCategories() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('categories')
              .orderBy('createdAt', descending: false)
              .get();

      final List<String> loadedCategories = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final String name = (data['name'] ?? '').toString().trim();

        if (name.isNotEmpty && !loadedCategories.contains(name)) {
          loadedCategories.add(name);
        }
      }

      if (!mounted) return;

      setState(() {
        categories = loadedCategories;
        isLoadingCategories = false;
      });

      debugPrint('عدد التصنيفات: ${categories.length}');
      debugPrint('التصنيفات: $categories');
    } catch (e) {
      debugPrint('خطأ في جلب التصنيفات: $e');

      // إذا كان orderBy يسبب مشكلة بسبب createdAt،
      // نعيد القراءة بدون ترتيب.
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance.collection('categories').get();

        final List<String> loadedCategories = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final String name = (data['name'] ?? '').toString().trim();

          if (name.isNotEmpty && !loadedCategories.contains(name)) {
            loadedCategories.add(name);
          }
        }

        if (!mounted) return;

        setState(() {
          categories = loadedCategories;
          isLoadingCategories = false;
        });

        debugPrint('التصنيفات بعد المحاولة الثانية: $categories');
      } catch (e2) {
        debugPrint('خطأ المحاولة الثانية: $e2');

        if (!mounted) return;

        setState(() {
          categories = [];
          isLoadingCategories = false;
        });
      }
    }
  }

  // ============================================================
  // حفظ الملاحظة
  // ============================================================

  Future<void> saveNote() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    final String title = titleController.text.trim();
    final String content = contentController.text.trim();

    if (!hasAnyText) {
      _showMessage('اكتب شيئًا في الملاحظة أولاً');
      return;
    }

    if (!hasTitle) {
      _showMessage('الرجاء كتابة عنوان الملاحظة');

      if (mounted) {
        titleFocusNode.requestFocus();
      }

      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('يجب تسجيل الدخول أولاً', isError: true);

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('notes').add({
        'title': title,
        'content': content,
        'category': selectedCategory ?? 'غير مصنف',
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isFavorite': false,
      });

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('saveNote error: $e');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage('حدث خطأ أثناء حفظ الملاحظة', isError: true);
    }
  }

  // ============================================================
  // رسالة
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // اختيار التصنيف
  // ============================================================

  void showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: paperColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // المقبض
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: secondaryText.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // العنوان
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'اختر التصنيف',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // غير مصنف
                    _categoryItem(
                      name: 'غير مصنف',
                      selected:
                          selectedCategory == null ||
                          selectedCategory == 'غير مصنف',
                      onTap: () {
                        setState(() {
                          selectedCategory = null;
                        });

                        Navigator.pop(bottomSheetContext);
                      },
                    ),

                    const SizedBox(height: 4),

                    // التصنيفات
                    if (isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    else if (categories.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              color: secondaryText,
                              size: 38,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'لا توجد تصنيفات أخرى',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...categories.map((String category) {
                        return _categoryItem(
                          name: category,
                          selected: selectedCategory == category,
                          onTap: () {
                            setState(() {
                              selectedCategory = category;
                            });

                            Navigator.pop(bottomSheetContext);
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // عنصر التصنيف
  // ============================================================

  Widget _categoryItem({
    required String name,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.75)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: accentColor.withOpacity(0.25))
                : null,
          ),
          child: Row(
            children: [
              // أيقونة المجلد
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? accentColor.withOpacity(0.12)
                      : Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  name == 'غير مصنف'
                      ? Icons.folder_off_outlined
                      : Icons.folder_outlined,
                  color: accentColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              // اسم التصنيف
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),

              // علامة الاختيار
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: accentColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Undo
  // ============================================================

  void undoText() {
    if (!hasAnyText) {
      return;
    }

    _redoTitle = titleController.text;
    _redoContent = contentController.text;

    final String currentTitle = titleController.text;
    final String currentContent = contentController.text;

    if (currentContent.isNotEmpty) {
      contentController.text = currentContent.substring(
        0,
        currentContent.length - 1,
      );

      contentController.selection = TextSelection.collapsed(
        offset: contentController.text.length,
      );
    } else if (currentTitle.isNotEmpty) {
      titleController.text = currentTitle.substring(0, currentTitle.length - 1);

      titleController.selection = TextSelection.collapsed(
        offset: titleController.text.length,
      );
    }

    setState(() {});
  }

  // ============================================================
  // Redo
  // ============================================================

  void redoText() {
    if (!canRedo) {
      _showMessage('لا يوجد شيء لإعادته');
      return;
    }

    titleController.text = _redoTitle;
    contentController.text = _redoContent;

    titleController.selection = TextSelection.collapsed(
      offset: titleController.text.length,
    );

    contentController.selection = TextSelection.collapsed(
      offset: contentController.text.length,
    );

    _redoTitle = '';
    _redoContent = '';

    setState(() {});
  }

  // ============================================================
  // مشاركة
  // ============================================================

  void shareNote() {
    final String title = titleController.text.trim();
    final String content = contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      _showMessage('لا توجد ملاحظة لمشاركتها');
      return;
    }

    _showMessage('ميزة المشاركة تحتاج إلى ربط share_plus');
  }

  // ============================================================
  // القائمة
  // ============================================================

  void showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: paperColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: secondaryText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _moreOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'مسح الملاحظة',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _clearNote();
                    },
                  ),

                  _moreOption(
                    icon: Icons.push_pin_outlined,
                    title: 'تثبيت الملاحظة',
                    onTap: () {
                      Navigator.pop(sheetContext);

                      _showMessage('يمكن تفعيل التثبيت لاحقًا');
                    },
                  ),

                  _moreOption(
                    icon: Icons.star_border_rounded,
                    title: 'إضافة إلى المفضلة',
                    onTap: () {
                      Navigator.pop(sheetContext);

                      _showMessage('يمكن تفعيل المفضلة لاحقًا');
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
  // عناصر القائمة
  // ============================================================

  Widget _moreOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 23),

              const SizedBox(width: 14),

              Text(
                title,
                style: const TextStyle(color: textColor, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // مسح الملاحظة
  // ============================================================

  void _clearNote() {
    titleController.clear();
    contentController.clear();

    _redoTitle = '';
    _redoContent = '';

    setState(() {});

    titleFocusNode.requestFocus();
  }

  // ============================================================
  // زر الأدوات
  // ============================================================

  Widget _toolButton({
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: enabled
                ? textColor.withOpacity(0.8)
                : textColor.withOpacity(0.25),
            size: 21,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // الشريط السفلي
  // ============================================================

  Widget _buildBottomToolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // تنسيق
            _toolButton(
              icon: Icons.text_fields_rounded,
              onTap: _showFormatting,
            ),

            // نقاط
            _toolButton(
              icon: Icons.format_list_bulleted_rounded,
              onTap: () {
                _insertText('\n• ');
              },
            ),

            // قائمة تحقق
            _toolButton(
              icon: Icons.check_box_outlined,
              onTap: () {
                _insertText('\n☐ ');
              },
            ),

            // شطب
            _toolButton(
              icon: Icons.strikethrough_s_rounded,
              onTap: () {
                _showMessage('تنسيق النص المتقدم قريبًا');
              },
            ),

            // إيموجي
            _toolButton(
              icon: Icons.emoji_emotions_outlined,
              onTap: () {
                _insertText(' 😊');
              },
            ),

            // صورة
            _toolButton(
              icon: Icons.image_outlined,
              onTap: () {
                _showComingSoon('إضافة صورة');
              },
            ),

            // ملف
            _toolButton(
              icon: Icons.attach_file_rounded,
              onTap: () {
                _showComingSoon('إرفاق ملف');
              },
            ),

            // تسجيل
            _toolButton(
              icon: Icons.mic_none_rounded,
              onTap: () {
                _showComingSoon('التسجيل الصوتي');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // إدخال نص
  // ============================================================

  void _insertText(String text) {
    final String current = contentController.text;

    final TextSelection selection = contentController.selection;

    if (!selection.isValid) {
      contentController.text = current + text;

      contentController.selection = TextSelection.collapsed(
        offset: contentController.text.length,
      );
    } else {
      final int start = selection.start.clamp(0, current.length);

      final int end = selection.end.clamp(0, current.length);

      final String newText = current.replaceRange(start, end, text);

      contentController.text = newText;

      contentController.selection = TextSelection.collapsed(
        offset: start + text.length,
      );
    }

    contentFocusNode.requestFocus();
  }

  // ============================================================
  // التنسيق
  // ============================================================

  void _showFormatting() {
    showModalBottomSheet(
      context: context,
      backgroundColor: paperColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: secondaryText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'تنسيق النص',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _formatItem(text: 'B', bold: true),
                      _formatItem(text: 'I', italic: true),
                      _formatItem(text: 'U', underline: true),
                      _formatItem(text: 'Aa'),
                    ],
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // زر التنسيق
  // ============================================================

  Widget _formatItem({
    required String text,
    bool bold = false,
    bool italic = false,
    bool underline = false,
  }) {
    return Container(
      width: 55,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Coming Soon
  // ============================================================

  void _showComingSoon(String feature) {
    _showMessage('$feature ستكون متاحة قريبًا');
  }

  // ============================================================
  // التاريخ
  // ============================================================

  String getFormattedDate() {
    final DateTime date = createdAt;
    final DateTime now = DateTime.now();

    final bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final String time = _formatTime(date);

    if (isToday) {
      return 'اليوم، $time';
    }

    return '${date.day}/${date.month}/${date.year}، $time';
  }

  // ============================================================
  // الوقت
  // ============================================================

  String _formatTime(DateTime date) {
    int hour = date.hour;

    final String minute = date.minute.toString().padLeft(2, '0');

    final String period = hour >= 12 ? 'م' : 'ص';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }

  // ============================================================
  // dispose
  // ============================================================

  @override
  void dispose() {
    titleController.removeListener(_onTextChanged);
    contentController.removeListener(_onTextChanged);

    titleController.dispose();
    contentController.dispose();

    titleFocusNode.dispose();
    contentFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool noteHasText = hasAnyText;
    final bool redoAvailable = canRedo;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: paperColor,
        resizeToAvoidBottomInset: true,

        // ========================================================
        // AppBar
        // ========================================================
        appBar: AppBar(
          backgroundColor: paperColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 62,
          titleSpacing: 3,

          title: Row(
            children: [
              // المزيد
              IconButton(
                tooltip: 'المزيد',
                onPressed: isSaving ? null : showMoreOptions,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: textColor,
                  size: 24,
                ),
              ),

              // مشاركة
              IconButton(
                tooltip: 'مشاركة',
                onPressed: isSaving ? null : shareNote,
                icon: const Icon(
                  Icons.ios_share_rounded,
                  color: textColor,
                  size: 21,
                ),
              ),

              // Undo
              IconButton(
                tooltip: 'تراجع',
                onPressed: isSaving || !noteHasText ? null : undoText,
                icon: Icon(
                  Icons.undo_rounded,
                  color: !noteHasText ? textColor.withOpacity(0.25) : textColor,
                  size: 22,
                ),
              ),

              // Redo
              IconButton(
                tooltip: 'إعادة',
                onPressed: isSaving || !redoAvailable ? null : redoText,
                icon: Icon(
                  Icons.redo_rounded,
                  color: !redoAvailable
                      ? textColor.withOpacity(0.25)
                      : textColor,
                  size: 22,
                ),
              ),

              const Spacer(),

              // ==================================================
              // التصنيف
              // ==================================================
              GestureDetector(
                onTap: isSaving ? null : showCategoryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        color: secondaryText,
                        size: 17,
                      ),

                      const SizedBox(width: 4),

                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: Text(
                          selectedCategory ?? 'غير مصنف',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: secondaryText,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 3),

              // رجوع
              IconButton(
                tooltip: 'رجوع',
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textColor,
                  size: 19,
                ),
              ),

              // حفظ
              GestureDetector(
                onTap: isSaving ? null : saveNote,
                child: Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isSaving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            color: accentColor,
                            size: 27,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // Body
        // ========================================================
        body: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // التاريخ
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 2, 22, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: secondaryText,
                      size: 14,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      getFormattedDate(),
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // الكتابة
              // ==================================================
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==================================================
                      // العنوان
                      // ==================================================
                      TextField(
                        controller: titleController,
                        focusNode: titleFocusNode,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'العنوان',
                          hintStyle: TextStyle(
                            color: Color(0xFFB5AD87),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (_) {
                          contentFocusNode.requestFocus();
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // المحتوى
                      // ==================================================
                      TextField(
                        controller: contentController,
                        focusNode: contentFocusNode,
                        minLines: 18,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          height: 1.7,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'أدخل محتوى الملاحظة هنا',
                          hintStyle: TextStyle(
                            color: Color(0xFFB5AD87),
                            fontSize: 17,
                            height: 1.7,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // الأدوات
              // ==================================================
              _buildBottomToolbar(),
            ],
          ),
        ),
      ),
    );
  }
}
