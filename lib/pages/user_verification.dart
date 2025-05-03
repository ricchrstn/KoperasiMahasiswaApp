import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class UserVerificationScreen extends StatelessWidget {
  const UserVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verifikasi User',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getUnverifiedUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text('Tidak ada user yang perlu diverifikasi'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.email),
                subtitle: Text(user.name ?? 'No name'),
                trailing: IconButton(
                  icon: const Icon(Icons.verified, color: Colors.green),
                  onPressed: () => firestoreService.verifyUser(user.uid),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
