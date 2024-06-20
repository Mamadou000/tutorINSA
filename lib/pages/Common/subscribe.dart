// ignore_for_file: library_private_types_in_public_api

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:page_transition/page_transition.dart';
import 'package:confetti/confetti.dart';
import 'package:tutorinsa/pages/Common/home.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';


class SubscribePage1 extends StatefulWidget {
  const SubscribePage1({super.key});

  @override
  _SubscribePage1State createState() => _SubscribePage1State();
}

class _SubscribePage1State extends State<SubscribePage1> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 28, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Comment t\'appelles-tu ?',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                      border: OutlineInputBorder(),
                      fillColor: Color.fromARGB(57, 61, 37, 168),
                      filled: true,
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      fillColor: Color.fromARGB(57, 61, 37, 168),
                      filled: true,
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre prénom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(context).push(
                          PageTransition(
                            type: PageTransitionType.rightToLeftJoined,
                            childCurrent: const SubscribePage1(),
                            child: SubscribePage2(
                              nom: _nomController.text,
                              prenom: _prenomController.text,
                            ),
                            duration: const Duration(milliseconds: 400),
                          ),
                        );
                      }
                    },
                    child: const Text('Suivant'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class SubscribePage2 extends StatefulWidget {
  final String nom;
  final String prenom;

  const SubscribePage2({super.key, required this.nom, required this.prenom});

  @override
  _SubscribePage2State createState() => _SubscribePage2State();
}

class _SubscribePage2State extends State<SubscribePage2> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedAnnee;
  String? _selectedFiliere;

  final List<String> annees = ['1A', '2A', '3A', '4A', '5A'];
  final Map<String, List<String>> filieresByAnnee = {
    '1A': ['STPI'],
    '2A': ['STI', 'MRI', 'ERE', 'GSI', 'ENP'],
    '3A': ['STI', 'MRI', 'ERE', 'GSI', 'ENP'],
    '4A': ['STI', 'MRI', 'ERE', 'GSI', 'ENP'],
    '5A': ['STI', 'MRI', 'ERE', 'GSI', 'ENP'],
  };

  List<String> getFilieresForAnnee(String annee) {
    return filieresByAnnee[annee] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 28, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Quelle est ta formation ?',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      fillColor: Color.fromARGB(57, 61, 37, 168),
                      filled: true,
                    ),
                    dropdownColor: const Color.fromARGB(255, 20, 28, 68),
                    value: _selectedAnnee,
                    items: annees.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedAnnee = newValue;
                        _selectedFiliere = null; // Reset filiere when annee changes
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner votre année';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filière',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      fillColor: Color.fromARGB(57, 61, 37, 168),
                      filled: true,
                    ),
                    dropdownColor: const Color.fromARGB(255, 20, 28, 68),
                    value: _selectedFiliere,
                    items: _selectedAnnee != null
                        ? getFilieresForAnnee(_selectedAnnee!).map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList()
                        : [],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedFiliere = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner votre filière';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(context).push(
                          PageTransition(
                            type: PageTransitionType.rightToLeftJoined,
                            childCurrent: SubscribePage2(
                              nom: widget.nom,
                              prenom: widget.prenom,
                            ),
                            child: SubscribePage3(
                              nom: widget.nom,
                              prenom: widget.prenom,
                              annee: _selectedAnnee!,
                              filiere: _selectedFiliere!,
                            ),
                            duration: const Duration(milliseconds: 400),
                          ),
                        );
                      }
                    },
                    child: const Text('Suivant'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SubscribePage3 extends StatefulWidget {
  final String nom;
  final String prenom;
  final String annee;
  final String filiere;

  const SubscribePage3({
    super.key,
    required this.nom,
    required this.prenom,
    required this.annee,
    required this.filiere,
  });

  @override
  _SubscribePage3State createState() => _SubscribePage3State();
}

class _SubscribePage3State extends State<SubscribePage3> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  // Corrected RegExp pattern for email validation
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 28, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Entre tes identifiants INSA',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email INSA',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      fillColor: Color.fromARGB(57, 61, 37, 168),
                      filled: true,
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email INSA';
                      }
                      if (!_emailRegExp.hasMatch(value)) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: const OutlineInputBorder(),
                      fillColor: const Color.fromARGB(57, 61, 37, 168),
                      filled: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    obscureText: _obscureText,
                    style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      // Add additional validation logic for password strength if needed
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(context).push(
                          PageTransition(
                            type: PageTransitionType.rightToLeftJoined,
                            childCurrent: widget,
                            child: SubscribePage4(
                              nom: widget.nom,
                              prenom: widget.prenom,
                              annee: widget.annee,
                              filiere: widget.filiere,
                              email: _emailController.text,
                              password: _passwordController.text,
                            ),
                            duration: const Duration(milliseconds: 400),
                          ),
                        );
                      }
                    },
                    child: const Text('Suivant'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SubscribePage4 extends StatefulWidget {
  final String nom;
  final String prenom;
  final String annee;
  final String filiere;
  final String email;
  final String password;

  const SubscribePage4({
    super.key,
    required this.nom,
    required this.prenom,
    required this.annee,
    required this.filiere,
    required this.email,
    required this.password,
  });

  @override
  _SubscribePage4State createState() => _SubscribePage4State();
}

class _SubscribePage4State extends State<SubscribePage4> {
  File? _image;

  Future getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 28, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Souris pour une photo de profil !',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 50),
                _image == null
                    ? const Icon(Icons.account_circle, size: 100, color: Colors.white)
                    : SizedBox(
                        height: 200,
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon: Transform.scale(
                        scale: 1.3,
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.add_a_photo_rounded, color: Color.fromARGB(255, 59, 70, 150)),
                        ),
                      ),
                      onPressed: () {
                        getImage(ImageSource.camera);
                      },
                      color: Colors.white,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransition(
                            type: PageTransitionType.rightToLeftJoined,
                            childCurrent: SubscribePage4(
                              nom: widget.nom,
                              prenom: widget.prenom,
                              annee: widget.annee,
                              filiere: widget.filiere,
                              email: widget.email,
                              password: widget.password,
                            ),
                            child: SubscribePage7(
                              nom: widget.nom,
                              prenom: widget.prenom,
                              annee: widget.annee,
                              filiere: widget.filiere,
                              email: widget.email,
                              password: widget.password,
                              profileImage: _image,
                            ),
                            duration: const Duration(milliseconds: 400),
                          ),
                        );
                      },
                      child: const Text('Suivant'),
                    ),
                    IconButton(
                      icon: Transform.scale(
                        scale: 1.3,
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.image_rounded, color: Color.fromARGB(255, 59, 70, 150)),
                        ),
                      ),
                      onPressed: () {
                        getImage(ImageSource.gallery);
                      },
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class SubscribePage7 extends StatefulWidget {
  final String nom;
  final String prenom;
  final String annee;
  final String filiere;
  final String email;
  final String password;
  final File? profileImage;

  const SubscribePage7({
    super.key,
    required this.nom,
    required this.prenom,
    required this.annee,
    required this.filiere,
    required this.email,
    required this.password,
    required this.profileImage,
  });

  @override
  _SubscribePage7State createState() => _SubscribePage7State();
}

class _SubscribePage7State extends State<SubscribePage7> {
  List<String> matieres = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'Biologie',
    'Histoire',
    'Géographie',
    'Français',
    'Anglais',
    'Informatique',
    'Philosophie',
  ];

  List<bool> isSelected = List<bool>.generate(10, (index) => false);
  List<String> selectedMatieres = []; // List to store preferred subjects

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 28, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Quelles sont vos matières préférées ?',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: matieres.asMap().entries.map((entry) {
                          int index = entry.key;
                          String matiere = entry.value;
                          return ChoiceChip(
                            label: Text(
                              matiere,
                              style: const TextStyle(color: Colors.white),
                            ),
                            selected: isSelected[index],
                            onSelected: (bool selected) {
                              setState(() {
                                isSelected[index] = selected;
                                if (selected) {
                                  selectedMatieres.add(matiere); // Add subject to selected list
                                } else {
                                  selectedMatieres.remove(matiere); // Remove subject from selected list
                                }
                              });
                            },
                            backgroundColor: isSelected[index]
                                ? Colors.blue
                                : const Color.fromARGB(255, 59, 70, 150),
                            selectedColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() && selectedMatieres.isNotEmpty) {
                          Navigator.of(context).push(
                            PageTransition(
                              type: PageTransitionType.rightToLeftJoined,
                              childCurrent: widget,
                              child: SubscribePage5(
                                nom: widget.nom,
                                prenom: widget.prenom,
                                annee: widget.annee,
                                filiere: widget.filiere,
                                email: widget.email,
                                password: widget.password,
                                profileImage: widget.profileImage,
                                preferredMatieres: selectedMatieres, // Pass selected subjects to next page
                              ),
                              duration: const Duration(milliseconds: 400),
                            ),
                          );
                        } else {
                          if (selectedMatieres.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez choisir au moins une matière.'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Suivant'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class SubscribePage5 extends StatelessWidget {
  final String nom;
  final String prenom;
  final String annee;
  final String filiere;
  final String email;
  final String password;
  final File? profileImage;
  final List<String> preferredMatieres; // List of preferred subjects

  const SubscribePage5({
    super.key,
    required this.nom,
    required this.prenom,
    required this.annee,
    required this.filiere,
    required this.email,
    required this.password,
    this.profileImage,
    required this.preferredMatieres,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 28, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tu t\'inscris en tant que :',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 170),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageTransition(
                        type: PageTransitionType.rightToLeftJoined,
                        childCurrent: this,
                        child: SubscribePage6(
                          nom: nom,
                          prenom: prenom,
                          annee: annee,
                          filiere: filiere,
                          email: email,
                          password: password,
                          profileImage: profileImage,
                          isTuteur: true,
                          preferredMatieres: preferredMatieres, // Pass preferred subjects to next page
                        ),
                        duration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 60),
                  ),
                  child: const Text('Tuteur', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageTransition(
                        type: PageTransitionType.rightToLeftJoined,
                        childCurrent: this,
                        child: CongratulationsPage(
                          nom: nom,
                          prenom: prenom,
                          annee: annee,
                          filiere: filiere,
                          email: email,
                          password: password,
                          profileImage: profileImage,
                          isTuteur: false,
                          selectedMatieres: const [], // Pass an empty list for non-tutors
                          preferredMatieres: preferredMatieres, // Pass the preferred subjects
                        ),
                        duration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 60),
                  ),
                  child: const Text('Etudiant', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class CongratulationsPage extends StatefulWidget {
  final String nom;
  final String prenom;
  final String annee;
  final String filiere;
  final String email;
  final String password;
  final File? profileImage;
  final bool isTuteur;
  final List<String> selectedMatieres;
  final List<String> preferredMatieres;

  const CongratulationsPage({
    super.key,
    required this.nom,
    required this.prenom,
    required this.annee,
    required this.filiere,
    required this.email,
    required this.password,
    this.profileImage,
    required this.isTuteur,
    required this.selectedMatieres,
    required this.preferredMatieres,
  });

  @override
  _CongratulationsPageState createState() => _CongratulationsPageState();
}

class _CongratulationsPageState extends State<CongratulationsPage> {
  late ConfettiController _confettiController;
  CollectionReference usersRefs = FirebaseFirestore.instance.collection('Users');

  @override
  void initState() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    Timer(const Duration(seconds: 3), () {
      _confettiController.stop();
      _uploadUserData().then((_) {
        if (widget.isTuteur) {
          usersRefs.doc(widget.email).set({
            'Matieres': widget.selectedMatieres,
          }, SetOptions(merge: true));
        }
        usersRefs.doc(widget.email).set({
          'PreferredMatieres': widget.preferredMatieres,
        }, SetOptions(merge: true));
        _storeUserEmail(widget.email);
        _redirectUser();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  String hashPassword(String password) {
    var bytes = utf8.encode(password); // convert string to bytes
    var digest = sha256.convert(bytes); // hash the bytes
    return digest.toString(); // convert hash to string
  }


  Future<void> _uploadUserData() async {
    String? imageUrl;
    if (widget.profileImage != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${widget.email}.jpg');
      final uploadTask = storageRef.putFile(widget.profileImage!);
      final taskSnapshot = await uploadTask.whenComplete(() => {});
      imageUrl = await taskSnapshot.ref.getDownloadURL();
    }

    // Hash the password before saving
    String hashedPassword = hashPassword(widget.password);

    await usersRefs.doc(widget.email).set({
      'Nom': widget.nom,
      'Prénom': widget.prenom,
      'Annee': widget.annee,
      'Filiere': widget.filiere,
      'Email': widget.email,
      'Password': hashedPassword, // Save the hashed password
      'Image': imageUrl,
      'isTuteur': widget.isTuteur,
      'connected': true,
    });

    if (widget.isTuteur) {
      await usersRefs.doc(widget.email).update({
        'Matieres': widget.selectedMatieres,
      });
    }

    await usersRefs.doc(widget.email).update({
      'PreferredMatieres': widget.preferredMatieres,
    });
  }

  Future<void> _storeUserEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
  }

  void _redirectUser() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.1,
              numberOfParticles: 5,
              maxBlastForce: 10,
              minBlastForce: 1,
              gravity: 0.4,
            ),
            const Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Félicitations !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  Text(
                    'Bienvenue sur TutorInsa !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SubscribePage6 extends StatefulWidget {
  final String nom;
  final String prenom;
  final String annee;
  final String filiere;
  final String email;
  final String password;
  final File? profileImage;
  final bool isTuteur;
  final List<String> preferredMatieres; // Nouvelle variable pour les matières préférées

  const SubscribePage6({
    super.key,
    required this.nom,
    required this.prenom,
    required this.annee,
    required this.filiere,
    required this.email,
    required this.password,
    required this.profileImage,
    required this.isTuteur,
    required this.preferredMatieres, // Initialisation de la variable
  });

  @override
  _SubscribePage6State createState() => _SubscribePage6State();
}

class _SubscribePage6State extends State<SubscribePage6> {
  List<String> matieres = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'Biologie',
    'Histoire',
    'Géographie',
    'Français',
    'Anglais',
    'Informatique',
    'Philosophie',
  ];

  List<bool> isSelected = List<bool>.generate(10, (index) => false);
  List<String> selectedMatieres = []; // List to store selected subjects

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 28, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Dans quelles matières veux-tu aider ?',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: matieres.asMap().entries.map((entry) {
                          int index = entry.key;
                          String matiere = entry.value;
                          return ChoiceChip(
                            label: Text(
                              matiere,
                              style: const TextStyle(color: Colors.white),
                            ),
                            selected: isSelected[index],
                            onSelected: (bool selected) {
                              setState(() {
                                isSelected[index] = selected;
                                if (selected) {
                                  selectedMatieres.add(matiere); // Add subject to selected list
                                } else {
                                  selectedMatieres.remove(matiere); // Remove subject from selected list
                                }
                              });
                            },
                            backgroundColor: isSelected[index]
                                ? Colors.blue
                                : const Color.fromARGB(255, 59, 70, 150),
                            selectedColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() && selectedMatieres.isNotEmpty) {
                          Navigator.of(context).push(
                            PageTransition(
                              type: PageTransitionType.rightToLeftJoined,
                              childCurrent: widget,
                              child: CongratulationsPage(
                                nom: widget.nom,
                                prenom: widget.prenom,
                                annee: widget.annee,
                                filiere: widget.filiere,
                                email: widget.email,
                                password: widget.password,
                                profileImage: widget.profileImage,
                                isTuteur: widget.isTuteur,
                                selectedMatieres: selectedMatieres, // Pass selected subjects to CongratulationsPage
                                preferredMatieres: widget.preferredMatieres, // Pass preferred subjects to CongratulationsPage
                              ),
                              duration: const Duration(milliseconds: 400),
                            ),
                          );
                        } else {
                          if (selectedMatieres.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez choisir au moins une matière.'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Suivant'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


