import 'package:flutter/material.dart';

import 'package:tutorinsa/pages/Tutor/NavigationBar.dart';   // Assurez-vous que le chemin est correct

class TutorLivePage extends StatefulWidget {
  const TutorLivePage({super.key});

  @override
  _TutorLivePageState createState() => _TutorLivePageState();
}

class _TutorLivePageState extends State<TutorLivePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<String> _tags = [];
  String? _selectedSubject;

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

  void _addTag(String tag) {
    setState(() {
      _tags.add(tag);
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Lancer un Live'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFF5F67EA),
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
                      hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Écrire une description...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                    keyboardType: TextInputType.multiline,
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
                      const SizedBox(width: 90.0), // Ajoutez cette ligne
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Ajoutez votre logique pour lancer le live ici
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F67EA),
                    ),
                    child: const Text(
                      'Lancer le Live',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationBar2(
              selectedIndex: 1, // Sélectionnez l'index correspondant à cette page (Live)
              onItemTapped: (index) {
                // Ajoutez votre logique pour la navigation ici si nécessaire
              },
            ),
          ),
        ],
      ),
    );
  }
}
