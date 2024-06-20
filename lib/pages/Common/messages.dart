import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBubble extends StatelessWidget {
  final String? message;
  final String sender;
  final bool isUser;
  final String? imageUrl;
  final String messageId;
  final String conversationId;

  const ChatBubble({
    super.key,
    this.message,
    required this.sender,
    required this.isUser,
    this.imageUrl,
    required this.messageId,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showOptionsDialog(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                sender,
                style: const TextStyle(
                    fontSize: 13, fontFamily: 'Poppins', color: Colors.black87),
              ),
            ),
            Material(
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(50),
                topLeft: isUser ? const Radius.circular(50) : Radius.zero,
                bottomRight: const Radius.circular(50),
                topRight: isUser ? Radius.zero : const Radius.circular(50),
              ),
              color: isUser ? Colors.blue : Colors.white,
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl!,
                          width: 150, // Adjust the width as needed
                          height: 150, // Adjust the height as needed
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        message ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.blue,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                if (message != null) {
                  FlutterClipboard.copy(message!).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copié')),
                    );
                  });
                }
                Navigator.of(context).pop();
              },
            ),
            if (isUser) // Only show delete option if the message is from the current user
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Supprimer'),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(conversationId)
                      .collection('messages')
                      .doc(messageId)
                      .delete();
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }
}
