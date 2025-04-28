import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopma/pages/login_page.dart';
import 'simpanan_page.dart';
import 'pinjaman_page.dart';
import 'profil_page.dart';
import 'admin_dashboard.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!doc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': 'mahasiswa',
        });
      }

      setState(() {
        _userRole = doc.data()?['role'] ?? 'mahasiswa';
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_userRole == 'admin') {
      return AdminDashboard();
    }

    return _buildUserDashboard();
  }

  Widget _buildUserDashboard() {
    final List<Widget> _pages = [
      HomeContent(userRole: _userRole),
      SimpananPage(),
      PinjamanPage(),
      ProfilPage(),
    ];

    return Scaffold(
      appBar:
          _selectedIndex == 0
              ? AppBar(
                title: Text('Dashboard Koperasi'),
                centerTitle: true,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: () => _logout(context),
                  ),
                ],
              )
              : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Simpanan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Pinjaman',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.green.shade50,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi'),
            content: Text('Yakin ingin logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }
}

class HomeContent extends StatelessWidget {
  final String? userRole;

  const HomeContent({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green[50]!, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selamat Datang di Koperasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              userRole == 'admin'
                  ? 'Anda login sebagai Admin'
                  : 'Anda login sebagai Mahasiswa',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Icon(Icons.account_balance, size: 60, color: Colors.green.shade600),
          ],
        ),
      ),
    );
  }
}
