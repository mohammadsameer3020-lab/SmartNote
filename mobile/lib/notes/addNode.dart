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

  static const Color paperColor = Color(0xFFFFFDF2);
  static const Color surfaceColor = Color(0xFFFFFEF8);

  static const Color textColor = Color(0xFF292929);
  static const Color secondaryText = Color(0xFF817A60);
  static const Color lightText = Color(0xFFADA68B);

  static const Color accentColor = Color(0xFFFFA000);
  static const Color accentLight = Color(0xFFFFF2D2);

  static const Color dividerColor = Color(0xFFEFEAD7);

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

  String _previousTitle = '';
  String _previousContent = '';

  String _redoTitle = '';
  String _redoContent = '';

  // ============================================================
  // حالة الواجهة
  // ============================================================

  bool get hasTitle => titleController.text.trim().isNotEmpty;

  bool get hasContent => contentController.text.trim().isNotEmpty;

  bool get hasAnyText => hasTitle || hasContent;

  bool get canUndo =>
      _previousTitle.isNotEmpty || _previousContent.isNotEmpty || hasAnyText;

  bool get canRedo => _redoTitle.isNotEmpty || _redoContent.isNotEmpty;

  // ============================================================
  // Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    titleController.addListener(_onTextChanged);

    contentController.addListener(_onTextChanged);

    fetchCategories();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      titleFocusNode.requestFocus();
    });
  }

  // ============================================================
  // مراقبة النص
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
      QuerySnapshot<Map<String, dynamic>> snapshot;

      try {
        snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .orderBy('createdAt', descending: false)
            .get();
      } catch (_) {
        snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .get();
      }

      final List<String> loadedCategories = [];

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

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
    } catch (e) {
      debugPrint('fetchCategories error: $e');

      if (!mounted) return;

      setState(() {
        categories = [];
        isLoadingCategories = false;
      });
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

    // ----------------------------------------
    // التحقق من البيانات
    // ----------------------------------------

    if (title.isEmpty && content.isEmpty) {
      _showMessage('اكتب شيئًا في الملاحظة أولاً');
      return;
    }

    if (title.isEmpty) {
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
  // الرسائل
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.redAccent : textColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // المقبض
                    _buildSheetHandle(),

                    const SizedBox(height: 20),

                    // العنوان
                    Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: accentLight,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.folder_open_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تصنيف الملاحظة',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'اختر مكان حفظ الملاحظة',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

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

                        Navigator.pop(sheetContext);
                      },
                    ),

                    if (isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 35),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: accentColor,
                        ),
                      )
                    else if (categories.isEmpty)
                      _buildEmptyCategories()
                    else ...[
                      const SizedBox(height: 5),
                      ...categories.map((String category) {
                        return _categoryItem(
                          name: category,
                          selected: selectedCategory == category,
                          onTap: () {
                            setState(() {
                              selectedCategory = category;
                            });

                            Navigator.pop(sheetContext);
                          },
                        );
                      }),
                    ],
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
  // المقبض
  // ============================================================

  Widget _buildSheetHandle() {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: secondaryText.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accentLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accentColor.withOpacity(0.18) : dividerColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFFFFFCF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  name == 'غير مصنف'
                      ? Icons.folder_off_outlined
                      : Icons.folder_outlined,
                  color: accentColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),

              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: accentColor,
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // لا توجد تصنيفات
  // ============================================================

  Widget _buildEmptyCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            color: secondaryText.withOpacity(0.65),
            size: 38,
          ),
          const SizedBox(height: 9),
          const Text(
            'لا توجد تصنيفات أخرى',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

    final String title = titleController.text;

    final String content = contentController.text;

    // نحفظ الحالة الحالية
    _previousTitle = title;
    _previousContent = content;

    // إزالة آخر حرف من المحتوى أولاً
    if (content.isNotEmpty) {
      contentController.text = content.substring(0, content.length - 1);

      contentController.selection = TextSelection.collapsed(
        offset: contentController.text.length,
      );
    } else if (title.isNotEmpty) {
      titleController.text = title.substring(0, title.length - 1);

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

    _previousTitle = '';
    _previousContent = '';

    _redoTitle = '';
    _redoContent = '';

    setState(() {});
  }

  // ============================================================
  // مشاركة
  // ============================================================

  void shareNote() {
    if (!hasAnyText) {
      _showMessage('لا توجد ملاحظة لمشاركتها');
      return;
    }

    _showMessage('ميزة المشاركة تحتاج إلى ربط share_plus');
  }

  // ============================================================
  // المزيد
  // ============================================================

  void showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),

                  const SizedBox(height: 18),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'خيارات الملاحظة',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

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

                      _showMessage('يمكن تفعيل التثبيت بعد حفظ الملاحظة');
                    },
                  ),

                  _moreOption(
                    icon: Icons.star_border_rounded,
                    title: 'إضافة إلى المفضلة',
                    onTap: () {
                      Navigator.pop(sheetContext);

                      _showMessage('يمكن تفعيل المفضلة بعد حفظ الملاحظة');
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
  // عنصر القائمة
  // ============================================================

  Widget _moreOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: textColor, size: 21),
              ),

              const SizedBox(width: 12),

              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // مسح النص
  // ============================================================

  void _clearNote() {
    titleController.clear();
    contentController.clear();

    _previousTitle = '';
    _previousContent = '';
    _redoTitle = '';
    _redoContent = '';

    titleFocusNode.requestFocus();

    setState(() {});
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
  // أدوات النص
  // ============================================================

  void _showFormatting() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),

                  const SizedBox(height: 19),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'تنسيق النص',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(child: _formatItem(text: 'B', bold: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _formatItem(text: 'I', italic: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _formatItem(text: 'U', underline: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _formatItem(text: 'Aa')),
                    ],
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
  // زر التنسيق
  // ============================================================

  Widget _formatItem({
    required String text,
    bool bold = false,
    bool italic = false,
    bool underline = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.pop(context);
          _showMessage('تنسيق النص المتقدم قريبًا');
        },
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                decoration: underline
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: enabled
                ? textColor.withOpacity(0.78)
                : textColor.withOpacity(0.22),
            size: 21,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // شريط الأدوات السفلي
  // ============================================================

  Widget _buildBottomToolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolButton(
              icon: Icons.text_fields_rounded,
              onTap: _showFormatting,
            ),

            _toolButton(
              icon: Icons.format_list_bulleted_rounded,
              onTap: () {
                _insertText('\n• ');
              },
            ),

            _toolButton(
              icon: Icons.check_box_outlined,
              onTap: () {
                _insertText('\n☐ ');
              },
            ),

            _toolButton(
              icon: Icons.strikethrough_s_rounded,
              onTap: () {
                _showMessage('تنسيق النص المتقدم قريبًا');
              },
            ),

            _toolButton(
              icon: Icons.emoji_emotions_outlined,
              onTap: () {
                _insertText(' 😊');
              },
            ),

            _toolButton(
              icon: Icons.image_outlined,
              onTap: () {
                _showComingSoon('إضافة صورة');
              },
            ),

            _toolButton(
              icon: Icons.attach_file_rounded,
              onTap: () {
                _showComingSoon('إرفاق ملف');
              },
            ),

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
  // ميزات مستقبلية
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

    final bool today =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final String time = _formatTime(date);

    if (today) {
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
  // Header
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 7, 13, 4),
      child: Row(
        children: [
          // ==============================================
          // الرجوع
          // ==============================================
          _headerIconButton(
            icon: Icons.arrow_forward_ios_rounded,
            tooltip: 'رجوع',
            onTap: isSaving
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
          ),

          const SizedBox(width: 3),

          // ==============================================
          // العنوان
          // ==============================================
          const Expanded(
            child: Text(
              'ملاحظة جديدة',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // ==============================================
          // المزيد
          // ==============================================
          _headerIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: 'المزيد',
            onTap: isSaving ? null : showMoreOptions,
          ),

          // ==============================================
          // مشاركة
          // ==============================================
          _headerIconButton(
            icon: Icons.ios_share_outlined,
            tooltip: 'مشاركة',
            onTap: isSaving ? null : shareNote,
          ),

          // ==============================================
          // Undo
          // ==============================================
          _headerIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'تراجع',
            enabled: hasAnyText,
            onTap: isSaving || !hasAnyText ? null : undoText,
          ),

          // ==============================================
          // Redo
          // ==============================================
          _headerIconButton(
            icon: Icons.redo_rounded,
            tooltip: 'إعادة',
            enabled: canRedo,
            onTap: isSaving || !canRedo ? null : redoText,
          ),

          const SizedBox(width: 4),

          // ==============================================
          // حفظ
          // ==============================================
          GestureDetector(
            onTap: isSaving ? null : saveNote,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    : const Icon(
                        Icons.check_rounded,
                        color: accentColor,
                        size: 26,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // زر Header
  // ============================================================

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? textColor.withOpacity(0.78)
                  : textColor.withOpacity(0.22),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // التصنيف + التاريخ
  // ============================================================

  Widget _buildNoteMeta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
      child: Row(
        children: [
          // ==============================================
          // التصنيف
          // ==============================================
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              onTap: isSaving ? null : showCategoryPicker,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      color: secondaryText,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        selectedCategory ?? 'غير مصنف',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: secondaryText,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ==============================================
          // خط فاصل
          // ==============================================
          Container(width: 1, height: 17, color: dividerColor),

          const SizedBox(width: 10),

          // ==============================================
          // التاريخ
          // ==============================================
          const Icon(Icons.access_time_rounded, color: secondaryText, size: 14),

          const SizedBox(width: 5),

          Expanded(
            child: Text(
              getFormattedDate(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Body
  // ============================================================

  Widget _buildEditor() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(22, 17, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==============================================
          // العنوان
          // ==============================================
          TextField(
            controller: titleController,
            focusNode: titleFocusNode,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              color: textColor,
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              hintText: 'عنوان الملاحظة',
              hintStyle: TextStyle(
                color: lightText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onSubmitted: (_) {
              contentFocusNode.requestFocus();
            },
          ),

          const SizedBox(height: 15),

          // ==============================================
          // المحتوى
          // ==============================================
          TextField(
            controller: contentController,
            focusNode: contentFocusNode,
            minLines: 20,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textColor,
              fontSize: 17,
              height: 1.75,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              hintText: 'ابدأ بكتابة ملاحظتك...',
              hintStyle: TextStyle(
                color: lightText,
                fontSize: 17,
                height: 1.75,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Dispose
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: paperColor,
        resizeToAvoidBottomInset: true,

        // ======================================================
        // AppBar
        // ======================================================
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: SafeArea(bottom: false, child: _buildTopBar()),
        ),

        // ======================================================
        // Body
        // ======================================================
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // -----------------------------------------------
              // معلومات الملاحظة
              // -----------------------------------------------
              _buildNoteMeta(),

              const SizedBox(height: 4),

              // -----------------------------------------------
              // خط بسيط
              // -----------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(height: 1, color: dividerColor),
              ),

              // -----------------------------------------------
              // المحرر
              // -----------------------------------------------
              Expanded(child: _buildEditor()),

              // -----------------------------------------------
              // أدوات الكتابة
              // -----------------------------------------------
              _buildBottomToolbar(),
            ],
          ),
        ),
      ),
    );
  }
}
