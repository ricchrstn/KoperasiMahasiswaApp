import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionManageScreen extends StatelessWidget {
  TransactionManageScreen({super.key});

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Transaksi'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Pinjaman'), Tab(text: 'Simpanan')],
          ),
        ),
        body: const TabBarView(children: [_PinjamanTab(), _SimpananTab()]),
      ),
    );
  }
}

class _PinjamanTab extends StatelessWidget {
  const _PinjamanTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('pinjaman')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final pinjamanList = snapshot.data!.docs;

        if (pinjamanList.isEmpty) {
          return const Center(child: Text('Belum ada data pinjaman.'));
        }

        return ListView.builder(
          itemCount: pinjamanList.length,
          itemBuilder: (context, index) {
            final data = pinjamanList[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(Icons.account_balance, color: Colors.orange),
                title: Text(
                  'Jumlah: Rp${data['jumlah'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${data['status'] ?? '-'}'),
                    Text('Tanggal: ${data['tanggal'] ?? '-'}'),
                    if (data['tujuan'] != null)
                      Text('Tujuan: ${data['tujuan']}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SimpananTab extends StatelessWidget {
  const _SimpananTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('simpanan')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final simpananList = snapshot.data!.docs;

        if (simpananList.isEmpty) {
          return const Center(child: Text('Belum ada data simpanan.'));
        }

        return ListView.builder(
          itemCount: simpananList.length,
          itemBuilder: (context, index) {
            final data = simpananList[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(Icons.savings, color: Colors.green),
                title: Text(
                  'Jumlah: Rp${data['jumlah'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Tanggal: ${data['tanggal'] ?? '-'}'),
              ),
            );
          },
        );
      },
    );
  }
}
