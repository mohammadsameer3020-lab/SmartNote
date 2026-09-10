import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteOptionsSheet {
  static const Color blue = Color(0xFF00A8FF);

  // ============================================================
  // فتح القائمة
  // ============================================================

  static void show({
    required BuildContext context,
    required QueryDocumentSnapshot note,
    required VoidCallback onRefresh,
    required VoidCallback onMove,
    required VoidCallback onDelete,
  }) {
    final data = note.data() as Map<String, dynamic>;

    final bool isPinned = data['isPinned'] == true;
    final bool isHidden = data['isHidden'] == true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 10,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 55,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================================================
                  // عنوان الملاحظة
                  // ==================================================
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE7D2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.note_alt_outlined,
                          color: Colors.black54,
                          size: 21,
                        ),
                      ),

                      const SizedBox(width: 11),

                      Expanded(
                        child: Text(
                          data['title']?.toString().trim().isNotEmpty == true
                              ? data['title'].toString()
                              : 'بدون عنوان',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Divider(height: 1),

                  const SizedBox(height: 5),

                  // ==================================================
                  // تثبيت
                  // ==================================================
                  ListTile(
                    contentPadding: EdgeInsets.zero,

                    leading: _optionIcon(
                      icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: blue,
                      background: const Color(0xFFEAF6FF),
                    ),

                    title: Text(
                      isPinned ? 'إلغاء تثبيت الملاحظة' : 'تثبيت الملاحظة',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),

                    onTap: () async {
                      Navigator.pop(dialogContext);

                      try {
                        await FirebaseFirestore.instance
                            .collection('notes')
                            .doc(note.id)
                            .update({
                              'isPinned': !isPinned,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                        onRefresh();
                      } catch (e) {
                        debugPrint('ERROR PINNING NOTE: $e');
                      }
                    },
                  ),

                  // ==================================================
                  // إخفاء
                  // ==================================================
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),

                    onTap: () async {
                      Navigator.pop(dialogContext);

                      try {
                        await FirebaseFirestore.instance
                            .collection('notes')
                            .doc(note.id)
                            .update({
                              'isHidden': !isHidden,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                        onRefresh();
                      } catch (e) {
                        debugPrint('ERROR HIDING NOTE: $e');
                      }
                    },
                  ),

                  // ==================================================
                  // نقل
                  // ==================================================
                  ListTile(
                    contentPadding: EdgeInsets.zero,

                    leading: _optionIcon(
                      icon: Icons.drive_file_move_outlined,
                      color: Colors.orange,
                      background: const Color(0xFFFFF4E8),
                    ),

                    title: const Text(
                      'نقل إلى',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),

                    onTap: () {
                      Navigator.pop(dialogContext);
                      onMove();
                    },
                  ),

                  // ==================================================
                  // حذف
                  // ==================================================
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
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    onTap: () {
                      Navigator.pop(dialogContext);
                      onDelete();
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
  // أيقونة الخيار
  // ============================================================

  static Widget _optionIcon({
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
