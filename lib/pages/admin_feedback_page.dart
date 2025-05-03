import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Feedback Pengguna',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('feedback')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Text('Belum ada feedback'));
            }
            return ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                return Card(
                  color: theme.cardColor,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.email, color: theme.colorScheme.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['userEmail'] ?? '-',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (createdAt != null)
                              Text(
                                DateFormat(
                                  'dd MMM yyyy, HH:mm',
                                ).format(createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          data['feedback'] ?? '-',
                          style: TextStyle(fontSize: 15),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Sentimen: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              data['sentiment'] ?? '-',
                              style: TextStyle(
                                color:
                                    (data['sentiment'] == 'Positif')
                                        ? Colors.green
                                        : (data['sentiment'] == 'Negatif')
                                        ? Colors.red
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
