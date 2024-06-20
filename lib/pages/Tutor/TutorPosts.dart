import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:tutorinsa/pages/User/createpost.dart';
import 'package:tutorinsa/pages/Common/profilepage.dart';
import 'package:tutorinsa/pages/Tutor/NavigationBar.dart';

class TutorPostsPage extends StatefulWidget {
  const TutorPostsPage({super.key});

  @override
  _TutorPageState createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPostsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  int _selectedIndex = 0;
  final List<String> _selectedTags = [];
  String? _userName;
  String? _userImage;
  List<String> _userPreferences = [];

  final List<String> _tags = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'Biologie',
    'Informatique',
    'Histoire',
    'Géographie',
    'Anglais',
    'Français',
    'Espagnol'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      if (userSnapshot.exists) {
        setState(() {
          _userName = userSnapshot['Prénom'];
          _userImage = userSnapshot['Image'];
          _userPreferences = List<String>.from(
              (userSnapshot.data() as Map).containsKey('PreferredMatieres')
                  ? userSnapshot['PreferredMatieres']
                  : []);
        });
      }
    }
  }


  void _updateSearchTerm(String value) {
    setState(() {
      _searchTerm = value.toLowerCase();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
              backgroundColor: const ui.Color(0xFF5F67EA),
              automaticallyImplyLeading: false,
              title: Text(
                'Welcome, ${_userName ?? 'User'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: _userImage != null
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(_userImage!),
                  )
                      : const Icon(Icons.account_circle, size: 30),
                  tooltip: 'Profil de l\'utilisateur',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Rechercher un post...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.2),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  _updateSearchTerm(_searchController.text);
                                },
                              ),
                            ),
                            onSubmitted: _updateSearchTerm,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showTagFilterDialog,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 0, top: 20.0),
                    child: Text(
                      'Les posts récents 🔥',
                      style: TextStyle(
                        color: ui.Color.fromARGB(255, 0, 0, 0),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPostsList(),
                ],
              ),
            ),
            bottomNavigationBar: NavigationBar2(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
           /* floatingActionButton: OpenContainer(
              closedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(28.0),
                ),
              ),
              closedColor: const Color(0xFF5F67EA),
              closedElevation: 6.0,
              transitionDuration: const Duration(milliseconds: 500),
              closedBuilder:
                  (BuildContext context, VoidCallback openContainer) {
                return FloatingActionButton(
                  onPressed: openContainer,
                  backgroundColor: const Color(0xFF5F67EA),
                  child: const Icon(Icons.add, color: Colors.white),
                );
              },
              openBuilder: (BuildContext context, VoidCallback _) {
                return const CreatePost();
              },
            ),*/
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        }

  void _showTagFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sélectionner les tags'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: _tags.map((tag) {
                    return CheckboxListTile(
                      title: Text(tag),
                      value: _selectedTags.contains(tag),
                      onChanged: (isSelected) {
                        setState(() {
                          if (isSelected!) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var documents = snapshot.data!.docs;

        // Filtre par titre et/ou tags
        if (_searchTerm.isNotEmpty || _selectedTags.isNotEmpty) {
          final searchTermLower = _searchTerm.toLowerCase();
          documents = documents.where((doc) {
            final title = doc['Titre']?.toString().toLowerCase() ?? '';
            final tags = List<String>.from(doc['Tags'] ?? []);

            // Vérifier si le titre contient le terme de recherche
            bool titleMatches = title.contains(searchTermLower);

            // Vérifier si l'un des tags est sélectionné
            bool tagsMatch = false;
            if (_selectedTags.isNotEmpty) {
              for (var selectedTag in _selectedTags) {
                if (tags.contains(selectedTag)) {
                  tagsMatch = true;
                  break;
                }
              }
            } else {
              tagsMatch = true; // Si aucun tag n'est sélectionné, ignorer cette vérification
            }

            return titleMatches && tagsMatch;
          }).toList();
        }

        var preferredDocs = documents.where((doc) {
          final tags = List<String>.from(doc['Tags'] ?? []);
          return _userPreferences.any((pref) => tags.contains(pref));
        }).toList();

        var otherDocs = documents.where((doc) {
          final tags = List<String>.from(doc['Tags'] ?? []);
          return !_userPreferences.any((pref) => tags.contains(pref));
        }).toList();

        preferredDocs.sort((a, b) => b['Timestamp'].toDate().compareTo(a['Timestamp'].toDate()));
        // Combiner les deux listes, en affichant d'abord les posts préférés
        documents = [...preferredDocs, ...otherDocs];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final title = doc['Titre'] ?? 'Titre indisponible';
            final content = doc['Contenu'] ?? 'Contenu indisponible';
            final postImagePath = doc['Image'] ?? '';
            final tags = List<String>.from(doc['Tags'] ?? []);
            final publishedBy = doc['PublishedBy'] ?? ''; // Nom du champ qui contient l'ID de l'utilisateur

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('Users').doc(publishedBy).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox.shrink(); // Gérer le cas où l'utilisateur n'existe pas
                }

                final userData = userSnapshot.data!;
                final userImage = userData['Image'] ?? '';

                return _buildPost(
                  title.toString(),
                  content.toString(),
                  postImagePath.toString(),
                  userImage.toString(),
                  tags,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPost(String title, String content, String postImagePath, String userImage, List<String> tags) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: ui.Color.fromARGB(255, 87, 87, 87),
            blurRadius: 5.0,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: ui.Color.fromARGB(255, 87, 87, 87),
            offset: Offset(0, 0),
          ),
          BoxShadow(
            color: ui.Color.fromARGB(255, 255, 255, 255),
            offset: Offset(5, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                if (postImagePath.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 0),
                      child: Image.network(
                        postImagePath,
                        width: 500, // Ajustez la largeur de l'image selon vos besoins
                        height: 200, // Ajustez la hauteur de l'image selon vos besoins
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
              radius: 20,
              child: userImage.isEmpty ? const Icon(Icons.person) : null,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) {
                return Text(
                  '#$tag', // Ajoutez un symbole hashtag devant chaque tag
                  style: const TextStyle(
                    fontSize: 10, // Réduisez la taille du texte selon vos besoins
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}