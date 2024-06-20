import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutorinsa/pages/Common/addmatierespage.dart';
import 'package:tutorinsa/pages/Common/home.dart';
import 'package:tutorinsa/pages/User/posts.dart'; // Import UserPage
import 'package:tutorinsa/pages/Tutor/TutorPosts.dart'; // Import TutorPostsPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late String userId;
  bool isLoading = true;
  String name = 'John';
  String lastName = 'Doe';
  String insaAddress = 'insa@example.com';
  String filiere = 'Computer Science';
  String annee = '3rd Year';
  String imageUrl = '';
  String password = '';
  bool isTutor = false; // Default to false
  List<String> matieres = []; // List to hold matieres for tutor
  List<String> preferredMatieres = []; // List to hold preferred matieres

  bool isEditingName = false;
  bool isEditingLastName = false;
  bool isEditingInsaAddress = false;
  bool isEditingFiliere = false;
  bool isEditingAnnee = false;
  bool isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId')!;

    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    var doc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    if (doc.exists) {
      setState(() {
        name = doc['Nom'] ?? 'Nom inconnu';
        lastName = doc['Prénom'] ?? 'Prénom inconnu';
        insaAddress = doc['Email'] ?? 'insa@example.com';
        filiere = doc['Filiere'] ?? 'Filière inconnue';
        annee = doc['Annee'] ?? 'Année inconnue';
        imageUrl = doc['Image'] ?? '';
        isLoading = false;
        password = doc['Password'] ?? '';
        isTutor = doc['isTuteur'] ?? false; // Fetch the isTuteur field
        if ((doc.data() as Map).containsKey('Matieres')) {
          matieres = List<String>.from(doc['Matieres']);
        } else {
          // If Matieres field doesn't exist, initialize it with an empty list
          FirebaseFirestore.instance.collection('Users').doc(userId).update({
            'Matieres': [],
          });
          matieres = [];
        }
        if ((doc.data() as Map).containsKey('PreferredMatieres')) {
          preferredMatieres = List<String>.from(doc['PreferredMatieres']);
        } else {
          // If PreferredMatieres field doesn't exist, initialize it with an empty list
          FirebaseFirestore.instance.collection('Users').doc(userId).update({
            'PreferredMatieres': [],
          });
          preferredMatieres = [];
        }
      });
    }
  }

  Future<void> _updateUserProfile() async {
    await FirebaseFirestore.instance.collection('Users').doc(userId).update({
      'Nom': name,
      'Prénom': lastName,
      'Email': insaAddress,
      'Filiere': filiere,
      'Annee': annee,
      'Image': imageUrl,
      'Password': password,
      'isTuteur': isTutor, // Update the isTuteur field
      'Matieres': matieres, // Update the Matieres field
      'PreferredMatieres': preferredMatieres, // Update the PreferredMatieres field
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    var storageRef = FirebaseStorage.instance.ref().child('user_images/$userId');
    var uploadTask = storageRef.putFile(_image!);
    var imageUrl = await (await uploadTask).ref.getDownloadURL();

    setState(() {
      this.imageUrl = imageUrl;
    });
    _updateUserProfile();
  }

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _uploadImage();
      }
    });
  }

  Future<void> _disconnectUser() async {
    // Mettre à jour le champ 'connected' à false dans Firestore
    await FirebaseFirestore.instance.collection('Users').doc(userId).update({
      'connected': false,
    });

    // Naviguer vers la page d'accueil après la déconnexion
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  void _toggleRole() {
    if (!isTutor && matieres.isEmpty) {
      // Redirect to AddMatierePage if no Matieres
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddMatierePage(userId: userId)),
      ).then((value) {
        _fetchUserProfile(); // Re-fetch the profile to get updated Matieres
        if (matieres.isNotEmpty) {
          setState(() {
            isTutor = true;
            _updateUserProfile();
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TutorPostsPage()),
          );
        }
      });
    } else {
      setState(() {
        isTutor = !isTutor;
        _updateUserProfile();
      });

      if (isTutor) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorPostsPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserPage()),
        );
      }
    }
  }

  void _addMatiere(String matiere) {
    setState(() {
      if (matiere.isNotEmpty) {
        matieres.add(matiere);
        _updateUserProfile();
      }
    });
  }

  void _addPreferredMatiere(String matiere) {
    setState(() {
      if (matiere.isNotEmpty) {
        preferredMatieres.add(matiere);
        _updateUserProfile();
      }
    });
  }

  void _removeMatiere(String matiere) {
    setState(() {
      matieres.remove(matiere);
      _updateUserProfile();
    });
  }

  void _removePreferredMatiere(String matiere) {
    setState(() {
      preferredMatieres.remove(matiere);
      _updateUserProfile();
    });
  }

  Widget _buildMatieresField() {
    if (!isTutor) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes matieres tutorées',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ...matieres.map((matiere) => ListTile(
          title: Text(matiere),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _removeMatiere(matiere);
            },
          ),
        )),
        TextButton(
          onPressed: () {
            _showAddMatiereDialog();
          },
          child: const Text('Ajouter Matiere', style: TextStyle(color: Colors.blue)),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildPreferredMatieresField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes matières préférées',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ...preferredMatieres.map((matiere) => ListTile(
          title: Text(matiere),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _removePreferredMatiere(matiere);
            },
          ),
        )),
        TextButton(
          onPressed: () {
            _showAddPreferredMatiereDialog();
          },
          child: const Text('Ajouter Matiere Préférée', style: TextStyle(color: Colors.blue)),
        ),
        const Divider(),
      ],
    );
  }

  void _showAddMatiereDialog() {
    List<String> matieres = ['Mathématiques', 'Physique', 'Chimie', 'Informatique']; // Liste des matières disponibles
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Quelles matières voulez-vous ajouter ?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0, // espace entre les bulles
              runSpacing: 8.0, // espace entre les lignes de bulles
              children: matieres.map((matiere) => GestureDetector(
                onTap: () {
                  _addMatiere(matiere);
                  Navigator.of(context).pop();
                },
                child: Chip(
                  label: Text(
                    matiere,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.lightBlueAccent.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  side: BorderSide(
                    color: Colors.lightBlueAccent.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddPreferredMatiereDialog() {
    List<String> matieres = ['Mathématiques', 'Physique', 'Chimie', 'Informatique']; // Liste des matières disponibles
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Quelles matières préférez-vous ?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0, // espace entre les bulles
              runSpacing: 8.0, // espace entre les lignes de bulles
              children: matieres.map((matiere) => GestureDetector(
                onTap: () {
                  _addPreferredMatiere(matiere);
                  Navigator.of(context).pop();
                },
                child: Chip(
                  label: Text(
                    matiere,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.lightGreenAccent.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  side: BorderSide(
                    color: Colors.lightGreenAccent.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF5F67EA),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: imageUrl.isEmpty
                            ? const AssetImage('assets/images/nopicture.png')
                            : NetworkImage(imageUrl) as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: getImage,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildEditableField('Nom', name, isEditingName, (value) {
                  setState(() {
                    name = value;
                  });
                }, () {
                  setState(() {
                    isEditingName = !isEditingName;
                  });
                  _updateUserProfile();
                }),
                const SizedBox(height: 16),
                _buildEditableField('Prénom', lastName, isEditingLastName, (value) {
                  setState(() {
                    lastName = value;
                  });
                }, () {
                  setState(() {
                    isEditingLastName = !isEditingLastName;
                  });
                  _updateUserProfile();
                }),
                const SizedBox(height: 16),
                _buildEditableField('Adresse INSA', insaAddress, isEditingInsaAddress, (value) {
                  setState(() {
                    insaAddress = value;
                  });
                }, () {
                  setState(() {
                    isEditingInsaAddress = !isEditingInsaAddress;
                  });
                  _updateUserProfile();
                }),
                const SizedBox(height: 16),
                _buildEditableField('Filière', filiere, isEditingFiliere, (value) {
                  setState(() {
                    filiere = value;
                  });
                }, () {
                  setState(() {
                    isEditingFiliere = !isEditingFiliere;
                  });
                  _updateUserProfile();
                }),
                const SizedBox(height: 16),
                _buildEditableField('Année', annee, isEditingAnnee, (value) {
                  setState(() {
                    annee = value;
                  });
                }, () {
                  setState(() {
                    isEditingAnnee = !isEditingAnnee;
                  });
                  _updateUserProfile();
                }),
                const SizedBox(height: 16),
                _buildEditableField('Mot de passe', '****', isEditingPassword, (value) {
                  setState(() {
                    password = value;
                  });
                }, () {
                  setState(() {
                    isEditingPassword = !isEditingPassword;
                  });
                }, isPassword: true),
                const SizedBox(height: 24),
                _buildMatieresField(),
                _buildPreferredMatieresField(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tuteur',
                      style: TextStyle(fontSize: 16),
                    ),
                    Switch(
                      value: isTutor,
                      onChanged: (value) {
                        _toggleRole();
                      },
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  title: const Text('Déconnexion'),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  onTap: _disconnectUser,
                ),
                ListTile(
                  title: const Text('Supprimer le compte'),
                  leading: const Icon(Icons.delete, color: Colors.red),
                  onTap: () {
                    // Supprimer le compte de l'utilisateur
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String value, bool isEditing, ValueChanged<String> onChanged, VoidCallback onEditPressed, {bool isPassword = false}) {
    return Row(
      children: [
        Expanded(
          child: isEditing
              ? TextFormField(
                  initialValue: value,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: isPassword,
                  onChanged: onChanged,
                )
              : ListTile(
                  subtitle: Text(label),
                  title: Text(value),
                ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: onEditPressed,
          child: Text(
            isEditing ? 'Sauvegarder' : 'Changer',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
