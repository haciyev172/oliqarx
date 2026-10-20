import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AttendanceService {
  Future<void> recordAttendance({
    required String workerId,
    required String workerName,
    required String type,
    required File? selfieFile,
    required String qrPayload,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase qoşulmayıb. Bu QR qeydiyyatı serverə yazıla bilməz. Firebase konfiqurasiyası tələb olunur.',
      );
    }

    String selfieUrl = '';
    if (selfieFile != null) {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('attendance_selfies/$workerId/$timestamp.jpg');

    await ref.putFile(selfieFile);
    selfieUrl = await ref.getDownloadURL();
  } catch (e) {
    debugPrint('Selfie yüklənmədi: $e');
    selfieUrl = '';
  }
}

    final now = DateTime.now();
    await FirebaseFirestore.instance.collection('attendance_logs').add({
      'worker_id': workerId,
      'worker_name': workerName,
      'type': type,
      'qr_payload': qrPayload,
      'selfie_url': selfieUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'created_at': now.toIso8601String(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamWorkerRecentLogs(
    String workerId,
  ) {
    if (Firebase.apps.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('attendance_logs')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }
}
