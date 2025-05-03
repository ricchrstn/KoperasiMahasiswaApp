import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_verification.dart';
import 'transaction_manage.dart';
import '../services/export_service.dart';
import '../services/anomaly_detection_service.dart';
import '../pages/admin_feedback_page.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class AdminDashboard extends StatelessWidget {
  static const _cardSize = 160.0;
  static const _chartHeight = 300.0;
  static const _monthsToShow = 6;
  static const _recentTransactionsLimit = 5;

  late final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.orange,
            ),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _showLogoutDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.green),
            onSelected: (value) async {
              switch (value) {
                case 'Export Pinjaman':
                  await ExportService.exportPinjaman(context);
                  break;
                case 'Export Simpanan':
                  await ExportService.exportSimpanan(context);
                  break;
                case 'Export Users':
                  await ExportService.exportUsers(context);
                  break;
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: 'Export Pinjaman',
                    child: Row(
                      children: [
                        Icon(Icons.file_download),
                        SizedBox(width: 8),
                        Text('Export Pinjaman'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Export Simpanan',
                    child: Row(
                      children: [
                        Icon(Icons.file_download),
                        SizedBox(width: 8),
                        Text('Export Simpanan'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Export Users',
                    child: Row(
                      children: [
                        Icon(Icons.file_download),
                        SizedBox(width: 8),
                        Text('Export Users'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade700.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Menu Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.verified_user, color: Colors.green.shade700),
              ),
              title: Text(
                'Verifikasi User',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserVerificationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payment, color: Colors.green.shade700),
              ),
              title: Text(
                'Kelola Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TransactionManageScreen()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.feedback, color: Colors.green.shade700),
              ),
              title: Text(
                'Lihat Feedback',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFeedbackPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        _buildRealtimeStatCard(
                          title: 'Total Anggota',
                          icon: Icons.people,
                          color: Colors.blue,
                          stream:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .snapshots(),
                          countField: false,
                        ),
                        _buildRealtimeStatCard(
                          title: 'Total Simpanan',
                          icon: Icons.savings,
                          color: Colors.green,
                          stream:
                              FirebaseFirestore.instance
                                  .collection('simpanan')
                                  .snapshots(),
                          countField: true,
                          fieldName: 'jumlah',
                        ),
                        _buildRealtimeStatCard(
                          title: 'Pinjaman Aktif',
                          icon: Icons.account_balance,
                          color: Colors.orange,
                          stream:
                              FirebaseFirestore.instance
                                  .collection('pinjaman')
                                  .where('status', isEqualTo: 'Disetujui')
                                  .snapshots(),
                          countField: false,
                        ),
                        _buildRealtimeStatCard(
                          title: 'Menunggu Verifikasi',
                          icon: Icons.hourglass_top,
                          color: Colors.purple,
                          stream:
                              FirebaseFirestore.instance
                                  .collection('pinjaman')
                                  .where('status', isEqualTo: 'Menunggu')
                                  .snapshots(),
                          countField: false,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildAnomalyAlerts(context),
                const SizedBox(height: 20),
                _buildBarChartSection(),
                const SizedBox(height: 20),
                _buildRecentTransactions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Anda yakin ingin logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  Widget _buildRealtimeStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot<Object?>> stream,
    required bool countField,
    String? fieldName,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildStatCard(title, icon, Colors.red, 'Error');
        }

        if (!snapshot.hasData) {
          return _buildStatCard(title, icon, color, '...');
        }

        if (countField && fieldName != null) {
          double total = 0;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data[fieldName] ?? 0).toDouble();
          }
          return _buildStatCard(
            title,
            icon,
            color,
            _currencyFormat.format(total),
          );
        } else {
          return _buildStatCard(
            title,
            icon,
            color,
            snapshot.data!.docs.length.toString(),
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    String title,
    IconData icon,
    Color color,
    String value,
  ) {
    return SizedBox(
      width: 160,
      child: Container(
        height: _cardSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Koperasi (6 Bulan Terakhir)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: _chartHeight,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildBarChart(),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pinjaman').snapshots(),
      builder: (context, pinjamanSnapshot) {
        if (pinjamanSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: ${pinjamanSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!pinjamanSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('simpanan').snapshots(),
          builder: (context, simpananSnapshot) {
            if (simpananSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${simpananSnapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!simpananSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            try {
              final chartData = _prepareChartData(
                pinjamanSnapshot.data!.docs,
                simpananSnapshot.data!.docs,
              );

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(chartData.pinjaman, chartData.simpanan),
                  barGroups: List.generate(_monthsToShow, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: chartData.pinjaman[index],
                          color: Colors.orange,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        BarChartRodData(
                          toY: chartData.simpanan[index],
                          color: Colors.blue,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final now = DateTime.now();
                          final month = now.subtract(
                            Duration(days: 30 * (5 - value.toInt())),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(month),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              );
            } catch (e) {
              return Center(child: Text('Error: $e'));
            }
          },
        );
      },
    );
  }

  _ChartData _prepareChartData(
    List<QueryDocumentSnapshot<Object?>> pinjamanDocs,
    List<QueryDocumentSnapshot<Object?>> simpananDocs,
  ) {
    final now = DateTime.now();
    final dataPinjaman = List<double>.filled(_monthsToShow, 0);
    final dataSimpanan = List<double>.filled(_monthsToShow, 0);

    for (final doc in pinjamanDocs) {
      try {
        final tanggalStr = doc['tanggal']?.toString();
        if (tanggalStr == null) continue;

        final tanggal = DateTime.tryParse(tanggalStr);
        if (tanggal == null) continue;

        final monthsAgo =
            (now.year - tanggal.year) * 12 + (now.month - tanggal.month);
        if (monthsAgo >= 0 && monthsAgo < _monthsToShow) {
          dataPinjaman[_monthsToShow - 1 - monthsAgo] += 1;
        }
      } catch (e) {
        debugPrint('Error processing pinjaman document: $e');
      }
    }

    for (final doc in simpananDocs) {
      try {
        final tanggalStr = doc['tanggal']?.toString();
        if (tanggalStr == null) continue;

        final tanggal = DateTime.tryParse(tanggalStr);
        if (tanggal == null) continue;

        final monthsAgo =
            (now.year - tanggal.year) * 12 + (now.month - tanggal.month);
        if (monthsAgo >= 0 && monthsAgo < _monthsToShow) {
          dataSimpanan[_monthsToShow - 1 - monthsAgo] += 1;
        }
      } catch (e) {
        debugPrint('Error processing simpanan document: $e');
      }
    }

    return _ChartData(dataPinjaman, dataSimpanan);
  }

  double _calculateMaxY(List<double> a, List<double> b) {
    final maxA = a.isNotEmpty ? a.reduce((a, b) => a > b ? a : b) : 0;
    final maxB = b.isNotEmpty ? b.reduce((a, b) => a > b ? a : b) : 0;
    return (maxA > maxB ? maxA : maxB) + 2;
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaksi Terakhir',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('pinjaman')
                  .orderBy('createdAt', descending: true)
                  .limit(_recentTransactionsLimit)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pinjaman = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pinjaman.length,
              itemBuilder: (context, index) {
                final data = pinjaman[index].data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      'Pinjaman: ${_currencyFormat.format(data['jumlah'] ?? 0)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Status: ${data['status'] ?? '-'}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Text(
                      DateFormat('dd MMM yyyy').format(
                        DateTime.tryParse(data['tanggal']?.toString() ?? '') ??
                            DateTime.now(),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnomalyAlerts(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AnomalyDetectionService().checkNewLoansForAnomalies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final anomalies = snapshot.data ?? [];
        if (anomalies.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 12),
                const Text(
                  'Tidak ada anomali terdeteksi',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peringatan Anomali',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ...anomalies.map(
              (anomaly) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning, color: Colors.red),
                  ),
                  title: Text(
                    'Anomali pengajuan dari ${anomaly['user_email']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'Jumlah: Rp${NumberFormat('#,###').format(anomaly['amount'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...(anomaly['anomaly_details']['reasons'] as List)
                          .map(
                            (reason) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '• $reason',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                  trailing: Text(
                    anomaly['date'],
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartData {
  final List<double> pinjaman;
  final List<double> simpanan;

  _ChartData(this.pinjaman, this.simpanan);
}
