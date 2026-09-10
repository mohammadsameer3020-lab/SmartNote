import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeleteNoteDialog {
  static void show({
    required BuildContext context,
    required QueryDocumentSnapshot note,
    required VoidCallback onDeleted,
  }) {
    final data = note.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                Navigator.pop(dialogContext);
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
                Navigator.pop(dialogContext);

                try {
                  await FirebaseFirestore.instance
                      .collection('notes')
                      .doc(note.id)
                      .delete();

                  onDeleted();

                  if (!context.mounted) {
                    return;
                  }

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
}
