import 'package:cloud_firestore/cloud_firestore.dart';

class CloudService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Stream<bool> faceVerificationStream(String uid) {
    return _firestore
        .collection('face_verifications')
        .doc(uid)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic>? data = doc.data();
      if (data == null) return false;
      return data['verified'] == true;
    });
  }

  Future<void> clearFaceVerification(String uid) async {
    await _firestore
        .collection('face_verifications')
        .doc(uid)
        .set(<String, dynamic>{
      'verified': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
