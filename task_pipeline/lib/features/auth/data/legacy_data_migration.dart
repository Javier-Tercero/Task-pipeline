import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_pipeline/shared/data/user_root.dart';

/// One-time import of the projects that were saved before accounts existed,
/// when every install shared a single top-level `projects` collection.
///
/// Moves them under the signed-in user (users/{uid}/projects), then deletes the
/// originals. Delete this file, and the import button in ProfileScreen, once the
/// import has been run.
class LegacyDataMigration {
  const LegacyDataMigration();

  CollectionReference<Map<String, dynamic>> get _legacy =>
      FirebaseFirestore.instance.collection('projects');

  CollectionReference<Map<String, dynamic>> get _mine =>
      currentUserRoot().collection('projects');

  /// Whether the old shared collection still has anything in it. Once the
  /// security rules stop allowing that path the read is denied, which also
  /// means there is nothing left to import.
  Future<bool> hasLegacyData() async {
    try {
      final snapshot = await _legacy.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } on FirebaseException {
      return false;
    }
  }

  /// Copies every legacy project and its tasks under the current user, then
  /// deletes the originals. Returns how many projects were moved.
  ///
  /// The copy keeps the original document ids, so if the import is interrupted
  /// it can just be run again: it overwrites the same documents.
  Future<int> migrate() async {
    final projects = await _legacy.get();
    for (final project in projects.docs) {
      final tasks = await project.reference.collection('tasks').get();
      final target = _mine.doc(project.id);

      // 1. Copy. Only the fields the app knows about; anything else is dropped.
      final copy = _ChunkedBatch();
      final data = project.data();
      await copy.set(target, {
        'name': data['name'],
        'summary': data['summary'],
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      for (final task in tasks.docs) {
        final t = task.data();
        await copy.set(target.collection('tasks').doc(task.id), {
          'name': t['name'],
          'isCompleted': t['isCompleted'] ?? false,
          'createdAt': t['createdAt'] ?? FieldValue.serverTimestamp(),
        });
      }
      await copy.flush();

      // 2. Delete the originals, only once the copy is committed.
      final cleanup = _ChunkedBatch();
      for (final task in tasks.docs) {
        await cleanup.delete(task.reference);
      }
      await cleanup.delete(project.reference);
      await cleanup.flush();
    }
    return projects.docs.length;
  }
}

/// Collects writes into batches, committing whenever one nears Firestore's
/// 500-writes-per-batch limit.
class _ChunkedBatch {
  static const _limit = 400;

  WriteBatch _batch = FirebaseFirestore.instance.batch();
  int _count = 0;

  Future<void> set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    _batch.set(ref, data);
    await _countWrite();
  }

  Future<void> delete(DocumentReference<Map<String, dynamic>> ref) async {
    _batch.delete(ref);
    await _countWrite();
  }

  Future<void> flush() async {
    if (_count == 0) return;
    await _batch.commit();
    _batch = FirebaseFirestore.instance.batch();
    _count = 0;
  }

  Future<void> _countWrite() async {
    _count++;
    if (_count >= _limit) await flush();
  }
}
