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
    // Simulasi analisis sentimen
    await Future.delayed(Duration(seconds: 1));
    if (text.toLowerCase().contains('bagus') ||
        text.toLowerCase().contains('baik')) {
      return 'Positif';
    }
    if (text.toLowerCase().contains('jelek') ||
        text.toLowerCase().contains('buruk')) {
      return 'Negatif';
    }
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
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Feedback tidak boleh kosong!')));
      return;
    }
    setState(() {
      _isLoading = true;
      _sentiment = null;
    });
    try {
      final result = await _analyzeSentiment(text);
      await _saveFeedback(text, result);
      setState(() {
        _sentiment = result;
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Feedback berhasil dikirim!')));
      _controller.clear();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim feedback: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Tambahkan logika jika diperlukan, misalnya menampilkan dialog konfirmasi
        return true; // Mengizinkan navigasi kembali
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Feedback'),
          centerTitle: true,
          backgroundColor: Colors.green.shade800,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Berikan Feedback Anda',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Kami menghargai masukan Anda untuk meningkatkan layanan kami.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Masukkan Feedback',
                          hintText: 'Tulis masukan Anda di sini...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade800,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Kirim Feedback',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              if (_sentiment != null) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          _sentiment == 'Positif'
                              ? Icons.sentiment_satisfied
                              : _sentiment == 'Negatif'
                              ? Icons.sentiment_dissatisfied
                              : Icons.sentiment_neutral,
                          color:
                              _sentiment == 'Positif'
                                  ? Colors.green
                                  : _sentiment == 'Negatif'
                                  ? Colors.red
                                  : Colors.grey,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Sentimen Anda: $_sentiment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  _sentiment == 'Positif'
                                      ? Colors.green
                                      : _sentiment == 'Negatif'
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
