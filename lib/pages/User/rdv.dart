import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'createRdv.dart';
import 'package:tutorinsa/pages/Common/navigation_bar.dart';
import 'package:tutorinsa/pages/Common/chatpage.dart';

class RDVPage extends StatefulWidget {
  const RDVPage({super.key});

  @override
  _RDVPageState createState() => _RDVPageState();
}

class _RDVPageState extends State<RDVPage> {
  List<Map<String, dynamic>> _upcomingRDVs = [];
  List<Map<String, dynamic>> _pastRDVs = [];
  List<Map<String, dynamic>> _pendingRDVs = [];
  Map<String, Map<String, List<Map<String, dynamic>>>> _usersBySubjectsAndYear = {};
  int _selectedIndex = 2; // Set the default selected index to RDV

  @override
  void initState() {
    super.initState();
    _fetchAcceptedRendezVous();
    _fetchPendingRendezVous();
    _fetchConnectedUsers();
  }

  Future<void> _fetchAcceptedRendezVous() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      return;
    }

    CollectionReference rendezVousRef = FirebaseFirestore.instance.collection('Rendezvousacceptes');
    QuerySnapshot querySnapshot = await rendezVousRef.where('InitiatedBy', isEqualTo: userId).get();

    final now = DateTime.now();
    final upcomingRDVs = <Map<String, dynamic>>[];
    final pastRDVs = <Map<String, dynamic>>[];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      DateTime rdvDate = DateTime.parse(data['Date']);
      data['id'] = doc.id;

      if (rdvDate.isAfter(now)) {
        upcomingRDVs.add(data);
      } else {
        pastRDVs.add(data);
      }
    }

    setState(() {
      _upcomingRDVs = upcomingRDVs;
      _pastRDVs = pastRDVs;
    });
  }

  Future<void> _fetchPendingRendezVous() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      return;
    }

    CollectionReference rendezVousRef = FirebaseFirestore.instance.collection('Rendezvous');
    QuerySnapshot querySnapshot = await rendezVousRef.where('InitiatedBy', isEqualTo: userId).get();

    final pendingRDVs = <Map<String, dynamic>>[];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      pendingRDVs.add(data);
    }

    setState(() {
      _pendingRDVs = pendingRDVs;
    });
  }

  Future<void> _fetchConnectedUsers() async {
    CollectionReference usersRef = FirebaseFirestore.instance.collection('Users');
    QuerySnapshot querySnapshot = await usersRef
        .where('isTuteur', isEqualTo: true)
        .where('connected', isEqualTo: true)
        .get();

    final usersBySubjectsAndYear = <String, Map<String, List<Map<String, dynamic>>>>{};

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      List<String> subjects = List<String>.from(data['Matieres'] ?? []);
      String year = data['Annee'] ?? 'Inconnue';

      for (String subject in subjects) {
        if (!usersBySubjectsAndYear.containsKey(subject)) {
          usersBySubjectsAndYear[subject] = {};
        }
        if (!usersBySubjectsAndYear[subject]!.containsKey(year)) {
          usersBySubjectsAndYear[subject]![year] = [];
        }
        usersBySubjectsAndYear[subject]![year]!.add(data);
      }
    }

    setState(() {
      _usersBySubjectsAndYear = usersBySubjectsAndYear;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  Future<void> _deletePendingRendezVous(String rdvId) async {
    await FirebaseFirestore.instance.collection('Rendezvous').doc(rdvId).delete();
    _fetchPendingRendezVous(); // Refresh the list after deletion
  }

  Widget _buildRendezVousList(List<Map<String, dynamic>> rdvs, {bool isPending = false}) {
    if (rdvs.isEmpty) {
      return const Center(
        child: Text("Vous n'avez pas de rendez-vous en attente"),
      );
    }

    return ListView.builder(
      itemCount: rdvs.length,
      itemBuilder: (context, index) {
        final rdv = rdvs[index];
        final rdvDate = DateTime.parse(rdv['Date']);
        final formattedDate = _formatDate(rdvDate);
        final rdvTime = rdv['Time'];

        return ListTile(
          title: Text(rdv['Matiere'] ?? 'No Description'),
          subtitle: Text('Date: $formattedDate \nHeure: $rdvTime'),
          trailing: isPending
              ? TextButton(
                  onPressed: () => _deletePendingRendezVous(rdv['id']),
                  child: Text('Annuler', style: TextStyle(color: Colors.red)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildConnectedUsersList() {
    if (_usersBySubjectsAndYear.isEmpty) {
      return const Center(
        child: Text("Aucun utilisateur connecté"),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(10.0),
      children: _usersBySubjectsAndYear.entries.map((subjectEntry) {
        String subject = subjectEntry.key;
        Map<String, List<Map<String, dynamic>>> years = subjectEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...years.entries.expand((yearEntry) {
              List<Map<String, dynamic>> users = yearEntry.value;
              return users.map((user) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(user['Image'] ?? 'https://via.placeholder.com/150'),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text('${user['Nom']} ${user['Prénom']}'),
                  onTap: () {
                    _showUserProfileDialog(user);
                  },
                );
              }).toList();
            }),
          ],
        );
      }).toList(),
    );
  }

  void _showUserProfileDialog(Map<String, dynamic> user) {
    TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${user['Nom']} ${user['Prénom']}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user['Image'] ?? 'https://via.placeholder.com/150'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('• ${user['Email']}'),
                    Text('• ${user['Annee']}'),
                    Text('• ${user['Filiere']}'),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(hintText: 'Écrire un message'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                String message = messageController.text.trim();
                if (message.isNotEmpty) {
                  await _sendMessage(user, message);
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage(Map<String, dynamic> user, String message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _currentUserId = prefs.getString('userId');

    if (_currentUserId == null) {
      return;
    }

    String userId = user['id'];
    String conversationId = '';

    QuerySnapshot conversationSnapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: _currentUserId)
        .get();

    for (var doc in conversationSnapshot.docs) {
      List participants = doc['participants'];
      if (participants.contains(userId)) {
        conversationId = doc.id;
        break;
      }
    }

    if (conversationId.isEmpty) {
      DocumentReference conversationRef = await FirebaseFirestore.instance.collection('conversations').add({
        'participants': [_currentUserId, userId],
        'lastMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      conversationId = conversationRef.id;
    } else {
      await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
        'lastMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await FirebaseFirestore.instance.collection('conversations').doc(conversationId).collection('messages').add({
      'text': message,
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
          conversationId: conversationId,
          otherUserName: user['Prénom'],
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var tween = Tween(begin: begin, end: end);
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
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
        title: const Text('Mes Rendez-vous'),
        backgroundColor: const Color(0xFF5F67EA),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: <Widget>[
            Container(
              height: 70,
              color: const Color(0xFF5F67EA),
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  'Utilisateurs Connectés',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildConnectedUsersList(),
            ),
          ],
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'En attente'),
                Tab(text: 'À venir'),
                Tab(text: 'Passés'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRendezVousList(_pendingRDVs, isPending: true),
                  _buildRendezVousList(_upcomingRDVs),
                  _buildRendezVousList(_pastRDVs),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const createRdv()),
          ).then((value) {
            _fetchAcceptedRendezVous();
            _fetchPendingRendezVous();
          });
        },
        backgroundColor: const Color(0xFF5F67EA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar2(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
