import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/export_service.dart'; // kita akan buat ini juga

class AdminHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Export Pinjaman') {
                ExportService.exportPinjaman(context);
              } else if (value == 'Export Simpanan') {
                ExportService.exportSimpanan(context);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'Export Pinjaman',
                    child: Text('Export Pinjaman ke PDF'),
                  ),
                  PopupMenuItem(
                    value: 'Export Simpanan',
                    child: Text('Export Simpanan ke PDF'),
                  ),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Statistik Koperasi (6 Bulan Terakhir)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(child: _buildBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pinjaman').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final now = DateTime.now();
        List<double> dataPinjaman = List.generate(6, (_) => 0);
        List<double> dataSimpanan = List.generate(6, (_) => 0);

        snapshot.data!.docs.forEach((doc) {
          final tanggal = DateTime.tryParse(doc['tanggal'] ?? '');
          if (tanggal != null) {
            final monthsAgo =
                now.month - tanggal.month + (now.year - tanggal.year) * 12;
            if (monthsAgo >= 0 && monthsAgo < 6) {
              dataPinjaman[5 - monthsAgo]++;
            }
          }
        });

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('simpanan').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData)
              return Center(child: CircularProgressIndicator());

            snap.data!.docs.forEach((doc) {
              final tanggal = DateTime.tryParse(doc['tanggal'] ?? '');
              if (tanggal != null) {
                final monthsAgo =
                    now.month - tanggal.month + (now.year - tanggal.year) * 12;
                if (monthsAgo >= 0 && monthsAgo < 6) {
                  dataSimpanan[5 - monthsAgo]++;
                }
              }
            });

            return BarChart(
              BarChartData(
                barGroups: List.generate(6, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dataPinjaman[index],
                        color: Colors.orange,
                      ),
                      BarChartRodData(
                        toY: dataSimpanan[index],
                        color: Colors.blue,
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final month = now.subtract(
                          Duration(days: (5 - value.toInt()) * 30),
                        );
                        return Text('${month.month}');
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
}
