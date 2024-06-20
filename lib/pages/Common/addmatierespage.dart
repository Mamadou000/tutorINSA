import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorinsa/pages/Tutor/TutorPosts.dart';

class AddMatierePage extends StatefulWidget {
  final String userId;

  const AddMatierePage({super.key, required this.userId});

  @override
  _AddMatierePageState createState() => _AddMatierePageState();
}

class _AddMatierePageState extends State<AddMatierePage> {
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
                        if (selectedMatieres.isNotEmpty) {
                          _updateUserMatieres();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez choisir au moins une matière.'),
                            ),
                          );
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

  Future<void> _updateUserMatieres() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? widget.userId;

    await FirebaseFirestore.instance.collection('Users').doc(userId).update({
      'Matieres': selectedMatieres,
      'isTuteur': true,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TutorPostsPage()),
    );
  }
}
