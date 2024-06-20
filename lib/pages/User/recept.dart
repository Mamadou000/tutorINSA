import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorinsa/pages/Common/navigation_bar.dart';
import 'package:tutorinsa/pages/Common/chatpage.dart';

class ReceptPage extends StatefulWidget {
  const ReceptPage({super.key});

  @override
  _ReceptPageState createState() => _ReceptPageState();
}

class _ReceptPageState extends State<ReceptPage> {
  int _selectedIndex = 1;
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
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _startNewConversation(String email) async {
    // Get the current user's ID
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
  
    QuerySnapshot userQuerySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('Email', isEqualTo: email)
        .limit(1)
        .get();
  
    if (userQuerySnapshot.docs.isNotEmpty) {
      DocumentSnapshot userSnapshot = userQuerySnapshot.docs.first;
      String otherUserId = userSnapshot.id;
  
      // Check if a conversation already exists
      QuerySnapshot conversationSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _currentUserId)
          .get();
  
      bool conversationExists = false;
      String conversationId = '';
  
      for (var doc in conversationSnapshot.docs) {
        List participants = doc['participants'];
        if (participants.contains(otherUserId)) {
          conversationExists = true;
          conversationId = doc.id;
          break;
        }
      }
  
      if (!conversationExists) {
        // Create a new conversation
        DocumentReference conversationRef = await FirebaseFirestore.instance.collection('conversations').add({
          'participants': [_currentUserId, otherUserId], // Use userIds instead of emails
          'lastMessage': '',
          'timestamp': FieldValue.serverTimestamp(),
        });
        conversationId = conversationRef.id;
      }
  
      // Navigate to ChatPage
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 100),
          pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
            conversationId: conversationId,
            otherUserName: userSnapshot['Prénom'] ?? 'Utilisateur',
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur introuvable')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Réception',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: const Color(0xFF5F67EA),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('conversations')
                .where('participants', arrayContains: _currentUserId)
                .orderBy('timestamp', descending: true) // Ajoutez cette ligne
                .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final conversations = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final participants = List<String>.from(conversation['participants']);
                    final otherUserId = participants.firstWhere((id) => id != _currentUserId);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('Users').doc(otherUserId).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(title: Text('Chargement...'));
                        }

                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return const ListTile(title: Text('Utilisateur introuvable'));
                        }

                        final userData = userSnapshot.data!;
                        final otherUserName = userData['Prénom'] ?? 'Utilisateur';
                        final profileImageUrl = userData['Image'] ?? 'https://via.placeholder.com/150';
                        final isOnline = (userData.data() as Map<String, dynamic>?)?.containsKey('isOnline') ?? false;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('conversations')
                              .doc(conversation.id)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, messageSnapshot) {
                            if (!messageSnapshot.hasData) {
                              return const ListTile(title: Text('Chargement...'));
                            }

                            final lastMessageDoc = messageSnapshot.data!.docs.isNotEmpty
                                ? messageSnapshot.data!.docs.first
                                : null;
                            final lastMessage = lastMessageDoc != null
                                ? lastMessageDoc['text'] ?? 'Image'
                                : 'Aucun message';
                            final lastMessageTime = lastMessageDoc != null && lastMessageDoc['timestamp'] != null
                              ? DateFormat('HH:mm dd/MM').format((lastMessageDoc['timestamp'] as Timestamp).toDate())
                              : 'Inconnu';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 100),
                                    pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
                                      conversationId: conversation.id,
                                      otherUserName: otherUserName,
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
                              },
                              child: ChatItem(
                                name: otherUserName,
                                message: lastMessage,
                                time: lastMessageTime,
                                isOnline: isOnline,
                                profileImageUrl: profileImageUrl,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar2(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class ChatItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final bool isOnline;
  final String profileImageUrl;

  const ChatItem({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    this.isOnline = false,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(profileImageUrl),
            radius: 25,
          ),
          if (isOnline)
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
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message),
      trailing: Text(time),
    );
  }
}

