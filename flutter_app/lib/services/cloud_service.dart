import 'package:cloud_firestore/cloud_firestore.dart';

class CloudService {
  final FirebaseFirestore _firestore;

  CloudService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logEvent({
    required String type,
    required String message,
  }) async {
    await _firestore.collection('ble_logs').add(<String, dynamic>{
      'type': type,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
