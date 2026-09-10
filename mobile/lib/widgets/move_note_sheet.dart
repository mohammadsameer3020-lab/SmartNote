import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MoveNoteSheet {
  static const Color blue = Color(0xFF00A8FF);

  static void show({
    required BuildContext context,
    required QueryDocumentSnapshot note,
    required List<String> categories,
    required VoidCallback onRefresh,
  }) {
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
      builder: (sheetContext) {
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

                      leading: Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_outlined,
                          color: blue,
                          size: 21,
                        ),
                      ),

                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      onTap: () async {
                        Navigator.pop(sheetContext);

                        try {
                          await FirebaseFirestore.instance
                              .collection('notes')
                              .doc(note.id)
                              .update({'category': category});

                          onRefresh();

                          if (!context.mounted) {
                            return;
                          }

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
}
