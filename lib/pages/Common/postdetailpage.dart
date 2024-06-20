import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String title;
  final String content;
  final String postImagePath;
  final String userImage;
  final List<String> tags;
  final String name;
  final String annee;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.title,
    required this.content,
    required this.postImagePath,
    required this.userImage,
    required this.tags,
    required this.name,
    required this.annee,
  });

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      if (userSnapshot.exists) {
        setState(() {

        });
      }
    }
  }

  Future<void> _addComment(String comment, [String? imageUrl]) async {
    if (comment.isNotEmpty || imageUrl != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      String userImage = userSnapshot['Image'];
      String userName = userSnapshot['Prénom'];
      String userAnnee = userSnapshot['Annee'];

      await FirebaseFirestore.instance.collection('Posts').doc(widget.postId).collection('Comments').add({
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'userImage': userImage,
        'imageUrl': imageUrl,
        'userName': userName,
        'year': userAnnee,
      });

      _commentController.clear();
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String? imageUrl = await _uploadImage(image);
      if (imageUrl != null) {
        _addComment('', imageUrl);
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('comments/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      await imageRef.putFile(File(image.path));
      return await imageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF5F67EA),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: widget.userImage.isNotEmpty ? NetworkImage(widget.userImage) : null,
                          radius: 20,
                          child: widget.userImage.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.annee,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.postImagePath.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(top: 20, right: 0),
                          child: Image.network(
                            widget.postImagePath,
                            width: 500,
                            height: 300,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.content,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.start,
                      children: widget.tags.map((tag) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Text(
                'Commentaires',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Posts').doc(widget.postId).collection('Comments').orderBy('timestamp', descending: false).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  List<Map<String, dynamic>> comments = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      var comment = comments[index];
                      var timestamp = comment['timestamp'] != null ? (comment['timestamp'] as Timestamp).toDate() : null;

                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: comment['userImage'] != null
                                    ? NetworkImage(comment['userImage'])
                                    : null,
                                child: comment['userImage'] == null ? const Icon(Icons.person) : null,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${comment['userName']}, ${comment['year']}', // Ajout du nom et de l'année
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(comment['comment']),
                                  if (comment['imageUrl'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Image.network(comment['imageUrl']),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (timestamp != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Text(
                                DateFormat('dd-MM-yy HH:mm').format(timestamp),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      _addComment(_commentController.text);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
