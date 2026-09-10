import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final QueryDocumentSnapshot note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const Color blue = Color(0xFF00A8FF);

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final data = note.data() as Map<String, dynamic>;

    final String title = data['title']?.toString() ?? '';

    final String content = data['content']?.toString() ?? '';

    final String category = data['category']?.toString() ?? '';

    final bool isPinned = data['isPinned'] == true;

    String createdDate = '';

    if (data['createdAt'] is Timestamp) {
      final Timestamp timestamp = data['createdAt'] as Timestamp;

      final DateTime date = timestamp.toDate();

      createdDate =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFE7D2),
          borderRadius: BorderRadius.circular(16),
          border: isPinned ? Border.all(color: blue, width: 1.5) : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // رأس البطاقة
            // ==================================================
            Row(
              children: [
                if (isPinned) const Icon(Icons.push_pin, color: blue, size: 17),

                if (isPinned) const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    title.isEmpty ? 'بدون عنوان' : title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ==================================================
            // المحتوى
            // ==================================================
            Expanded(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ==================================================
            // التصنيف والتاريخ
            // ==================================================
            Row(
              children: [
                if (category.isNotEmpty)
                  Expanded(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                if (createdDate.isNotEmpty)
                  Text(
                    createdDate,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
