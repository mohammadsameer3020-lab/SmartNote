import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile/components/CustomButton.dart';
import 'package:mobile/components/CustomTextForm.dart';

class AddUserAndCategoryPage extends StatefulWidget {
  const AddUserAndCategoryPage({super.key});

  @override
  State<AddUserAndCategoryPage> createState() => _AddUserAndCategoryPageState();
}

class _AddUserAndCategoryPageState extends State<AddUserAndCategoryPage> {
  // الألوان الثابتة المتناسقة مع التطبيق
  static const Color orange = Color(0xFFFF7A00);
  static const Color background = Color(0xFFF8F8F8);
  static const Color textDark = Color(0xFF222222);

  // مفتاح للتحقق من صحة المدخلات في الـ Form
  final GlobalKey<FormState> formState = GlobalKey<FormState>();

  // المتحكم الخاص بحقل الإدخال
  final TextEditingController nameController = TextEditingController();

  // متغير للتحكم بحالة التحميل (Loading) أثناء الإضافة
  bool isLoading = false;

  // مرجع لمجموعة التصنيفات في Firestore (تم توحيد اسم المجموعة ليكون categories)
  final CollectionReference categoriesCollection = FirebaseFirestore.instance
      .collection('categories');

  // دالة لإضافة فئة (Category) جديدة
  Future<void> addCategories() async {
    if (!formState.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await categoriesCollection.add({
        'name': nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // مهم جداً للترتيب لاحقاً
      });

      if (!mounted) return;

      // العودة للصفحة السابقة أو الانتقال للـ home حسب رغبتك
      Navigator.of(context).pushReplacementNamed("NoteHomeScreen");
    } catch (e) {
      debugPrint('FULL FIREBASE ERROR: $e'); // ابحث عن هذا في الـ Debug Console

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إضافة التصنيف، حاول مرة أخرى',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'إضافة تصنيف جديد',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: textDark,
              size: 20,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formState,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اسم التصنيف',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // حقل إدخال اسم الفئة
                CustomTextForm(
                  hinttext: "أدخل اسم التصنيف",
                  mycontroller: nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "حقل الاسم لا يمكن أن يكون فارغاً";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // زر الإضافة مع إظهار مؤشر تحميل إذا كانت العملية جارية
                SizedBox(
                  width: double.infinity,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: orange),
                        )
                      : CustomButton(
                          title: "إضافة التصنيف",
                          onPressed: addCategories,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
