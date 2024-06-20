import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'messages.dart'; // Ensure the path is correct

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId'); // Use userId instead of email
      // Print userId to console
    });
  }

  void _showPickImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir une option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choisir une photo de l\'album'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String imageUrl = await _uploadImage(pickedFile.path);
      _sendMessage(imageUrl, true);
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      String imageUrl = await _uploadImage(pickedFile.path);
      _sendMessage(imageUrl, true);
    }
  }

  Future<String> _uploadImage(String path) async {
    File file = File(path);
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    UploadTask uploadTask = _storage.ref('chat_images/$fileName').putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  void _sendMessage(String content, bool isImage) {
    if (content.trim().isEmpty || _currentUserId == null) {
      return;
    }

    // Print userId when sending a message

    final messageData = {
      'text': isImage ? null : content,
      'imageUrl': isImage ? content : null,
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Print message data

    _firestore.collection('conversations').doc(widget.conversationId).collection('messages').add(messageData).then((value) {
    }).catchError((error) {
      print("Failed to send message: $error");
    });

    final conversationData = {
      'lastMessage': isImage ? 'Photo' : content,
      'timestamp': FieldValue.serverTimestamp(),
      'participants': FieldValue.arrayUnion([_currentUserId]) // Ensure correct userId is added
    };

    _firestore.collection('conversations').doc(widget.conversationId).update(conversationData).then((value) {
    }).catchError((error) {
      print("Failed to update conversation: $error");
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        backgroundColor: const Color(0xFF5F67EA),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message['senderId'] == _currentUserId;

                    return ChatBubble(
                      message: message['text'],
                      sender: isUser ? 'You' : widget.otherUserName,
                      isUser: isUser,
                      imageUrl: (message.data() as Map).containsKey('imageUrl') ? message['imageUrl'] : null,
                      messageId: message.id,
                      conversationId: widget.conversationId,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Saisissez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _showPickImageDialog,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: () => _sendMessage(_controller.text, false),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
