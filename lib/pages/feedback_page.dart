import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _controller = TextEditingController();
  String? _sentiment;
  bool _isLoading = false;

  Future<String> _analyzeSentiment(String text) async {
    // TODO: Ganti dengan request ke API sentimen
    await Future.delayed(Duration(seconds: 1));
    if (text.toLowerCase().contains('bagus') ||
        text.toLowerCase().contains('baik'))
      return 'Positif';
    if (text.toLowerCase().contains('jelek') ||
        text.toLowerCase().contains('buruk'))
      return 'Negatif';
    return 'Netral';
  }

  Future<void> _saveFeedback(String text, String sentiment) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': user?.uid ?? '-',
      'userEmail': user?.email ?? '-',
      'feedback': text,
      'sentiment': sentiment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _sentiment = null;
    });
    final result = await _analyzeSentiment(text);
    await _saveFeedback(text, result);
    setState(() {
      _sentiment = result;
      _isLoading = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Feedback berhasil dikirim!')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback & Sentimen'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        titleTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tulis feedback Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan feedback...',
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: Text('Kirim & Analisis Sentimen'),
            ),
            if (_isLoading) ...[
              SizedBox(height: 16),
              Center(child: CircularProgressIndicator()),
            ],
            if (_sentiment != null) ...[
              SizedBox(height: 16),
              Text(
                'Hasil Analisis Sentimen:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  _sentiment!,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        _sentiment == 'Positif'
                            ? Colors.green
                            : _sentiment == 'Negatif'
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
