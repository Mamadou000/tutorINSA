import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorinsa/pages/Tutor/NavigationBar.dart';

class TutorRDVPage extends StatefulWidget {
  const TutorRDVPage({super.key});

  @override
  _TutorRDVPageState createState() => _TutorRDVPageState();
}

class _TutorRDVPageState extends State<TutorRDVPage> {
  int _selectedIndex = 2;
  String? userId;
  List<String> tutorSpecialities = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndSpecialities();
  }

  void _loadUserIdAndSpecialities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');

    if (userId != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      setState(() {
        tutorSpecialities = List<String>.from(userDoc['Matieres']);
      });
    }
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
        title: const Text('Demandes de Rendez-vous'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFF5F67EA),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Rendezvous').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointmentRequests = snapshot.data!.docs.where((request) {
            final requestData = request.data() as Map<String, dynamic>;
            final matiere = requestData['Matiere'];
            return tutorSpecialities.contains(matiere);
          }).toList();

          return ListView.builder(
            itemCount: appointmentRequests.length,
            itemBuilder: (context, index) {
              final request = appointmentRequests[index];

              return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(request['InitiatedBy'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final user = userSnapshot.data;
                    final userName = user?['Prénom'] ?? 'Prénom inconnu';

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(userName),
                          titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Matière: ${request['Matiere']}'),
                              Text('Date: ${request['Date']}'),
                              Text('Heure: ${request['Time']}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 30),
                                onPressed: () {
                                  _acceptAppointment(request.id,
                                      request.data() as Map<String, dynamic>, user?['Prénom']);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.red, size: 30),
                                onPressed: () {
                                  _showRefuseConfirmationDialog(request.id,
                                      request.data() as Map<String, dynamic>);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'accepted_rdv', // Unique heroTag
            onPressed: () {
              _navigateToAcceptedAppointments(context);
            },
            icon: const Icon(Icons.event_available),
            label: const Text(
              'Voir les RDV acceptés',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF5F67EA),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'refused_rdv', // Unique heroTag
            onPressed: () {
              _navigateToRefusedAppointments(context);
            },
            icon: const Icon(Icons.cancel),
            label: const Text(
              'Voir les RDV refusés',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF5F67EA),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar2(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  void _showRefuseConfirmationDialog(
      String appointmentId, Map<String, dynamic> appointmentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Refuser le rendez-vous'),
          content:
              const Text('Êtes-vous sûr de vouloir refuser ce rendez-vous ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Je suis sûr'),
              onPressed: () {
                _refuseAppointment(appointmentId, appointmentData);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _acceptAppointment(
      String appointmentId, Map<String, dynamic> appointmentData, String? studentName) async {
    await FirebaseFirestore.instance.collection('Rendezvousacceptes').add({
      ...appointmentData,
      'AcceptedBy': userId, // Ajoutez l'ID du tuteur qui accepte le rendez-vous
    });

    await FirebaseFirestore.instance
        .collection('Rendezvous')
        .doc(appointmentId)
        .delete();
  }

  void _refuseAppointment(
      String appointmentId, Map<String, dynamic> appointmentData) {
    FirebaseFirestore.instance.collection('Rendezvousrefuses').add({
      ...appointmentData,
      'RefusedBy': userId // Ajoutez l'ID du tuteur qui refuse le rendez-vous
    });
    FirebaseFirestore.instance
        .collection('Rendezvous')
        .doc(appointmentId)
        .delete();
  }

  void _navigateToAcceptedAppointments(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (currentUserId != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AcceptedAppointmentsPage(userId: currentUserId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = Offset.zero;
            var end = Offset.zero;
            var curve = Curves.ease;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  void _navigateToRefusedAppointments(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (currentUserId != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RefusedAppointmentsPage(userId: currentUserId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = Offset.zero;
            var end = Offset.zero;
            var curve = Curves.ease;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }
}

class AcceptedAppointmentsPage extends StatelessWidget {
  final String userId;
  const AcceptedAppointmentsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous acceptés'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFF5F67EA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Rendezvousacceptes')
            .where('AcceptedBy', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final acceptedAppointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: acceptedAppointments.length,
            itemBuilder: (context, index) {
              final appointment = acceptedAppointments[index];
              return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(appointment['InitiatedBy'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final user = userSnapshot.data;
                    final userName = user?['Prénom'] ?? 'Prénom inconnu';

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(userName),
                          titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Matière: ${appointment['Matiere']}'),
                              Text('Date: ${appointment['Date']}'),
                              Text('Heure: ${appointment['Time']}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
            },
          );
        },
      ),
    );
  }
}

class RefusedAppointmentsPage extends StatelessWidget {
  final String userId;
  const RefusedAppointmentsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous refusés'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFF5F67EA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Rendezvousrefuses')
            .where('RefusedBy', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final refusedAppointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: refusedAppointments.length,
            itemBuilder: (context, index) {
              final appointment = refusedAppointments[index];
              return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(appointment['InitiatedBy'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final user = userSnapshot.data;
                    final userName = user?['Prénom'] ?? 'Prénom inconnu';

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(userName),
                          titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Matière: ${appointment['Matiere']}'),
                              Text('Date: ${appointment['Date']}'),
                              Text('Heure: ${appointment['Time']}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
            },
          );
        },
      ),
    );
  }
}
