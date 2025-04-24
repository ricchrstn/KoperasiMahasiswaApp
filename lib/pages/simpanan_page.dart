import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SimpananPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final String uid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Simpanan Saya')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('simpanan')
                .where('userId', isEqualTo: uid)
                .orderBy('tanggal', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return Center(child: Text('Belum ada data simpanan'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final simpanan = data[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Rp ${simpanan['jumlah']}'),
                subtitle: Text('Tanggal: ${simpanan['tanggal']}'),
              );
            },
          );
        },
      ),
    );
  }
}
