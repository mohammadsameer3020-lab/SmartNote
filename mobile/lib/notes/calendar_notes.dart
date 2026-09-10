import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/note_model.dart';
import 'package:mobile/notes/addNode.dart';
import 'package:mobile/notes/edit_note.dart';
import 'package:mobile/notes/addNode.dart';

class CalendarNotesPage extends StatefulWidget {
  const CalendarNotesPage({super.key});

  @override
  State<CalendarNotesPage> createState() => _CalendarNotesPageState();
}

class _CalendarNotesPageState extends State<CalendarNotesPage> {
  // ============================================================
  // الألوان
  // ============================================================

  static const Color primary = Color(0xFF00A8FF);
  static const Color background = Color(0xFFF4F4F4);

  static const Color textDark = Color(0xFF172B3D);
  static const Color textGrey = Color(0xFF777777);
  static const Color lightGrey = Color(0xFF9B9B9B);

  static const Color dividerColor = Color(0xFFEAEAEA);

  static const Color paperColor = Color(0xFFFFF3C7);
  static const Color pinnedPaperColor = Color(0xFFFFEFB2);

  // ============================================================
  // الأشهر
  // ============================================================

  final List<String> months = const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  // السبت أول يوم في الأسبوع
  final List<String> weekDays = const ['س', 'ج', 'خ', 'ر', 'ت', 'ث', 'أ'];

  // ============================================================
  // التاريخ
  // ============================================================

  late DateTime selectedDate;
  late DateTime displayedMonth;

  // ============================================================
  // البيانات
  // ============================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>> notes = [];

  Set<String> noteDates = {};

  bool isLoading = true;

  // ============================================================
  // Scroll
  // ============================================================

  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();

    selectedDate = DateTime(now.year, now.month, now.day);

    displayedMonth = DateTime(now.year, now.month);

    getNotesForSelectedDate();
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // عدد أيام الشهر
  // ============================================================

  int get daysInMonth {
    return DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
  }

  // ============================================================
  // مكان أول يوم
  //
  // السبت = 0
  // الأحد = 1
  // الاثنين = 2
  // الثلاثاء = 3
  // الأربعاء = 4
  // الخميس = 5
  // الجمعة = 6
  // ============================================================

  int get firstDayOffset {
    final int weekday = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    ).weekday;

    return (weekday + 1) % 7;
  }

  // ============================================================
  // مفتاح التاريخ
  // ============================================================

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // ============================================================
  // قراءة التاريخ
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // جلب الملاحظات
  // ============================================================

  Future<void> getNotesForSelectedDate() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          notes = [];
          noteDates = {};
          isLoading = false;
        });

        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('notes')
              .where('userId', isEqualTo: user.uid)
              .get();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> selectedNotes =
          [];

      final Set<String> datesWithNotes = {};

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        // --------------------------------------------------------
        // تجاهل الملاحظات المخفية
        // --------------------------------------------------------

        if (data['isHidden'] == true) {
          continue;
        }

        final DateTime? createdAt = _parseDate(data['createdAt']);

        if (createdAt == null) {
          continue;
        }

        // --------------------------------------------------------
        // تسجيل اليوم
        // --------------------------------------------------------

        datesWithNotes.add(_dateKey(createdAt));

        // --------------------------------------------------------
        // هل الملاحظة في اليوم المحدد؟
        // --------------------------------------------------------

        final bool sameDay =
            createdAt.year == selectedDate.year &&
            createdAt.month == selectedDate.month &&
            createdAt.day == selectedDate.day;

        if (sameDay) {
          selectedNotes.add(doc);
        }
      }

      // --------------------------------------------------------
      // المثبتة أولًا
      // ثم الأحدث
      // --------------------------------------------------------

      selectedNotes.sort((a, b) {
        final bool aPinned = a.data()['isPinned'] == true;

        final bool bPinned = b.data()['isPinned'] == true;

        if (aPinned && !bPinned) {
          return -1;
        }

        if (!aPinned && bPinned) {
          return 1;
        }

        final DateTime? aDate = _parseDate(a.data()['createdAt']);

        final DateTime? bDate = _parseDate(b.data()['createdAt']);

        if (aDate != null && bDate != null) {
          return bDate.compareTo(aDate);
        }

        return 0;
      });

      if (!mounted) return;

      setState(() {
        notes = selectedNotes;
        noteDates = datesWithNotes;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Calendar notes error: $e');

      if (!mounted) return;

      setState(() {
        notes = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'حدث خطأ أثناء تحميل الملاحظات',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  // ============================================================
  // الشهر السابق
  // ============================================================

  Future<void> previousMonth() async {
    final DateTime newMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month - 1,
    );

    final int maxDay = DateTime(newMonth.year, newMonth.month + 1, 0).day;

    final int safeDay = selectedDate.day > maxDay ? maxDay : selectedDate.day;

    setState(() {
      displayedMonth = newMonth;

      selectedDate = DateTime(newMonth.year, newMonth.month, safeDay);
    });

    await getNotesForSelectedDate();
  }

  // ============================================================
  // الشهر التالي
  // ============================================================

  Future<void> nextMonth() async {
    final DateTime newMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
    );

    final int maxDay = DateTime(newMonth.year, newMonth.month + 1, 0).day;

    final int safeDay = selectedDate.day > maxDay ? maxDay : selectedDate.day;

    setState(() {
      displayedMonth = newMonth;

      selectedDate = DateTime(newMonth.year, newMonth.month, safeDay);
    });

    await getNotesForSelectedDate();
  }

  // ============================================================
  // الانتقال لليوم
  // ============================================================

  Future<void> goToToday() async {
    final DateTime now = DateTime.now();

    setState(() {
      displayedMonth = DateTime(now.year, now.month);

      selectedDate = DateTime(now.year, now.month, now.day);
    });

    await getNotesForSelectedDate();
  }

  // ============================================================
  // اختيار يوم
  // ============================================================

  Future<void> selectDate(int day) async {
    setState(() {
      selectedDate = DateTime(displayedMonth.year, displayedMonth.month, day);
    });

    await getNotesForSelectedDate();
  }

  // ============================================================
  // هل اليوم محدد؟
  // ============================================================

  bool isSelectedDay(int day) {
    return selectedDate.year == displayedMonth.year &&
        selectedDate.month == displayedMonth.month &&
        selectedDate.day == day;
  }

  // ============================================================
  // هل اليوم الحالي؟
  // ============================================================

  bool isToday(int day) {
    final DateTime now = DateTime.now();

    return now.year == displayedMonth.year &&
        now.month == displayedMonth.month &&
        now.day == day;
  }

  // ============================================================
  // هل توجد ملاحظة؟
  // ============================================================

  bool hasNotes(int day) {
    final DateTime date = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      day,
    );

    return noteDates.contains(_dateKey(date));
  }

  // ============================================================
  // إضافة ملاحظة
  // ============================================================

  Future<void> addNote() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddNotePage()));

    await getNotesForSelectedDate();
  }

  // ============================================================
  // فتح تعديل الملاحظة
  // ============================================================

  Future<void> openEditNote(
    QueryDocumentSnapshot<Map<String, dynamic>> note,
  ) async {
    try {
      final NoteModel noteModel = NoteModel.fromFirestore(note);

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => EditNote(note: noteModel)));

      await getNotesForSelectedDate();
    } catch (e) {
      debugPrint('Edit note error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('تعذر فتح الملاحظة', textAlign: TextAlign.center),
        ),
      );
    }
  }

  // ============================================================
  // تنسيق الوقت
  // ============================================================

  String _formatTime(DateTime date) {
    int hour = date.hour;

    final int minute = date.minute;

    final String period = hour >= 12 ? 'م' : 'ص';

    hour %= 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }

  // ============================================================
  // اسم اليوم
  // ============================================================

  String _weekdayName(DateTime date) {
    const List<String> names = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    final int index = (date.weekday + 1) % 7;

    return names[index];
  }

  // ============================================================
  // عنوان اليوم
  // ============================================================

  String get selectedDayTitle {
    final bool today = DateUtils.isSameDay(selectedDate, DateTime.now());

    if (today) {
      return 'ملاحظات اليوم';
    }

    return 'ملاحظات ${_weekdayName(selectedDate)}';
  }

  VoidCallback? get openAddNote => null;

  // ============================================================
  // زر علوي
  // ============================================================

  Widget _topIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(icon, color: textDark, size: 28)),
        ),
      ),
    );
  }

  // ============================================================
  // الشريط العلوي
  // ============================================================

  Widget _buildTopBar() {
    return SizedBox(
      height: 74,
      child: Row(
        children: [
          // ------------------------------------------------------
          // المزيد
          // ------------------------------------------------------
          _topIconButton(icon: Icons.more_vert_rounded, onTap: _showMoreMenu),

          // ------------------------------------------------------
          // السابق
          // ------------------------------------------------------
          _topIconButton(
            icon: Icons.chevron_right_rounded,
            onTap: previousMonth,
          ),

          // ------------------------------------------------------
          // الشهر
          // ------------------------------------------------------
          Expanded(
            child: GestureDetector(
              onTap: goToToday,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Text(
                  '${months[displayedMonth.month - 1]} / ${displayedMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // التالي
          // ------------------------------------------------------
          _topIconButton(icon: Icons.chevron_left_rounded, onTap: nextMonth),

          // ------------------------------------------------------
          // رجوع
          // ------------------------------------------------------
          _topIconButton(
            icon: Icons.arrow_forward_rounded,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // أيام الأسبوع
  // ============================================================

  Widget _buildWeekDays() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  color: lightGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // يوم التقويم
  // ============================================================

  Widget _calendarDay(int day) {
    final bool selected = isSelectedDay(day);

    final bool today = isToday(day);

    final bool hasNote = hasNotes(day);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => selectDate(day),
      child: Center(
        child: SizedBox(
          width: 46,
          height: 49,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --------------------------------------------------
              // دائرة اليوم المحدد
              // --------------------------------------------------
              if (selected)
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),

              // --------------------------------------------------
              // رقم اليوم
              // --------------------------------------------------
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected || today
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: selected ? Colors.white : textDark,
                ),
              ),

              // --------------------------------------------------
              // نقطة الملاحظات
              // --------------------------------------------------
              if (hasNote)
                Positioned(
                  bottom: 1,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFB000) : primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // شبكة التقويم
  // ============================================================

  Widget _buildCalendarGrid() {
    final int totalCells = firstDayOffset + daysInMonth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCells,
        padding: const EdgeInsets.only(top: 7, bottom: 14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 0,
          mainAxisSpacing: 1,
          childAspectRatio: 1.18,
        ),
        itemBuilder: (context, index) {
          if (index < firstDayOffset) {
            return const SizedBox();
          }

          final int day = index - firstDayOffset + 1;

          return _calendarDay(day);
        },
      ),
    );
  }

  // ============================================================
  // عنوان الملاحظات
  // ============================================================

  Widget _buildNotesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'ملاحظات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),

          Text(
            DateUtils.isSameDay(selectedDate, DateTime.now())
                ? 'اليوم'
                : '${selectedDate.day} ${months[selectedDate.month - 1]}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: lightGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة الملاحظة
  // ============================================================

  Widget _buildNoteCard(QueryDocumentSnapshot<Map<String, dynamic>> note) {
    final Map<String, dynamic> data = note.data();

    final String title = (data['title'] ?? '').toString().trim();

    final String content = (data['content'] ?? '').toString().trim();

    final bool isPinned = data['isPinned'] == true;

    final DateTime? createdAt = _parseDate(data['createdAt']);

    final String displayTitle = title.isEmpty ? 'بدون عنوان' : title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openEditNote(note),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(14, 15, 14, 12),
          decoration: BoxDecoration(
            color: isPinned ? pinnedPaperColor : paperColor,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // العنوان
              // --------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ),

                  if (isPinned)
                    const Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: Color(0xFFC99400),
                    ),
                ],
              ),

              const SizedBox(height: 9),

              // --------------------------------------------------
              // المحتوى
              // --------------------------------------------------
              Expanded(
                child: Text(
                  content.isEmpty ? 'لا يوجد محتوى' : content,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.65,
                    color: Color(0xFF5E5949),
                  ),
                ),
              ),

              // --------------------------------------------------
              // التاريخ
              // --------------------------------------------------
              if (createdAt != null)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF9A906F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // شبكة الملاحظات
  // ============================================================

  Widget _buildNotesGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (context, index) {
          return _buildNoteCard(notes[index]);
        },
      ),
    );
  }

  // ============================================================
  // التحميل
  // ============================================================

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: SizedBox(
          width: 27,
          height: 27,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
        ),
      ),
    );
  }

  // ============================================================
  // لا توجد ملاحظات
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      child: Column(
        children: [
          const SizedBox(height: 5),

          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF5D5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              size: 29,
              color: Color(0xFFD0B158),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'لا توجد ملاحظات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'لا توجد ملاحظات محفوظة في هذا اليوم',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: textGrey),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }

  // ============================================================
  // القائمة
  // ============================================================

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E1E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.today_outlined, color: primary),
                  title: const Text(
                    'الانتقال إلى اليوم',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    goToToday();
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: primary),
                  title: const Text(
                    'تحديث الملاحظات',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    getNotesForSelectedDate();
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
  // زر +
  // ============================================================

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: openAddNote,

      foregroundColor: Colors.white,
      elevation: 5,
      icon: const Icon(Icons.add),
      label: const Text(
        'ملاحظة جديدة',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // AppBar ثابت في الأعلى
              // ==================================================
              Container(color: Colors.white, child: _buildTopBar()),

              // ==================================================
              // المحتوى القابل للتمرير
              // ==================================================
              Expanded(
                child: RefreshIndicator(
                  color: primary,
                  backgroundColor: Colors.white,
                  onRefresh: getNotesForSelectedDate,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(28),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ==================================
                              // أيام الأسبوع
                              // ==================================
                              _buildWeekDays(),

                              // ==================================
                              // التقويم
                              // ==================================
                              _buildCalendarGrid(),

                              // ==================================
                              // الفاصل
                              // ==================================
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                color: dividerColor,
                              ),

                              // ==================================
                              // عنوان الملاحظات
                              // ==================================
                              _buildNotesHeader(),

                              // ==================================
                              // الملاحظات
                              // ==================================
                              if (isLoading)
                                _buildLoading()
                              else if (notes.isEmpty)
                                _buildEmptyState()
                              else
                                _buildNotesGrid(),
                            ],
                          ),
                        ),
                      ),

                      // ==========================================
                      // مساحة أسفل الصفحة
                      // ==========================================
                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // زر الإضافة
        // ========================================================
        floatingActionButton: _buildFloatingButton(),

        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}
