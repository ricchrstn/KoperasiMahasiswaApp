import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kopma/services/anomaly_detection_service.dart';
import 'package:flutter/cupertino.dart';

class PinjamanPage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  PinjamanPage({this.onBackToHome, Key? key}) : super(key: key);
  @override
  _PinjamanPageState createState() => _PinjamanPageState();
}

class _PinjamanPageState extends State<PinjamanPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  String? _userRole;
  String _searchQuery = '';
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _userRole = doc.data()?['role'] ?? 'mahasiswa';
        });
      } catch (e) {
        setState(() {
          _userRole = 'mahasiswa';
        });
      }
    }
  }

  Future<void> _addCicilan(String pinjamanId, int jumlah) async {
    try {
      await _firestore.collection('cicilan').add({
        'pinjamanId': pinjamanId,
        'jumlah': jumlah,
        'tanggal': _dateFormat.format(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cicilan berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan cicilan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Mendefinisikan variabel theme
    return WillPopScope(
      onWillPop: () async {
        // Tambahkan logika jika diperlukan, misalnya menampilkan dialog konfirmasi
        return true; // Mengizinkan navigasi kembali
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            'Pinjaman',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
          leading:
              widget.onBackToHome != null
                  ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: widget.onBackToHome,
                  )
                  : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Cari berdasarkan jumlah atau tanggal...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged:
                                (value) => setState(
                                  () => _searchQuery = value.toLowerCase(),
                                ),
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                _userRole == 'admin'
                                    ? _firestore
                                        .collection('pinjaman')
                                        .orderBy('createdAt', descending: true)
                                        .snapshots()
                                    : _firestore
                                        .collection('pinjaman')
                                        .where(
                                          'userId',
                                          isEqualTo: _auth.currentUser?.uid,
                                        )
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

                              if (_filterStatus != 'Semua') {
                                documents =
                                    documents
                                        .where(
                                          (doc) => (doc['status'] ?? '')
                                              .toString()
                                              .contains(_filterStatus),
                                        )
                                        .toList();
                              }

                              if (_searchQuery.isNotEmpty) {
                                documents =
                                    documents.where((doc) {
                                      final jumlah =
                                          (doc['jumlah'] ?? '').toString();
                                      final tanggal =
                                          (doc['tanggal'] ?? '').toString();
                                      return jumlah.contains(_searchQuery) ||
                                          tanggal.contains(_searchQuery);
                                    }).toList();
                              }

                              if (documents.isEmpty) {
                                return Center(
                                  child: Text('Belum ada data pinjaman'),
                                );
                              }
                              return ListView.builder(
                                itemCount: documents.length,
                                itemBuilder: (context, index) {
                                  final pinjamanData =
                                      documents[index].data()
                                          as Map<String, dynamic>;
                                  final createdAt =
                                      (pinjamanData['createdAt'] as Timestamp?)
                                          ?.toDate();
                                  return Card(
                                    color: theme.cardColor,
                                    margin: EdgeInsets.all(8),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green[100],
                                        child: Icon(
                                          Icons.money,
                                          color: Colors.green,
                                        ),
                                      ),
                                      title: Text(
                                        _currencyFormat.format(
                                          pinjamanData['jumlah'] ?? 0,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tanggal: ${pinjamanData['tanggal'] ?? '-'}',
                                          ),
                                          Text(
                                            'Status: ${pinjamanData['status'] ?? 'Menunggu'}',
                                          ),
                                        ],
                                      ),
                                      trailing: _buildStatusIcon(
                                        pinjamanData['status'],
                                      ),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              if (pinjamanData['tujuan'] !=
                                                  null)
                                                ListTile(
                                                  leading: Icon(Icons.label),
                                                  title: Text('Tujuan'),
                                                  subtitle: Text(
                                                    pinjamanData['tujuan'],
                                                  ),
                                                ),
                                              if (pinjamanData['keterangan'] !=
                                                  null)
                                                ListTile(
                                                  leading: Icon(Icons.note),
                                                  title: Text('Keterangan'),
                                                  subtitle: Text(
                                                    pinjamanData['keterangan'],
                                                  ),
                                                ),
                                              if (createdAt != null)
                                                ListTile(
                                                  leading: Icon(
                                                    Icons.date_range,
                                                  ),
                                                  title: Text('Diajukan'),
                                                  subtitle: Text(
                                                    _dateFormat.format(
                                                      createdAt,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String? status) {
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
