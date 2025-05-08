import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login_page.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class TransactionManageScreen extends StatefulWidget {
  const TransactionManageScreen({super.key});

  @override
  State<TransactionManageScreen> createState() =>
      _TransactionManageScreenState();
}

class _TransactionManageScreenState extends State<TransactionManageScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Silakan login terlebih dahulu';
        });
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Anda tidak memiliki akses ke halaman ini';
        });
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _isLoading = false;
        _isAdmin = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _exportToExcel(String type) async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin penyimpanan diperlukan untuk mengekspor data',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Create Excel workbook
      var excelFile = excel.Excel.createExcel();
      var sheet = excelFile[type];

      // Add headers
      List<String> headers = [
        'No',
        'Tanggal',
        'Email Pengguna',
        'Jumlah',
        'Status',
        'Tanggal Disetujui/Ditolak',
      ];
      if (type == 'Pinjaman') {
        headers.addAll(['Tujuan', 'Keterangan']);
      }

      // Style for headers
      var headerStyle = excel.CellStyle(
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
        backgroundColorHex: '#C0C0C0',
      );

      // Add headers with style
      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      // Fetch data from Firestore
      var collection = type.toLowerCase();
      var snapshot =
          await FirebaseFirestore.instance
              .collection(collection)
              .orderBy('createdAt', descending: true)
              .get();

      // Add data rows
      var row = 1;
      for (var doc in snapshot.docs) {
        var data = doc.data();
        var approvedAt = data['approvedAt'] as Timestamp?;
        var rejectedAt = data['rejectedAt'] as Timestamp?;
        var statusDate = approvedAt ?? rejectedAt;

        List<dynamic> rowData = [
          row,
          data['tanggal'] ?? '-',
          data['userEmail'] ?? '-',
          data['jumlah']?.toString() ?? '0',
          data['status'] ?? 'Menunggu',
          statusDate != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(statusDate.toDate())
              : '-',
        ];

        if (type == 'Pinjaman') {
          rowData.addAll([data['tujuan'] ?? '-', data['keterangan'] ?? '-']);
        }

        // Add data with style
        for (var i = 0; i < rowData.length; i++) {
          var cell = sheet.cell(
            excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
          );
          cell.value = rowData[i];
          cell.cellStyle = excel.CellStyle(
            horizontalAlign:
                i == 0 || i == 3
                    ? excel.HorizontalAlign.Right
                    : excel.HorizontalAlign.Left,
          );
        }
        row++;
      }

      // Auto fit columns
      final workbook = xlsio.Workbook();
      final loanSheet = workbook.worksheets[0];
      final savingsSheet = workbook.worksheets.addWithName('Savings');
      final summarySheet = workbook.worksheets.addWithName('Summary');

      // ← taruh kode loop yang tadi di sini
      // Fungsi untuk ubah angka ke huruf kolom Excel (0 -> A, 1 -> B, ..., 26 -> AA)
      String getColumnLetter(int index) {
        String letter = '';
        while (index >= 0) {
          letter = String.fromCharCode((index % 26) + 65) + letter;
          index = (index ~/ 26) - 1;
        }
        return letter;
      }

      // Ini pengganti kode lamamu
      for (var sheet in [loanSheet, savingsSheet, summarySheet]) {
        for (var i = 0; i < 7; i++) {
          String column = getColumnLetter(i); // A, B, C, D, dst
          sheet.getRangeByName('${column}1').columnWidth = 15;
        }
      }

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          '${type.toLowerCase()}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
      final filePath = '${directory.path}/$fileName';

      // Save file
      var fileBytes = excelFile.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File telah disimpan di: $filePath'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Buka',
                onPressed: () async {
                  // You might want to implement file opening functionality here
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Kelola Transaksi',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.green),
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

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Kelola Transaksi',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.green),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_errorMessage == 'Silakan login terlebih dahulu') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  } else {
                    _checkAdminStatus();
                  }
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Kelola Transaksi',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.green),
        ),
        body: const Center(
          child: Text('Anda tidak memiliki akses ke halaman ini'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Kelola Transaksi',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.green),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download, color: Colors.green),
              tooltip: 'Ekspor Data',
              onSelected: _exportToExcel,
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'Pinjaman',
                      child: Text('Ekspor Data Pinjaman'),
                    ),
                    const PopupMenuItem(
                      value: 'Simpanan',
                      child: Text('Ekspor Data Simpanan'),
                    ),
                  ],
            ),
          ],
          bottom: TabBar(
            tabs: const [Tab(text: 'Pinjaman'), Tab(text: 'Simpanan')],
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: const TabBarView(children: [PinjamanTab(), SimpananTab()]),
      ),
    );
  }
}

class PinjamanTab extends StatelessWidget {
  const PinjamanTab({super.key});

  Future<void> _handleAction(
    BuildContext context,
    String action,
    String docId,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'approve':
        await _approveLoan(context, docId);
        break;
      case 'reject':
        await _rejectLoan(context, docId);
        break;
      case 'edit':
        await _editLoan(context, docId, data);
        break;
      case 'delete':
        await _confirmDelete(context, docId);
        break;
    }
  }

  Future<void> _approveLoan(BuildContext context, String docId) async {
    final TextEditingController notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Setujui Pinjaman'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yakin ingin menyetujui pinjaman ini?'),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Setujui'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('pinjaman')
            .doc(docId)
            .update({
              'status': 'Disetujui',
              'approvedAt': FieldValue.serverTimestamp(),
              'adminNotes': notesController.text,
            });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pinjaman berhasil disetujui')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyetujui pinjaman')),
          );
        }
      }
    }
  }

  Future<void> _rejectLoan(BuildContext context, String docId) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tolak Pinjaman'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yakin ingin menolak pinjaman ini?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan penolakan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  if (reasonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Harap masukkan alasan penolakan'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Tolak'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('pinjaman')
            .doc(docId)
            .update({
              'status': 'Ditolak',
              'rejectedAt': FieldValue.serverTimestamp(),
              'rejectionReason': reasonController.text,
            });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pinjaman berhasil ditolak')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menolak pinjaman')),
          );
        }
      }
    }
  }

  Future<void> _editLoan(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final TextEditingController amountController = TextEditingController(
      text: data['jumlah']?.toString() ?? '',
    );
    final TextEditingController purposeController = TextEditingController(
      text: data['tujuan']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Pinjaman'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Tujuan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('pinjaman')
                        .doc(docId)
                        .update({
                          'jumlah': int.parse(amountController.text),
                          'tujuan': purposeController.text,
                        });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pinjaman berhasil diperbarui'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal memperbarui pinjaman'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text('Yakin ingin menghapus pinjaman ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('pinjaman')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pinjaman berhasil dihapus')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus pinjaman')),
          );
        }
      }
    }
  }

  Widget _buildStatusBadge(String status) {
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

    return Chip(
      backgroundColor: statusColor.withOpacity(0.1),
      label: Text(statusText, style: TextStyle(color: statusColor)),
      avatar: Icon(statusIcon, color: statusColor, size: 18),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('pinjaman')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final loans = snapshot.data!.docs;

        if (loans.isEmpty) {
          return const Center(child: Text('Belum ada data pinjaman.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final doc = loans[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Menunggu';
            final amount = data['jumlah'] ?? 0;
            final purpose = data['tujuan'] ?? '-';
            final date = data['tanggal'] ?? '-';
            final userEmail = data['userEmail'] ?? '-';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengaju: $userEmail'),
                    Text('Tanggal: $date'),
                    _buildStatusBadge(status),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.person,
                          'Pengaju',
                          userEmail,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.calendar_today, 'Tanggal', date),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Jumlah',
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(amount),
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.description, 'Tujuan', purpose),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.info,
                          'Status',
                          status,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'Menunggu') ...[
                              IconButton(
                                icon: const Icon(Icons.check),
                                color: Colors.green,
                                tooltip: 'Setujui',
                                onPressed:
                                    () => _handleAction(
                                      context,
                                      'approve',
                                      doc.id,
                                      data,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.red,
                                tooltip: 'Tolak',
                                onPressed:
                                    () => _handleAction(
                                      context,
                                      'reject',
                                      doc.id,
                                      data,
                                    ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              tooltip: 'Edit',
                              onPressed:
                                  () => _handleAction(
                                    context,
                                    'edit',
                                    doc.id,
                                    data,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              tooltip: 'Hapus',
                              onPressed:
                                  () => _handleAction(
                                    context,
                                    'delete',
                                    doc.id,
                                    data,
                                  ),
                            ),
                          ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Menunggu':
      default:
        return Colors.orange;
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class SimpananTab extends StatelessWidget {
  const SimpananTab({super.key});

  Future<void> _handleAction(
    BuildContext context,
    String action,
    String docId,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'approve':
        await _approveSavings(context, docId);
        break;
      case 'reject':
        await _rejectSavings(context, docId);
        break;
      case 'edit':
        await _editSavings(context, docId, data);
        break;
      case 'delete':
        await _confirmDelete(context, docId);
        break;
    }
  }

  Future<void> _approveSavings(BuildContext context, String docId) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Setujui Simpanan'),
            content: const Text('Yakin ingin menyetujui simpanan ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Setujui'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('simpanan')
            .doc(docId)
            .update({
              'status': 'Disetujui',
              'approvedAt': FieldValue.serverTimestamp(),
            });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Simpanan berhasil disetujui')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyetujui simpanan')),
          );
        }
      }
    }
  }

  Future<void> _rejectSavings(BuildContext context, String docId) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tolak Simpanan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yakin ingin menolak simpanan ini?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan penolakan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  if (reasonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Harap masukkan alasan penolakan'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Tolak'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('simpanan')
            .doc(docId)
            .update({
              'status': 'Ditolak',
              'rejectedAt': FieldValue.serverTimestamp(),
              'rejectionReason': reasonController.text,
            });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Simpanan berhasil ditolak')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menolak simpanan')),
          );
        }
      }
    }
  }

  Future<void> _editSavings(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final TextEditingController amountController = TextEditingController(
      text: data['jumlah']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Simpanan'),
            content: TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('simpanan')
                        .doc(docId)
                        .update({'jumlah': int.parse(amountController.text)});
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Simpanan berhasil diperbarui'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal memperbarui simpanan'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text('Yakin ingin menghapus simpanan ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('simpanan')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Simpanan berhasil dihapus')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus simpanan')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('simpanan')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final savings = snapshot.data!.docs;

        if (savings.isEmpty) {
          return const Center(child: Text('Belum ada data simpanan.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: savings.length,
          itemBuilder: (context, index) {
            final doc = savings[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Menunggu';
            final amount = data['jumlah'] ?? 0;
            final date = data['tanggal'] ?? '-';
            final userEmail = data['userEmail'] ?? '-';
            final jenis = data['jenis'] ?? 'sukarela';
            final approvedAt = data['approvedAt'] as Timestamp?;
            final rejectedAt = data['rejectedAt'] as Timestamp?;
            final rejectionReason = data['rejectionReason'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.person, color: Colors.green),
                ),
                title: Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengaju: $userEmail'),
                    Text('Tanggal: $date'),
                    _buildStatusBadge(status),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.person,
                          'Pengaju',
                          userEmail,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.calendar_today, 'Tanggal', date),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Jumlah',
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(amount),
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.category,
                          'Jenis',
                          jenis == 'wajib' ? 'Wajib' : 'Sukarela',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.info,
                          'Status',
                          status,
                          color: _getStatusColor(status),
                        ),
                        if (status == 'Disetujui' && approvedAt != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.check_circle,
                            'Disetujui pada',
                            DateFormat(
                              'dd MMM yyyy HH:mm',
                            ).format(approvedAt.toDate()),
                            color: Colors.green,
                          ),
                        ],
                        if (status == 'Ditolak' && rejectedAt != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.cancel,
                            'Ditolak pada',
                            DateFormat(
                              'dd MMM yyyy HH:mm',
                            ).format(rejectedAt.toDate()),
                            color: Colors.red,
                          ),
                          if (rejectionReason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.comment,
                              'Alasan',
                              rejectionReason,
                              color: Colors.red,
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'Menunggu') ...[
                              IconButton(
                                icon: const Icon(Icons.check),
                                color: Colors.green,
                                tooltip: 'Setujui',
                                onPressed:
                                    () => _handleAction(
                                      context,
                                      'approve',
                                      doc.id,
                                      data,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.red,
                                tooltip: 'Tolak',
                                onPressed:
                                    () => _handleAction(
                                      context,
                                      'reject',
                                      doc.id,
                                      data,
                                    ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              tooltip: 'Edit',
                              onPressed:
                                  () => _handleAction(
                                    context,
                                    'edit',
                                    doc.id,
                                    data,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              tooltip: 'Hapus',
                              onPressed:
                                  () => _handleAction(
                                    context,
                                    'delete',
                                    doc.id,
                                    data,
                                  ),
                            ),
                          ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Menunggu':
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
