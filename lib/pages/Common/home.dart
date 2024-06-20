import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorinsa/pages/Tutor/TutorPosts.dart';
import 'package:tutorinsa/pages/User/posts.dart';
import 'package:tutorinsa/pages/Common/subscribe.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    // Hash the input password
    String hashedPassword = hashPassword(password);

    // Vérifiez les informations dans Firestore
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    QuerySnapshot querySnapshot = await users
        .where('Email', isEqualTo: email)
        .where('Password', isEqualTo: hashedPassword)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Mettre à jour la variable 'connected' à true
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      await userDoc.reference.update({'connected': true});
  
      String userId = querySnapshot.docs[0].id;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

      // Vérifier si l'utilisateur est un tuteur
      bool isTuteur = userDoc['isTuteur'] ?? false;

      // Naviguer vers UserPage
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => isTuteur ? const TutorPostsPage() : const UserPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(0, 1);
            var end = Offset.zero;
            var curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else {
      // Utilisateur non trouvé, afficher un message d'erreur
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Erreur de connexion'),
            content: const Text('Email ou mot de passe incorrect.'),
            actions: <Widget>[
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
    }
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert string to bytes
    var digest = sha256.convert(bytes); // Hash the bytes
    return digest.toString(); // Convert hash to string
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ListView(
              children: [
                _buildTitle(),
                const SizedBox(height: 30),
                const SizedBox(height: 120),
                const SizedBox(height: 280),
                _buildLoginForm(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.only(top: 50.0),
      child: Text(
        'Connexion',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'E-mail INSA',
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
        controller: _passwordController,
        obscureText: _obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Mot de passe',
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _togglePasswordVisibility,
            ),
           ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('Se connecter'),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const SubscribePage1(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          var begin = const Offset(0, 1);
                          var end = Offset.zero;
                          var curve = Curves.ease;

                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('S\'inscrire'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
