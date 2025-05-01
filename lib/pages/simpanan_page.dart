import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kopma/pages/dashboard_page.dart';

class SimpananPage extends StatefulWidget {
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
  String _filterTanggal = 'Semua';
  String _jenisSimpanan = 'semua';

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
    final User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Simpanan'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Silakan login untuk melihat simpanan',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_userRole == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Simpanan'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
        title: Text(_userRole == 'admin' ? 'Kelola Simpanan' : 'Simpanan Saya'),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'Semua' ||
                    value == 'Bulan Ini' ||
                    value == '3 Bulan Terakhir') {
                  _filterTanggal = value;
                } else {
                  _jenisSimpanan = value;
                }
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    child: Text('Filter Tanggal'),
                    enabled: false,
                  ),
                  const PopupMenuItem(
                    value: 'Semua',
                    child: Text('Semua Tanggal'),
                  ),
                  const PopupMenuItem(
                    value: 'Bulan Ini',
                    child: Text('Bulan Ini'),
                  ),
                  const PopupMenuItem(
                    value: '3 Bulan Terakhir',
                    child: Text('3 Bulan Terakhir'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    child: Text('Jenis Simpanan'),
                    enabled: false,
                  ),
                  const PopupMenuItem(
                    value: 'semua',
                    child: Text('Semua Jenis'),
                  ),
                  const PopupMenuItem(value: 'wajib', child: Text('Wajib')),
                  const PopupMenuItem(
                    value: 'sukarela',
                    child: Text('Sukarela'),
                  ),
                ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton:
          _userRole != 'admin'
              ? FloatingActionButton(
                onPressed: () => _showAddSimpananDialog(context, user.uid),
                child: Icon(Icons.add),
                backgroundColor: Colors.blue,
              )
              : null,
      body: Column(
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

                if (snapshot.connectionState == ConnectionState.waiting) {
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

                // Filter tanggal
                if (_filterTanggal != 'Semua') {
                  final now = DateTime.now();
                  documents =
                      documents.where((doc) {
                        final tanggal = DateTime.tryParse(doc['tanggal'] ?? '');
                        if (tanggal == null) return false;
                        if (_filterTanggal == 'Bulan Ini') {
                          return tanggal.month == now.month &&
                              tanggal.year == now.year;
                        } else if (_filterTanggal == '3 Bulan Terakhir') {
                          return now.difference(tanggal).inDays <= 90;
                        }
                        return true;
                      }).toList();
                }

                // Filter jenis
                if (_jenisSimpanan != 'semua') {
                  documents =
                      documents.where((doc) {
                        final jenis =
                            doc.data().toString().contains('jenis')
                                ? (doc['jenis'] ?? 'sukarela')
                                : 'sukarela';
                        return jenis == _jenisSimpanan;
                      }).toList();
                }

                // Search jumlah
                if (_searchQuery.isNotEmpty) {
                  documents =
                      documents.where((doc) {
                        final jumlah = (doc['jumlah'] ?? '').toString();
                        return jumlah.contains(_searchQuery);
                      }).toList();
                }

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.savings, size: 50, color: Colors.blue),
                        SizedBox(height: 16),
                        Text('Belum ada data simpanan'),
                        if (_userRole != 'admin')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed:
                                  () =>
                                      _showAddSimpananDialog(context, user.uid),
                              child: Text('Tambah Simpanan'),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // Hitung total
                double totalWajib = documents
                    .where((doc) {
                      final jenis =
                          doc.data().toString().contains('jenis')
                              ? (doc['jenis'] ?? 'sukarela')
                              : 'sukarela';
                      return jenis == 'wajib';
                    })
                    .fold(
                      0,
                      (sum, doc) =>
                          sum + ((doc.data() as Map)['jumlah'] ?? 0).toDouble(),
                    );

                double totalSukarela = documents
                    .where((doc) {
                      final jenis =
                          doc.data().toString().contains('jenis')
                              ? (doc['jenis'] ?? 'sukarela')
                              : 'sukarela';
                      return jenis == 'sukarela';
                    })
                    .fold(
                      0,
                      (sum, doc) =>
                          sum + ((doc.data() as Map)['jumlah'] ?? 0).toDouble(),
                    );

                double total = totalWajib + totalSukarela;

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
                              _currencyFormat.format(total),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Wajib',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      _currencyFormat.format(totalWajib),
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
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      _currencyFormat.format(totalSukarela),
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
                              documents[index].data() as Map<String, dynamic>;
                          final jenis =
                              simpanan.containsKey('jenis')
                                  ? simpanan['jenis']
                                  : 'sukarela';

                          return Card(
                            margin: EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    jenis == 'wajib'
                                        ? Colors.blue[100]
                                        : Colors.green[100],
                                child: Icon(
                                  Icons.savings,
                                  color:
                                      jenis == 'wajib'
                                          ? Colors.blue
                                          : Colors.green,
                                ),
                              ),
                              title: Text(
                                _currencyFormat.format(simpanan['jumlah']),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal: ${simpanan['tanggal'] ?? '-'}',
                                  ),
                                  Text(
                                    'Jenis: ${jenis == 'wajib' ? 'Wajib' : 'Sukarela'}',
                                  ),
                                  if (simpanan['keterangan'] != null)
                                    Text(
                                      'Keterangan: ${simpanan['keterangan']}',
                                    ),
                                ],
                              ),
                              trailing:
                                  _userRole != 'admin'
                                      ? IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteSimpanan(
                                              documents[index].id,
                                            ),
                                      )
                                      : null,
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
                        await _firestore.collection('simpanan').add({
                          'userId': userId,
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

  Widget _buildStatusBadge(String? status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'Disetujui':
        statusColor = Colors.green;
        statusText = 'Disetujui';
        statusIcon = Icons.check_circle;
        break;
      case 'Ditolak':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        statusIcon = Icons.cancel;
        break;
      case 'Menunggu':
      default:
        statusColor = Colors.orange;
        statusText = 'Menunggu';
        statusIcon = Icons.access_time;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
