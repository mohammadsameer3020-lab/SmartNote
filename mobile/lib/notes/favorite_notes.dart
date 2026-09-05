import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/note_model.dart';
import 'edit_note.dart';

class FavoriteNotes extends StatefulWidget {
  const FavoriteNotes({super.key});

  @override
  State<FavoriteNotes> createState() => _FavoriteNotesState();
}

class _FavoriteNotesState extends State<FavoriteNotes> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // ============================================================
  // إزالة الملاحظة من المفضلة
  // ============================================================

  Future<void> removeFavorite(String noteId) async {
    try {
      await firestore.collection('notes').doc(noteId).update({
        'isFavorite': false,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('notes')
            .where('userId', isEqualTo: user.uid)
            .where('isFavorite', isEqualTo: true)
            .snapshots(),

        builder: (context, snapshot) {
          // ======================================================
          // Loading
          // ======================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ======================================================
          // Error
          // ======================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading favorite notes:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ======================================================
          // لا توجد ملاحظات مفضلة
          // ======================================================

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 90,
                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'No Favorite Notes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'You have not added any notes to favorites yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ======================================================
          // تحويل Firestore إلى NoteModel
          // ======================================================

          final List<NoteModel> notes = snapshot.data!.docs.map((doc) {
            return NoteModel.fromFirestore(doc);
          }).toList();

          // ======================================================
          // عرض الملاحظات
          // ======================================================

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final NoteModel note = notes[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditNote(note: note),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // =================================================
                        // العنوان + المفضلة
                        // =================================================
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                removeFavorite(note.id);
                              },
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                              tooltip: 'Remove from favorites',
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // =================================================
                        // المحتوى
                        // =================================================
                        Text(
                          note.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // =================================================
                        // التاريخ
                        // =================================================
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              note.createdAt != null
                                  ? _formatDate(note.createdAt!)
                                  : 'Recently',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // تنسيق التاريخ
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
