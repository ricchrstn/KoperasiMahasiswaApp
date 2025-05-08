import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kopma/services/anomaly_detection_service.dart';

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

  Future<void> _updateStatus(
    String id,
    String status,
    Map<String, dynamic> pinjamanData,
  ) async {
    try {
      await _firestore.collection('pinjaman').doc(id).update({
        'status': status,
      });
      if (status == 'Disetujui') {
        await _firestore.collection('notifications').add({
          'userId': pinjamanData['userId'],
          'title': 'Pinjaman Disetujui',
          'message':
              'Pinjaman ${_currencyFormat.format(pinjamanData['jumlah'])} telah disetujui',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pinjaman diperbarui menjadi $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    final theme = Theme.of(context);
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Silakan login untuk melihat pinjaman',
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
        ),
      );
    }
    if (_userRole == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat data...'),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          _userRole == 'admin' ? 'Kelola Pinjaman' : 'Pinjaman Saya',
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
      floatingActionButton:
          _userRole != 'admin'
              ? FloatingActionButton(
                onPressed: () => _showAddPinjamanDialog(context, user.uid),
                child: Icon(Icons.add),
                backgroundColor: Colors.green,
              )
              : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan jumlah atau tanggal...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged:
                    (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        _userRole == 'admin'
                            ? _firestore
                                .collection('pinjaman')
                                .orderBy('createdAt', descending: true)
                                .snapshots()
                            : _firestore
                                .collection('pinjaman')
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
                                'Error: {snapshot.error}',
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
                              final jumlah = (doc['jumlah'] ?? '').toString();
                              final tanggal = (doc['tanggal'] ?? '').toString();
                              return jumlah.contains(_searchQuery) ||
                                  tanggal.contains(_searchQuery);
                            }).toList();
                      }

                      if (documents.isEmpty) {
                        return Center(child: Text('Belum ada data pinjaman'));
                      }
                      return ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final pinjamanData =
                              documents[index].data() as Map<String, dynamic>;
                          final createdAt =
                              (pinjamanData['createdAt'] as Timestamp?)
                                  ?.toDate();
                          return Card(
                            color: theme.cardColor,
                            margin: EdgeInsets.all(8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Icon(Icons.money, color: Colors.green),
                              ),
                              title: Text(
                                _currencyFormat.format(
                                  pinjamanData['jumlah'] ?? 0,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal: ${pinjamanData['tanggal'] ?? '-'}',
                                  ),
                                  Text(
                                    'Status: ${pinjamanData['status'] ?? 'Menunggu'}',
                                  ),
                                ],
                              ),
                              trailing:
                                  _userRole == 'admin'
                                      ? PopupMenuButton<String>(
                                        onSelected:
                                            (value) => _updateStatus(
                                              documents[index].id,
                                              value,
                                              pinjamanData,
                                            ),
                                        itemBuilder:
                                            (context) => [
                                              PopupMenuItem(
                                                value: 'Disetujui',
                                                child: Text('Setujui'),
                                              ),
                                              PopupMenuItem(
                                                value: 'Ditolak',
                                                child: Text('Tolak'),
                                              ),
                                            ],
                                      )
                                      : _buildStatusIcon(
                                        pinjamanData['status'],
                                      ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (pinjamanData['tujuan'] != null)
                                        ListTile(
                                          leading: Icon(Icons.label),
                                          title: Text('Tujuan'),
                                          subtitle: Text(
                                            pinjamanData['tujuan'],
                                          ),
                                        ),
                                      if (pinjamanData['keterangan'] != null)
                                        ListTile(
                                          leading: Icon(Icons.note),
                                          title: Text('Keterangan'),
                                          subtitle: Text(
                                            pinjamanData['keterangan'],
                                          ),
                                        ),
                                      if (_userRole == 'admin' &&
                                          pinjamanData['userId'] != null)
                                        ListTile(
                                          leading: Icon(Icons.person),
                                          title: Text('User ID'),
                                          subtitle: Text(
                                            pinjamanData['userId'],
                                          ),
                                        ),
                                      if (_userRole == 'admin' &&
                                          pinjamanData['userEmail'] != null)
                                        ListTile(
                                          leading: Icon(Icons.email),
                                          title: Text('Email Pengguna'),
                                          subtitle: Text(
                                            pinjamanData['userEmail'],
                                          ),
                                        ),
                                      if (createdAt != null)
                                        ListTile(
                                          leading: Icon(Icons.date_range),
                                          title: Text('Diajukan'),
                                          subtitle: Text(
                                            _dateFormat.format(createdAt),
                                          ),
                                        ),
                                      if (pinjamanData['status'] ==
                                              'Disetujui' &&
                                          _userRole != 'admin')
                                        ElevatedButton(
                                          onPressed:
                                              () => _showAddCicilanDialog(
                                                context,
                                                documents[index].id,
                                              ),
                                          child: Text('Bayar Cicilan'),
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
              ),
            ],
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

  void _showAddPinjamanDialog(BuildContext context, String userId) {
    final formKey = GlobalKey<FormState>();
    final jumlahController = TextEditingController();
    final tujuanController = TextEditingController();
    final keteranganController = TextEditingController();
    final tanggalController = TextEditingController(
      text: _dateFormat.format(DateTime.now()),
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
                      if (value == null || value.isEmpty)
                        return 'Jumlah harus diisi';
                      if (int.tryParse(value) == null)
                        return 'Masukkan angka yang valid';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: tujuanController,
                    decoration: InputDecoration(labelText: 'Tujuan Pinjaman'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Tujuan harus diisi'
                                : null,
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
                        tanggalController.text = _dateFormat.format(date);
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
                    // Cek anomali sebelum menyimpan
                    final anomalyService = AnomalyDetectionService();
                    final anomalyCheck = await anomalyService
                        .detectLoanAnomalies(userId);

                    if (anomalyCheck['isAnomaly']) {
                      // Tampilkan dialog peringatan
                      bool proceed = await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Peringatan Anomali'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Sistem mendeteksi pola tidak biasa dalam pengajuan ini:',
                                    ),
                                    const SizedBox(height: 10),
                                    ...(anomalyCheck['reasons'] as List)
                                        .map((reason) => Text('- $reason'))
                                        .toList(),
                                    const SizedBox(height: 20),
                                    const Text('Lanjutkan pengajuan?'),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Lanjutkan'),
                                ),
                              ],
                            ),
                      );

                      if (!proceed) return;
                    }
                    await _firestore.collection('pinjaman').add({
                      'userId': userId,
                      'userEmail': userEmail,
                      'jumlah': int.parse(jumlahController.text),
                      'tujuan': tujuanController.text,
                      'keterangan': keteranganController.text,
                      'tanggal': tanggalController.text,
                      'status': 'Menunggu',
                      'createdAt': FieldValue.serverTimestamp(),
                      'isAnomaly': anomalyCheck['isAnomaly'],
                      'anomalyReasons': anomalyCheck['reasons'],
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pinjaman berhasil diajukan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengajukan pinjaman: $e'),
                        backgroundColor: Colors.red,
                      ),
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

  void _showAddCicilanDialog(BuildContext context, String pinjamanId) {
    final formKey = GlobalKey<FormState>();
    final jumlahController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Cicilan'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: jumlahController,
              decoration: InputDecoration(
                labelText: 'Jumlah Cicilan',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Jumlah harus diisi';
                if (int.tryParse(value) == null)
                  return 'Masukkan angka yang valid';
                return null;
              },
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
                  await _addCicilan(
                    pinjamanId,
                    int.parse(jumlahController.text),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}