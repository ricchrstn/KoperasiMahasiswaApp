import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopma/pages/login_page.dart';
import 'simpanan_page.dart';
import 'pinjaman_page.dart';
import 'profil_page.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:kopma/pages/about_page.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'feedback_page.dart';
import 'package:flutter/cupertino.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;
  String? _errorMessage;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _userRole = userDoc.data()?['role'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData(String type) async {
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
          await _firestore
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
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
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

  Future<void> _generateMonthlyReport(DateTime selectedDate) async {
    try {
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

      // Create sheets for both loan and savings
      var loanSheet = excelFile['Pinjaman'];
      var savingsSheet = excelFile['Simpanan'];

      // Get the first and last day of selected month
      final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
      final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      // Style for headers
      var headerStyle = excel.CellStyle(
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
        backgroundColorHex: '#C0C0C0',
      );

      // Headers for loan sheet
      var loanHeaders = [
        'No',
        'Tanggal',
        'Email Pengguna',
        'Jumlah',
        'Status',
        'Tujuan',
        'Keterangan',
      ];

      // Headers for savings sheet
      var savingsHeaders = [
        'No',
        'Tanggal',
        'Email Pengguna',
        'Jumlah',
        'Status',
        'Jenis Simpanan',
      ];

      // Add headers to loan sheet
      for (var i = 0; i < loanHeaders.length; i++) {
        var cell = loanSheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = loanHeaders[i];
        cell.cellStyle = headerStyle;
      }

      // Add headers to savings sheet
      for (var i = 0; i < savingsHeaders.length; i++) {
        var cell = savingsSheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = savingsHeaders[i];
        cell.cellStyle = headerStyle;
      }

      // Fetch loan data
      var loanSnapshot =
          await _firestore
              .collection('pinjaman')
              .where('createdAt', isGreaterThanOrEqualTo: firstDay)
              .where('createdAt', isLessThanOrEqualTo: lastDay)
              .orderBy('createdAt', descending: true)
              .get();

      // Add loan data
      var loanRow = 1;
      num totalLoans = 0;
      num approvedLoans = 0;
      num rejectedLoans = 0;
      num pendingLoans = 0;

      for (var doc in loanSnapshot.docs) {
        var data = doc.data();
        List<dynamic> rowData = [
          loanRow,
          data['tanggal'] ?? '-',
          data['userEmail'] ?? '-',
          data['jumlah']?.toString() ?? '0',
          data['status'] ?? 'Menunggu',
          data['tujuan'] ?? '-',
          data['keterangan'] ?? '-',
        ];

        // Update statistics
        num amount = data['jumlah'] ?? 0;
        totalLoans += amount;
        switch (data['status']) {
          case 'Disetujui':
            approvedLoans += amount;
            break;
          case 'Ditolak':
            rejectedLoans += amount;
            break;
          default:
            pendingLoans += amount;
        }

        for (var i = 0; i < rowData.length; i++) {
          var cell = loanSheet.cell(
            excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: loanRow),
          );
          cell.value = rowData[i];
          cell.cellStyle = excel.CellStyle(
            horizontalAlign:
                i == 0 || i == 3
                    ? excel.HorizontalAlign.Right
                    : excel.HorizontalAlign.Left,
          );
        }
        loanRow++;
      }

      // Fetch savings data
      var savingsSnapshot =
          await _firestore
              .collection('simpanan')
              .where('createdAt', isGreaterThanOrEqualTo: firstDay)
              .where('createdAt', isLessThanOrEqualTo: lastDay)
              .orderBy('createdAt', descending: true)
              .get();

      // Add savings data
      var savingsRow = 1;
      num totalSavings = 0;
      num mandatorySavings = 0;
      num voluntarySavings = 0;

      for (var doc in savingsSnapshot.docs) {
        var data = doc.data();
        List<dynamic> rowData = [
          savingsRow,
          data['tanggal'] ?? '-',
          data['userEmail'] ?? '-',
          data['jumlah']?.toString() ?? '0',
          data['status'] ?? 'Menunggu',
          data['jenis'] ?? 'sukarela',
        ];

        // Update statistics
        num amount = data['jumlah'] ?? 0;
        totalSavings += amount;
        if (data['jenis'] == 'wajib') {
          mandatorySavings += amount;
        } else {
          voluntarySavings += amount;
        }

        for (var i = 0; i < rowData.length; i++) {
          var cell = savingsSheet.cell(
            excel.CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: savingsRow,
            ),
          );
          cell.value = rowData[i];
          cell.cellStyle = excel.CellStyle(
            horizontalAlign:
                i == 0 || i == 3
                    ? excel.HorizontalAlign.Right
                    : excel.HorizontalAlign.Left,
          );
        }
        savingsRow++;
      }

      // Add summary sheet
      var summarySheet = excelFile['Ringkasan'];
      var summaryHeaders = ['Kategori', 'Jumlah'];

      // Add headers to summary sheet
      for (var i = 0; i < summaryHeaders.length; i++) {
        var cell = summarySheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = summaryHeaders[i];
        cell.cellStyle = headerStyle;
      }

      // Add summary data
      var summaryData = [
        ['Total Pinjaman', totalLoans],
        ['- Pinjaman Disetujui', approvedLoans],
        ['- Pinjaman Ditolak', rejectedLoans],
        ['- Pinjaman Menunggu', pendingLoans],
        ['', ''],
        ['Total Simpanan', totalSavings],
        ['- Simpanan Wajib', mandatorySavings],
        ['- Simpanan Sukarela', voluntarySavings],
      ];

      for (var i = 0; i < summaryData.length; i++) {
        for (var j = 0; j < summaryData[i].length; j++) {
          var cell = summarySheet.cell(
            excel.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
          );
          var value = summaryData[i][j];
          cell.value = value is num ? _currencyFormat.format(value) : value;
          cell.cellStyle = excel.CellStyle(
            bold: i == 0 || i == 5,
            horizontalAlign:
                j == 1
                    ? excel.HorizontalAlign.Right
                    : excel.HorizontalAlign.Left,
          );
        }
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final monthYear = DateFormat('MMMM_yyyy').format(selectedDate);
      final fileName = 'laporan_${monthYear.toLowerCase()}.xlsx';
      final filePath = '${directory.path}/$fileName';

      var fileBytes = excelFile.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Laporan bulan $monthYear telah disimpan di: $filePath',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                onPressed: _checkUserRole,
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return WillPopScope(
      onWillPop: () async {
        // Mencegah error saat tombol back ditekan
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Menghapus ikon back default
          backgroundColor: Colors.green,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logokopma.png',
                width: 60, // Memperbesar logo
                height: 60,
              ),
              SizedBox(width: 15),
              Text(
                'Koperasi Mahasiswa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24, // Memperbesar ukuran teks
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round),
              tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
              onPressed: () => themeProvider.toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                padding: EdgeInsets.all(16),
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.account_balance,
                    title: 'Pinjaman',
                    color: Colors.blue,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PinjamanPage(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.savings,
                    title: 'Simpanan',
                    color: Colors.green,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SimpananPage(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.person,
                    title: 'Profil',
                    color: Colors.orange,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilPage()),
                        ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.feedback,
                    title: 'Feedback',
                    color: Colors.purple,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackPage(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.info,
                    title: 'Tentang Pembuat',
                    color: Colors.teal,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutPage()),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi'),
            content: Text('Yakin ingin Keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Keluar'),
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

  // Added logout dialog functionality.
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi Keluar'),
            content: Text('Yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                },
                child: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Updated HomeContent to improve layout and added logout functionality in AppBar.
class HomeContent extends StatelessWidget {
  final String? userRole;
  final VoidCallback? onLogout;

  const HomeContent({Key? key, required this.userRole, this.onLogout})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green[50]!, Colors.white],
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 12),
                Image.asset(
                  'assets/images/logokopma.png',
                  width: 70,
                  height: 70,
                ),
                SizedBox(height: 6),
                Text(
                  'Selamat Datang di Koperasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    childAspectRatio: 0.95,
                    children: [
                      _buildMenuCard(
                        context,
                        icon: Icons.account_balance,
                        title: 'Pinjaman',
                        color: Colors.blue,
                        onTap: () => _navigateToPage(context, 2),
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.savings,
                        title: 'Simpanan',
                        color: Colors.green,
                        onTap: () => _navigateToPage(context, 1),
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.person,
                        title: 'Profil',
                        color: Colors.orange,
                        onTap: () => _navigateToPage(context, 3),
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.info,
                        title: 'Tentang Pembuat',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AboutPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onLogout != null)
            Positioned(
              top: 10,
              right: 54,
              child: IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny : Icons.nightlight_round,
                  color: Colors.orange,
                ),
                tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
                onPressed: () => themeProvider.toggleTheme(),
              ),
            ),
          if (onLogout != null)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.logout, color: Colors.red),
                tooltip: 'Logout',
                onPressed: onLogout,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Added the missing _navigateToPage method to the HomeContent class.
  void _navigateToPage(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_DashboardPageState>();
    state?.setState(() {
      state._selectedIndex = index;
    });
  }
}

// Added extension for accessing state.
extension _FindDashboardState on BuildContext {
  _DashboardPageState? findAncestorStateOfType<_DashboardPageState>() {
    return findAncestorStateOfType<_DashboardPageState>();
  }
}
