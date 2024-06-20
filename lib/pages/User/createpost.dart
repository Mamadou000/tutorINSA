import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String? _selectedSubject;
  CollectionReference postsRef = FirebaseFirestore.instance.collection('Posts');

  // Liste prédéfinie de matières
  final List<String> _subjects = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'Biologie',
    'Informatique',
    'Histoire',
    'Géographie',
    'Anglais',
    'Français',
    'Espagnol',
    // Ajoutez plus de matières si nécessaire
  ];

  // Fonction pour ajouter un tag
  void _addTag(String tag) {
    setState(() {
      _tags.add(tag);
    });
  }

  // Fonction pour supprimer un tag
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // Fonction pour publier le post
  Future<void> _publishPost() async {
    // Vérifie que les champs de titre et de contenu ne sont pas vides
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Veuillez remplir tous les champs.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    String imageUrl = '';

    // Si une image est sélectionnée, elle est téléchargée sur Firebase Storage
    if (_image != null) {
      try {
      Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('images')
        .child('${DateTime.now()}.jpg');
      UploadTask uploadTask = storageRef.putFile(File(_image!.path));

      TaskSnapshot taskSnapshot = await uploadTask;
      imageUrl = await taskSnapshot.ref.getDownloadURL();
      } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: const Text('Erreur lors du téléchargement de l\'image.'),
          actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
            Navigator.of(context).pop();
            },
          ),
          ],
        );
        },
      );
      return;
      }
    }

    // Enregistre le post dans Firestore
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      await postsRef.add({
        'Titre': _titleController.text,
        'Contenu': _contentController.text,
        'Tags': _tags,
        'Image': imageUrl,
        'Timestamp': FieldValue.serverTimestamp(),
        'PublishedBy': userId,
      });
    } catch (e) {
      print('Error creating post: $e');
    }

    // Ferme l'écran de création de post
    Navigator.pop(context);
  }

  // Fonction pour sélectionner une image depuis la galerie
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Titre',
                      hintStyle:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un post...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  if (_image != null)
                    Stack(
                      children: [
                        Image.file(
                          File(_image!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            color: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _image = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(Icons.label),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 171.0,
                        child: DropdownButton<String>(
                          value: _selectedSubject,
                          hint: const Text('Ajoutez une matière'),
                          items: _subjects.map((subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSubject = value;
                              if (value != null) {
                                _addTag(value);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 90.0),
                      IconButton(
                        icon: const Icon(Icons.image),
                        color: const Color(0xFF5F67EA),
                        iconSize: 40.0,
                        onPressed: _pickImage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: ElevatedButton(
                    onPressed: _publishPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F67EA),
                    ),
                    child: const Text(
                      'Publier',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
