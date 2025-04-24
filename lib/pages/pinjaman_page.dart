import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinjamanPage extends StatefulWidget {
  @override
  _PinjamanPageState createState() => _PinjamanPageState();
}

class _PinjamanPageState extends State<PinjamanPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Pinjaman')),
        body: Center(child: Text('Silakan login untuk melihat pinjaman')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pinjaman Mahasiswa'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddPinjamanDialog(context, user.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('pinjaman')
                .where('userId', isEqualTo: user.uid)
                .orderBy('tanggal', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 50, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Belum ada data pinjaman'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddPinjamanDialog(context, user.uid),
                    child: Text('Ajukan Pinjaman'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final pinjaman = data[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.money, color: Colors.green),
                  ),
                  title: Text(
                    'Rp ${pinjaman['jumlah']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal: ${pinjaman['tanggal']}'),
                      Text('Status: ${pinjaman['status'] ?? 'Menunggu'}'),
                      if (pinjaman['keterangan'] != null)
                        Text('Keterangan: ${pinjaman['keterangan']}'),
                    ],
                  ),
                  trailing:
                      pinjaman['status'] == 'Disetujui'
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : pinjaman['status'] == 'Ditolak'
                          ? Icon(Icons.cancel, color: Colors.red)
                          : Icon(Icons.access_time, color: Colors.orange),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPinjamanDialog(context, user.uid),
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddPinjamanDialog(BuildContext context, String userId) {
    final formKey = GlobalKey<FormState>();
    final jumlahController = TextEditingController();
    final tujuanController = TextEditingController();
    final tanggalController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajukan Pinjaman'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: jumlahController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Pinjaman',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Jumlah harus diisi';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: tujuanController,
                    decoration: InputDecoration(labelText: 'Tujuan Pinjaman'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tujuan harus diisi';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: tanggalController,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Pengajuan',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        tanggalController.text = date.toString().split(' ')[0];
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('pinjaman')
                        .add({
                          'userId': userId,
                          'jumlah': int.parse(jumlahController.text),
                          'tujuan': tujuanController.text,
                          'tanggal': tanggalController.text,
                          'status': 'Menunggu',
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pinjaman berhasil diajukan')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengajukan pinjaman: $e')),
                    );
                  }
                }
              },
              child: Text('Ajukan'),
            ),
          ],
        );
      },
    );
  }
}
