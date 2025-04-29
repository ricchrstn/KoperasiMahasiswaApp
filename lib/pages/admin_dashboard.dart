import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_verification.dart';
import 'transaction_manage.dart';
import '../services/export_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
          PopupMenuButton<String>(
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
                    child: Text('Export Pinjaman'),
                  ),
                  PopupMenuItem(
                    value: 'Export Simpanan',
                    child: Text('Export Simpanan'),
                  ),
                  PopupMenuItem(
                    value: 'Export Users',
                    child: Text('Export Users'),
                  ),
                ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text('Menu Admin', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Verifikasi User'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserVerificationScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Kelola Transaksi'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionManageScreen(),
                    ),
                  ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: _buildStatistics(context),
            ),
            const SizedBox(height: 20),
            _buildBarChartSection(),
            const SizedBox(height: 20),
            _buildRecentTransactions(),
          ],
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

  Widget _buildStatistics(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _buildRealtimeStatCard(
              title: 'Total Anggota',
              icon: Icons.people,
              color: Colors.blue,
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              countField: false,
            ),
            _buildRealtimeStatCard(
              title: 'Total Simpanan',
              icon: Icons.savings,
              color: Colors.green,
              stream:
                  FirebaseFirestore.instance.collection('simpanan').snapshots(),
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
    return Flexible(
      child: SizedBox(
        width: _cardSize,
        height: _cardSize,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                FittedBox(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildBarChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Koperasi (6 Bulan Terakhir)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: _chartHeight,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8),
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
          return Center(child: Text('Error: ${pinjamanSnapshot.error}'));
        }

        if (!pinjamanSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('simpanan').snapshots(),
          builder: (context, simpananSnapshot) {
            if (simpananSnapshot.hasError) {
              return Center(child: Text('Error: ${simpananSnapshot.error}'));
            }

            if (!simpananSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

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
                      ),
                      BarChartRodData(
                        toY: chartData.simpanan[index],
                        color: Colors.blue,
                        width: 16,
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
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
                          child: Text(DateFormat('MMM').format(month)),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
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
      final tanggal = DateTime.tryParse(doc['tanggal']?.toString() ?? '');
      if (tanggal != null) {
        final monthsAgo =
            now.month - tanggal.month + (now.year - tanggal.year) * 12;
        if (monthsAgo >= 0 && monthsAgo < _monthsToShow) {
          dataPinjaman[_monthsToShow - 1 - monthsAgo] += 1;
        }
      }
    }

    for (final doc in simpananDocs) {
      final tanggal = DateTime.tryParse(doc['tanggal']?.toString() ?? '');
      if (tanggal != null) {
        final monthsAgo =
            now.month - tanggal.month + (now.year - tanggal.year) * 12;
        if (monthsAgo >= 0 && monthsAgo < _monthsToShow) {
          dataSimpanan[_monthsToShow - 1 - monthsAgo] += 1;
        }
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
        const SizedBox(height: 10),
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      'Pinjaman: ${_currencyFormat.format(data['jumlah'] ?? 0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Status: ${data['status'] ?? '-'}'),
                    trailing: Text(
                      DateFormat('dd MMM yyyy').format(
                        DateTime.tryParse(data['tanggal']?.toString() ?? '') ??
                            DateTime.now(),
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
}

class _ChartData {
  final List<double> pinjaman;
  final List<double> simpanan;

  _ChartData(this.pinjaman, this.simpanan);
}
