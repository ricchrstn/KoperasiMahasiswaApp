import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class SimpananPage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  SimpananPage({this.onBackToHome, Key? key}) : super(key: key);
  @override
  _SimpananPageState createState() => _SimpananPageState();
}

class _SimpananPageState extends State<SimpananPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? _userRole;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getUserRole();
    initializeDateFormatting('id_ID', null);
  }

  Future<void> _getUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = doc.data()?['role'] ?? 'mahasiswa';
      });
    }
  }

  void _showSnackbar(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async {
        // Tambahkan logika jika diperlukan, misalnya menampilkan dialog konfirmasi
        return true; // Mengizinkan navigasi kembali
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _userRole == 'admin' ? 'Kelola Simpanan' : 'Simpanan Saya',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.green.shade800),
          leading:
              widget.onBackToHome != null
                  ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: widget.onBackToHome,
                  )
                  : null,
        ),
        floatingActionButton:
            user != null
                ? FloatingActionButton(
                  onPressed: () => _showAddSimpananDialog(context, user.uid),
                  child: Icon(Icons.add),
                  backgroundColor: Colors.blue,
                )
                : null,
        body:
            user == null
                ? Center(child: Text('Tidak ada data pengguna yang tersedia.'))
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan jumlah...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            _userRole == 'admin'
                                ? _firestore
                                    .collection('simpanan')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots()
                                : _firestore
                                    .collection('simpanan')
                                    .where('userId', isEqualTo: user.uid)
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error: ${snapshot.error}',
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => setState(() {}),
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Memuat data...'),
                                ],
                              ),
                            );
                          }

                          var documents = snapshot.data!.docs;

                          if (_searchQuery.isNotEmpty) {
                            documents =
                                documents.where((doc) {
                                  final jumlah =
                                      (doc['jumlah'] ?? '').toString();
                                  return jumlah.contains(_searchQuery);
                                }).toList();
                          }

                          if (documents.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.savings,
                                    size: 50,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(height: 16),
                                  Text('Belum ada data simpanan'),
                                ],
                              ),
                            );
                          }

                          double totalWajib = documents
                              .where((doc) => doc['jenis'] == 'wajib')
                              .fold(
                                0,
                                (sum, doc) => sum + (doc['jumlah'] ?? 0),
                              );

                          double totalSukarela = documents
                              .where((doc) => doc['jenis'] == 'sukarela')
                              .fold(
                                0,
                                (sum, doc) => sum + (doc['jumlah'] ?? 0),
                              );

                          return Column(
                            children: [
                              Card(
                                margin: EdgeInsets.all(16),
                                elevation: 4,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Total Simpanan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _currencyFormat.format(
                                          totalWajib + totalSukarela,
                                        ),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                'Wajib',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _currencyFormat.format(
                                                  totalWajib,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                'Sukarela',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _currencyFormat.format(
                                                  totalSukarela,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: documents.length,
                                  itemBuilder: (context, index) {
                                    final simpanan =
                                        documents[index].data()
                                            as Map<String, dynamic>;
                                    return Card(
                                      margin: EdgeInsets.all(8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              simpanan['jenis'] == 'wajib'
                                                  ? Colors.blue[100]
                                                  : Colors.green[100],
                                          child: Icon(
                                            Icons.savings,
                                            color:
                                                simpanan['jenis'] == 'wajib'
                                                    ? Colors.blue
                                                    : Colors.green,
                                          ),
                                        ),
                                        title: Text(
                                          _currencyFormat.format(
                                            simpanan['jumlah'],
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tanggal: ${simpanan['tanggal'] ?? '-'}',
                                            ),
                                            Text('Jenis: ${simpanan['jenis']}'),
                                            if (simpanan['keterangan'] != null)
                                              Text(
                                                'Keterangan: ${simpanan['keterangan']}',
                                              ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _deleteSimpanan(
                                                documents[index].id,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _deleteSimpanan(String id) async {
    try {
      await _firestore.collection('simpanan').doc(id).delete();
      _showSnackbar('Simpanan berhasil dihapus');
    } catch (e) {
      _showSnackbar('Gagal menghapus simpanan: $e', color: Colors.red);
    }
  }

  void _showAddSimpananDialog(BuildContext context, String userId) {
    final formKey = GlobalKey<FormState>();
    final jumlahController = TextEditingController();
    final keteranganController = TextEditingController();
    final tanggalController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String jenisSimpanan = 'sukarela';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah Simpanan'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text('Wajib'),
                              leading: Radio(
                                value: 'wajib',
                                groupValue: jenisSimpanan,
                                onChanged: (value) {
                                  setState(() {
                                    jenisSimpanan = value.toString();
                                  });
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text('Sukarela'),
                              leading: Radio(
                                value: 'sukarela',
                                groupValue: jenisSimpanan,
                                onChanged: (value) {
                                  setState(() {
                                    jenisSimpanan = value.toString();
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: jumlahController,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Simpanan',
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
                        controller: keteranganController,
                        decoration: InputDecoration(
                          labelText: 'Keterangan (Opsional)',
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: tanggalController,
                        decoration: InputDecoration(
                          labelText: 'Tanggal',
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
                            tanggalController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(date);
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
                        final userEmail =
                            FirebaseAuth.instance.currentUser?.email ?? '-';
                        await _firestore.collection('simpanan').add({
                          'userId': userId,
                          'userEmail': userEmail,
                          'jumlah': int.parse(jumlahController.text),
                          'jenis': jenisSimpanan,
                          'keterangan': keteranganController.text,
                          'tanggal': tanggalController.text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(context);
                        _showSnackbar('Simpanan berhasil ditambahkan');
                      } catch (e) {
                        _showSnackbar(
                          'Gagal menambahkan simpanan: $e',
                          color: Colors.red,
                        );
                      }
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
