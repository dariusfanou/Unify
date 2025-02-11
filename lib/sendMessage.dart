import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendMessage(String messageText, String senderId) async {
  try {
    await FirebaseFirestore.instance.collection('messages').add({
      'text': messageText,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print("Error sending message: $e");
  }
}
