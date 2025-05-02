// test/anomaly_detection_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kopma/services/ml_anomaly_detector.dart'; // Tambahkan import ini

void main() {
  group('Anomaly Detection Tests', () {
    test('Detect amount anomaly', () {
      final amounts = [1000000.0, 1200000.0, 1500000.0, 1100000.0];
      // Jumlah normal
      expect(MLAnomalyDetector.isAmountAnomaly(amounts, 1300000.0), false);
      // Jumlah anomali (terlalu besar)
      expect(MLAnomalyDetector.isAmountAnomaly(amounts, 5000000.0), true);
    });

    test('Detect frequency anomaly', () {
      final dates = [
        DateTime(2023, 1, 1),
        DateTime(2023, 1, 2),
        DateTime(2023, 1, 3),
        DateTime(2023, 1, 4),
        DateTime(2023, 1, 5),
      ];
      // Tanggal normal
      expect(MLAnomalyDetector.isFrequencyAnomaly(dates, DateTime(2023, 1, 10)), false);
      // Tanggal anomali (terlalu sering)
      expect(MLAnomalyDetector.isFrequencyAnomaly(dates, DateTime(2023, 1, 6)), true);
    });
  });
}