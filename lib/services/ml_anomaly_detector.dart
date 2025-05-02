// lib/services/ml_anomaly_detector.dart
import 'dart:math';

class MLAnomalyDetector {
  // Contoh sederhana Isolation Forest
  static bool isAmountAnomaly(List<double> amounts, double newAmount) {
    if (amounts.isEmpty) return false;
    
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final stdDev = sqrt(amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length);
    
    // Jika jumlah baru > 3 standar deviasi dari mean
    return (newAmount - mean).abs() > 3 * stdDev;
  }

  // Contoh deteksi cluster abnormal
  static bool isFrequencyAnomaly(List<DateTime> dates, DateTime newDate) {
    if (dates.length < 5) return false;
    
    // Hitung jarak hari dari pengajuan terakhir
    final lastDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final daysSinceLast = newDate.difference(lastDate).inDays;
    
    // Jika pengajuan baru < 1 hari sejak terakhir dan sudah ada >5 pengajuan bulan ini
    return daysSinceLast < 1 && 
        dates.where((d) => d.month == newDate.month && d.year == newDate.year).length >= 5;
  }
}