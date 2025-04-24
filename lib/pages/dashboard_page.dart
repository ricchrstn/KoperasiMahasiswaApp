import 'package:flutter/material.dart';
import 'simpanan_page.dart';
import 'pinjaman_page.dart';
import 'profil_page.dart';

class DashboardPage extends StatelessWidget {
  final List<Map<String, dynamic>> menu = [
    {'icon': Icons.savings, 'label': 'Simpanan', 'page': SimpananPage()},
    {
      'icon': Icons.account_balance,
      'label': 'Pinjaman',
      'page': PinjamanPage(),
    },
    {'icon': Icons.person, 'label': 'Profil', 'page': ProfilPage()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard Koperasi')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children:
            menu.map((item) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item['page']),
                  );
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(20)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 40),
                    SizedBox(height: 10),
                    Text(item['label'], style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
