import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Pages/home.dart';
import 'Pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyA-RelrJNhZKMRn85jpNVXLALQ7h_VdIjA",
          appId: "1:807684363672:android:908123de4aeb40199187ed",
          messagingSenderId: "807684363672",
          projectId: "bidverse-f972c",
          storageBucket:"gs://bidverse-f972c.appspot.com", ));
       FirebaseFirestore.instance.settings = const Settings(
       persistenceEnabled: true, );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Waiting for Firebase initialization
            return const CircularProgressIndicator();
          } else if (snapshot.hasData) {
            // User is logged in
            return const Home();
          } else {
            // User is not logged in
            return const Login();
          }
        },
      ),
    );
  }
}