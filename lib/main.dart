import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tutorinsa/Services/notifi_service.dart';
import 'firebase_options.dart';
import 'pages/Common/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TutorInsa',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
