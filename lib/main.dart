import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/registration_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/dashboard_page.dart';
import 'services/firestore_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _createDefaultAdmin();
    runApp(
      MultiProvider(
        providers: [Provider(create: (_) => FirestoreService())],
        child: const KoperasiApp(),
      ),
    );
  } catch (e) {
    runApp(const FirebaseErrorApp());
  }
}

Future<void> _createDefaultAdmin() async {
  try {
    const adminEmail = 'admin@kopma.com';
    const adminPassword = 'admin123';
    const adminName = 'Admin Koperasi';

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      await auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      await auth.signOut();
    } catch (e) {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      await userCredential.user?.updateDisplayName(adminName);

      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': adminEmail,
        'name': adminName,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    print('Gagal membuat admin default: $e');
  }
}

class KoperasiApp extends StatelessWidget {
  const KoperasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koperasi Mahasiswa',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/dashboard':
            (context) =>
                DashboardPage(), // Akan arahkan ke Admin/Mahasiswa dashboard
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Page not found')),
              ),
        );
      },
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Failed to initialize Firebase',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
