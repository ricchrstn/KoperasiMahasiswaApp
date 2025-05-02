import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnomalyDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendeteksi anomali dalam pengajuan pinjaman
 Future<Map<String, dynamic>> detectLoanAnomalies(String userId) async {
  try {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
    
    // PERBAIKAN: Gunakan index yang sudah dibuat
    final userLoans = await _firestore
        .collection('pinjaman')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: sixMonthsAgo)
        .orderBy('createdAt', descending: true) // Tambahkan ini
        .get();

      if (userLoans.docs.isEmpty) {
        return {'isAnomaly': false, 'confidence': 0.0, 'reasons': []};
      }

      // Hitung statistik dasar
      final loanAmounts = userLoans.docs
          .map((doc) => (doc.data()['jumlah'] as num).toDouble())
          .toList();
      
      final avgAmount = loanAmounts.reduce((a, b) => a + b) / loanAmounts.length;
      final maxAmount = loanAmounts.reduce((a, b) => a > b ? a : b);
      final minAmount = loanAmounts.reduce((a, b) => a < b ? a : b);
      
      // Deteksi anomali sederhana (bisa diganti dengan model ML yang lebih canggih)
      List<String> anomalyReasons = [];
      double confidence = 0.0;

      // Rule 1: Jumlah pinjaman > 3x rata-rata
      if (maxAmount > 3 * avgAmount) {
        anomalyReasons.add('Jumlah pinjaman melebihi 3x rata-rata');
        confidence += 0.6;
      }

      // Rule 2: Frekuensi pengajuan > 5x dalam sebulan
      final loansThisMonth = userLoans.docs.where((doc) {
        final loanDate = (doc.data()['createdAt'] as Timestamp).toDate();
        return loanDate.month == now.month && loanDate.year == now.year;
      }).length;
      
      if (loansThisMonth > 5) {
        anomalyReasons.add('Frekuensi pengajuan tinggi (${loansThisMonth}x bulan ini)');
        confidence += 0.4;
      }

      // Rule 3: Perubahan pola waktu pengajuan
      // (Implementasi lebih kompleks bisa ditambahkan)

      return {
        'isAnomaly': anomalyReasons.isNotEmpty,
        'confidence': confidence.clamp(0.0, 1.0),
        'reasons': anomalyReasons,
        'stats': {
          'average_amount': avgAmount,
          'max_amount': maxAmount,
          'min_amount': minAmount,
          'total_loans': userLoans.docs.length,
          'loans_this_month': loansThisMonth,
        }
      };
    } catch (e) {
      throw Exception('Failed to detect anomalies: $e');
    }
  }

  // Untuk admin: deteksi anomali semua pengajuan baru
  Future<List<Map<String, dynamic>>> checkNewLoansForAnomalies() async {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    
    final newLoans = await _firestore
        .collection('pinjaman')
        .where('createdAt', isGreaterThanOrEqualTo: oneWeekAgo)
        .get();

    final results = <Map<String, dynamic>>[];
    
    for (var loan in newLoans.docs) {
      final data = loan.data();
      final userId = data['userId'];
      
      final anomalyResult = await detectLoanAnomalies(userId);
      if (anomalyResult['isAnomaly']) {
        results.add({
          'loan_id': loan.id,
          'user_id': userId,
          'user_email': data['userEmail'],
          'amount': data['jumlah'],
          'date': DateFormat('yyyy-MM-dd').format(
              (data['createdAt'] as Timestamp).toDate()),
          'anomaly_details': anomalyResult,
        });
      }
    }
    
    return results;
  }

  Future<void> _logAnomaly(String userId, Map<String, dynamic> details) async {
    await _firestore.collection('anomaly_logs').add({
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'details': details,
      'handled': false,
    });
  }
}