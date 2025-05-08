import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/registration_page.dart';
import 'pages/dashboard_page.dart';
import 'services/firestore_service.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Inisialisasi Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Membuat admin default jika belum ada
    await _createDefaultAdmin();

    // Menjalankan aplikasi
    runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => FirestoreService()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ChartRangeProvider()),
        ],
        child: const KoperasiApp(),
      ),
    );
  } catch (e) {
    // Jika Firebase gagal diinisialisasi
    print('Error initializing Firebase: $e');
    runApp(const FirebaseErrorApp());
  }
}

// Fungsi untuk membuat admin default
Future<void> _createDefaultAdmin() async {
  try {
    const adminEmail = 'admin@kopma.com';
    const adminPassword = 'admin123';
    const adminName = 'Admin Koperasi';

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      // Cek apakah admin sudah ada
      await auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      await auth.signOut();
    } catch (e) {
      // Jika admin belum ada, buat akun admin baru
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      // Perbarui nama admin
      await userCredential.user?.updateDisplayName(adminName);

      // Simpan data admin ke Firestore
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

// Widget utama aplikasi
class KoperasiApp extends StatelessWidget {
  const KoperasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Koperasi Mahasiswa',
      theme: ThemeData(
        brightness: Brightness.light,
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[900],
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/dashboard': (context) => DashboardPage(),
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

// Mengganti teks bahasa Inggris ke bahasa Indonesia
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
                'Gagal menginisialisasi Firebase',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
