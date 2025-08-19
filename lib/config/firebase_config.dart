import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDrXxXh2DYRYudUTay8V_dLrQFWqS2EQL4",
          authDomain: "schoolbustracker-22fdb.firebaseapp.com",
          databaseURL: "https://schoolbustracker-22fdb-default-rtdb.firebaseio.com",
          projectId: "schoolbustracker-22fdb",
          storageBucket: "schoolbustracker-22fdb.firebasestorage.app",
          messagingSenderId: "650328319030",
          appId: "1:650328319030:web:66e2692b178008808de497",
        ),
      );
    }

    // Configure Realtime Database
    FirebaseDatabase.instance.databaseURL = 'https://schoolbustracker-22fdb-default-rtdb.firebaseio.com';
  }

  static DatabaseReference get database => FirebaseDatabase.instance.ref();
}
