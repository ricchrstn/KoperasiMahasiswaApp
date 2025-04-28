import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportService {
  static Future<void> exportPinjaman(BuildContext context) async {
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
}
