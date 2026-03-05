import 'package:cloud_firestore/cloud_firestore.dart';

class CloudService {
  Future<void> logEvent({
    required String type,
    required String message,
  }) async {
    await FirebaseFirestore.instance.collection('ble_logs').add(<String, dynamic>{
      'type': type,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
