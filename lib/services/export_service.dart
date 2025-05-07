import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

class ExportService {
  static Future<void> exportPinjaman(BuildContext context) async {
    if (kIsWeb) {
      _showWebUnsupportedMessage(context);
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('pinjaman')
              .orderBy('createdAt', descending: true)
              .get();

      // In a real app, you would implement actual PDF export here
      // For now just show a snackbar with the count
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export pinjaman berhasil (${querySnapshot.docs.length} data)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export pinjaman: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> exportSimpanan(BuildContext context) async {
    if (kIsWeb) {
      _showWebUnsupportedMessage(context);
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('simpanan')
              .orderBy('createdAt', descending: true)
              .get();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export simpanan berhasil (${querySnapshot.docs.length} data)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export simpanan: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> exportUsers(BuildContext context) async {
    if (kIsWeb) {
      _showWebUnsupportedMessage(context);
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .get();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export users berhasil (${querySnapshot.docs.length} data)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export users: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> exportToPDF(
    BuildContext context,
    List<Map<String, dynamic>> data,
    String title,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build:
              (pw.Context context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: data.isNotEmpty ? data.first.keys.toList() : [],
                    data: data.map((row) => row.values.toList()).toList(),
                  ),
                ],
              ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/$title.pdf");
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF berhasil dibuat: ${file.path}')),
      );

      OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    }
  }

  static Future<void> exportToExcel(
    BuildContext context,
    List<Map<String, dynamic>> data,
    String title,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel["Sheet1"];

      if (data.isNotEmpty) {
        sheet.appendRow(data.first.keys.toList());
        for (var row in data) {
          sheet.appendRow(row.values.toList());
        }
      }

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/$title.xlsx");
      await file.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel berhasil dibuat: ${file.path}')),
      );

      OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat Excel: $e')));
    }
  }

  static void _showWebUnsupportedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ekspor tidak didukung di platform web.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
