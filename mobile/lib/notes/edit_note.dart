import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/models/note_model.dart';

class EditNote extends StatefulWidget {
  final NoteModel note;

  const EditNote({super.key, required this.note});

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  // =========================================================
  // الألوان
  // =========================================================

  static const Color creamyBackground = Color(0xFFFAF6E9);
  static const Color titleColor = Color(0xFF8B8155);
  static const Color hintColor = Color(0xFFB5A882);
  static const Color accentColor = Color(0xFFFFB300);

  // =========================================================
  // Controllers
  // =========================================================

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // =========================================================
  // التصنيفات
  // =========================================================

  List<String> _categories = [];

  String _selectedCategory = 'غير مصنف';

  // =========================================================
  // حالات الصفحة
  // =========================================================

  bool _isLoading = false;
  bool _isLoadingCategories = true;

  // =========================================================
  // المستخدم الحالي
  // =========================================================

  User? get _currentUser {
    return FirebaseAuth.instance.currentUser;
  }

  // =========================================================
  // initState
  // =========================================================

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note.title);

    _contentController = TextEditingController(text: widget.note.content);

    final String currentCategory = widget.note.category.trim();

    if (currentCategory.isNotEmpty) {
      _selectedCategory = currentCategory;
    } else {
      _selectedCategory = 'غير مصنف';
    }

    _fetchCategories();
  }

  // =========================================================
  // جلب تصنيفات المستخدم الحالي
  // =========================================================

  Future<void> _fetchCategories() async {
    try {
      final User? user = _currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _categories = ['غير مصنف'];
          _isLoadingCategories = false;
        });

        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('categories')
              .where('uid', isEqualTo: user.uid)
              .get();

      final List<String> loadedCategories = ['غير مصنف'];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        final dynamic rawName = data['name'];

        if (rawName == null) {
          continue;
        }

        final String categoryName = rawName.toString().trim();

        if (categoryName.isEmpty) {
          continue;
        }

        final bool alreadyExists = loadedCategories.any(
          (category) =>
              category.trim().toLowerCase() ==
              categoryName.trim().toLowerCase(),
        );

        if (!alreadyExists) {
          loadedCategories.add(categoryName);
        }
      }

      // إذا كان التصنيف الحالي للملاحظة غير موجود
      // نضيفه مؤقتًا حتى لا يختفي من الاختيار.
      if (_selectedCategory != 'غير مصنف') {
        final bool currentCategoryExists = loadedCategories.any(
          (category) =>
              category.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase(),
        );

        if (!currentCategoryExists) {
          loadedCategories.add(_selectedCategory);
        }
      }

      if (!mounted) return;

      setState(() {
        _categories = loadedCategories;
        _isLoadingCategories = false;
      });
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

      _showMessage('تعذر تحميل التصنيفات');
    }
  }

  // =========================================================
  // التحقق من ملكية الملاحظة
  // =========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> _getAuthorizedNote() async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception('USER_NOT_LOGGED_IN');
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(widget.note.id)
            .get();

    if (!snapshot.exists) {
      throw Exception('NOTE_NOT_FOUND');
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      throw Exception('NOTE_DATA_NOT_FOUND');
    }

    final String noteUserId = data['userId']?.toString() ?? '';

    if (noteUserId.isEmpty || noteUserId != user.uid) {
      throw Exception('UNAUTHORIZED');
    }

    return snapshot;
  }

  // =========================================================
  // تحديث نص الملاحظة
  // =========================================================

  Future<void> _updateNote() async {
    if (_isLoading) {
      return;
    }

    final User? user = _currentUser;

    if (user == null) {
      _showMessage('يجب تسجيل الدخول أولاً');
      return;
    }

    final String title = _titleController.text.trim();

    final String content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      _showMessage('لا يمكن حفظ ملاحظة فارغة');
      return;
    }

    FocusScope.of(context).unfocus();

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _getAuthorizedNote();

      final String categoryToSave = _selectedCategory.trim() == 'غير مصنف'
          ? ''
          : _selectedCategory.trim();

      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.note.id)
          .update({
            'title': title,
            'content': content,
            'category': categoryToSave,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ERROR UPDATING NOTE: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _handleFirestoreError(e);
    }
  }

  // =========================================================
  // تثبيت / إلغاء تثبيت
  // =========================================================

  Future<void> _togglePinned() async {
    if (_isLoading) return;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _getAuthorizedNote();

      final Map<String, dynamic> data = snapshot.data() ?? {};

      final bool currentPinned = data['isPinned'] == true;

      final bool newPinned = !currentPinned;

      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.note.id)
          .update({
            'isPinned': newPinned,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      _showMessage(newPinned ? 'تم تثبيت الملاحظة' : 'تم إلغاء تثبيت الملاحظة');

      setState(() {});
    } catch (e) {
      debugPrint('ERROR TOGGLE PINNED: $e');

      _handleFirestoreError(e);
    }
  }

  // =========================================================
  // إخفاء / إظهار
  // =========================================================

  Future<void> _toggleHidden() async {
    if (_isLoading) return;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _getAuthorizedNote();

      final Map<String, dynamic> data = snapshot.data() ?? {};

      final bool currentHidden = data['isHidden'] == true;

      final bool newHidden = !currentHidden;

      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.note.id)
          .update({
            'isHidden': newHidden,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      _showMessage(newHidden ? 'تم إخفاء الملاحظة' : 'تم إظهار الملاحظة');

      setState(() {});
    } catch (e) {
      debugPrint('ERROR TOGGLE HIDDEN: $e');

      _handleFirestoreError(e);
    }
  }

  // =========================================================
  // نسخ الملاحظة
  // =========================================================

  Future<void> _copyNote() async {
    final String title = _titleController.text.trim();

    final String content = _contentController.text.trim();

    String text = '';

    if (title.isNotEmpty) {
      text += title;
    }

    if (content.isNotEmpty) {
      if (text.isNotEmpty) {
        text += '\n\n';
      }

      text += content;
    }

    if (text.isEmpty) {
      _showMessage('لا يوجد محتوى لنسخه');
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    _showMessage('تم نسخ الملاحظة');
  }

  // =========================================================
  // حذف الملاحظة
  // =========================================================

  Future<void> _deleteNote() async {
    if (_isLoading) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: creamyBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'حذف الملاحظة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'هل أنت متأكد من حذف هذه الملاحظة؟\nلا يمكن التراجع عن هذا الإجراء.',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
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

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _getAuthorizedNote();

      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.note.id)
          .delete();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // يرجع true حتى يقوم NoteHomeScreen
      // بتحديث قائمة الملاحظات.
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ERROR DELETE NOTE: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _handleFirestoreError(e);
    }
  }

  // =========================================================
  // اختيار التصنيف
  // =========================================================

  void _showCategoryPicker() {
    if (_isLoadingCategories || _isLoading) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: creamyBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 18),

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

                          final bool isSelected =
                              category.trim().toLowerCase() ==
                              _selectedCategory.trim().toLowerCase();

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });

                                Navigator.pop(bottomSheetContext);
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
  // قائمة الثلاث نقاط
  // =========================================================

  Future<void> _showMoreMenu() async {
    if (_isLoading) return;

    try {
      final data = await _getAuthorizedNote();

      if (!mounted) return;

      final bool isPinned = data['isPinned'] == true;
      final bool isHidden = data['isHidden'] == true;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'إغلاق',
        barrierColor: Colors.black.withOpacity(0.25),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =========================
                        // رأس القائمة
                        // =========================
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  color: accentColor,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(width: 12),

                              const Text(
                                'خيارات الملاحظة',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // =========================
                        // تثبيت
                        // =========================
                        _buildMenuItem(
                          icon: isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          title: isPinned
                              ? 'إلغاء تثبيت الملاحظة'
                              : 'تثبيت الملاحظة',
                          onTap: () {
                            Navigator.pop(context);
                            _togglePinned();
                          },
                        ),

                        // =========================
                        // إخفاء
                        // =========================
                        _buildMenuItem(
                          icon: isHidden
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          title: isHidden ? 'إظهار الملاحظة' : 'إخفاء الملاحظة',
                          onTap: () {
                            Navigator.pop(context);
                            _toggleHidden();
                          },
                        ),

                        // =========================
                        // تغيير التصنيف
                        // =========================
                        _buildMenuItem(
                          icon: Icons.folder_outlined,
                          title: 'تغيير التصنيف',
                          onTap: () {
                            Navigator.pop(context);

                            Future.delayed(
                              const Duration(milliseconds: 150),
                              () {
                                if (mounted) {
                                  _showCategoryPicker();
                                }
                              },
                            );
                          },
                        ),

                        // =========================
                        // نسخ الملاحظة
                        // =========================
                        _buildMenuItem(
                          icon: Icons.copy_outlined,
                          title: 'نسخ الملاحظة',
                          onTap: () {
                            Navigator.pop(context);
                            _copyNote();
                          },
                        ),

                        // =========================
                        // حذف الملاحظة
                        // =========================
                        _buildMenuItem(
                          icon: Icons.delete_outline,
                          title: 'حذف الملاحظة',
                          iconColor: Colors.red,

                          onTap: () {
                            Navigator.pop(context);

                            Future.delayed(
                              const Duration(milliseconds: 150),
                              () {
                                if (mounted) {
                                  _deleteNote();
                                }
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },

        // =========================
        // حركة النافذة من الأعلى
        // =========================
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _handleFirestoreError(e);
    }
  }

  // =========================================================
  // عنصر في قائمة الخيارات
  // =========================================================

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.black54,
    Color textColor = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),

                Icon(
                  Icons.arrow_back_ios_new,
                  size: 15,
                  color: iconColor.withOpacity(0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // معالجة أخطاء Firestore
  // =========================================================

  void _handleFirestoreError(Object error) {
    if (!mounted) return;

    final String message = error.toString();

    if (message.contains('USER_NOT_LOGGED_IN')) {
      _showMessage('يجب تسجيل الدخول أولاً');
    } else if (message.contains('NOTE_NOT_FOUND')) {
      _showMessage('الملاحظة غير موجودة');
    } else if (message.contains('UNAUTHORIZED')) {
      _showMessage('لا يمكنك تنفيذ هذا الإجراء على هذه الملاحظة');
    } else if (message.contains('permission-denied')) {
      _showMessage('ليس لديك صلاحية لتنفيذ هذا الإجراء');
    } else {
      _showMessage('حدث خطأ، حاول مرة أخرى');
    }
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

        final String formattedMinute = minute.toString().padLeft(2, '0');

        return 'اليوم، $hour:$formattedMinute';
      }

      return 'اليوم';
    } catch (e) {
      debugPrint('DATE ERROR: $e');

      return 'اليوم';
    }
  }

  // =========================================================
  // عرض رسالة
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

        // =====================================================
        // AppBar
        // =====================================================
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,

          // ===================================================
          // زر الحفظ
          // ===================================================
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

          // ===================================================
          // العنوان والتصنيف
          // ===================================================
          title: Row(
            children: [
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

              Flexible(
                child: GestureDetector(
                  onTap: _showCategoryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _isLoadingCategories
                                ? 'جاري التحميل...'
                                : _selectedCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
              ),
            ],
          ),

          // ===================================================
          // أزرار AppBar
          // ===================================================
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

            // =================================================
            // الثلاث نقاط
            // =================================================
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black54),
              onPressed: _isLoading ? null : _showMoreMenu,
            ),
          ],
        ),

        // =====================================================
        // Body
        // =====================================================
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================
                    // التاريخ
                    // =========================================
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

                    // =========================================
                    // العنوان
                    // =========================================
                    TextField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
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

                    // =========================================
                    // المحتوى
                    // =========================================
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
