import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kopma/pages/dashboard_page.dart';

class ProfilPage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  ProfilPage({this.onBackToHome, Key? key}) : super(key: key);
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _KTMImage;
  double _shu = 0;
  String? _userRole;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _shu = (doc.data()?['shu'] ?? 0).toDouble();
            _userRole = doc.data()?['role'] ?? 'mahasiswa';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data profil: ${e.toString()}')),
      );
    }
  }

  Future<void> _addShuHistory(double amount, String description) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final newHistoryKey = DateTime.now().millisecondsSinceEpoch.toString();

        await docRef.update({
          'shu': FieldValue.increment(amount),
          'shu_history.$newHistoryKey': {
            'amount': amount,
            'date': DateTime.now().toIso8601String(),
            'description': description,
          },
        });

        setState(() {
          _shu += amount;
        });
      }
    } catch (e) {
      debugPrint('Error adding SHU history: $e');
    }
  }

  void _showShuHistory(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Riwayat SHU'),
          content: FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Text('Tidak ada data SHU');
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final shuHistory =
                  data['shu_history'] as Map<String, dynamic>? ?? {};

              if (shuHistory.isEmpty) {
                return Text('Belum ada riwayat SHU');
              }

              final sortedKeys =
                  shuHistory.keys.toList()..sort((a, b) => b.compareTo(a));

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: shuHistory.length,
                  itemBuilder: (context, index) {
                    final key = sortedKeys[index];
                    final entry = shuHistory[key] as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(entry['amount']),
                      ),
                      subtitle: Text(entry['description'] ?? ''),
                      trailing: Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(entry['date'])),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadProfilePicture() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'photoProfileBase64': base64Image,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto profil berhasil diupload')),
        );

        setState(() {});
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload foto profil: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadKTM() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membaca file')));
        return;
      }

      final base64Image = base64Encode(fileBytes);

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'ktmBase64': base64Image,
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Foto KTM berhasil diupload')));

        setState(() {
          _KTMImage = null;
        });
      }
    } catch (e) {
      debugPrint('Error details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload KTM: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _showEditProfileDialog(BuildContext context, User user) {
    final nameController = TextEditingController(text: user.displayName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profil'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nama Lengkap'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama harus diisi';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await user.updateDisplayName(nameController.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profil berhasil diperbarui')),
                    );
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui profil: $e')),
                    );
                  }
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _verifyEmail(BuildContext context, User user) async {
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email verifikasi telah dikirim')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim email verifikasi: $e')),
      );
    }
  }

  void _showSecurityOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Opsi Keamanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.lock_reset),
                title: Text('Perbarui Password'),
                onTap: () {
                  Navigator.pop(context);
                  _showUpdatePasswordDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdatePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Perbarui Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password Baru'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password harus diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: confirmController,
                  decoration: InputDecoration(labelText: 'Konfirmasi Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _auth.currentUser?.updatePassword(
                      passwordController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password berhasil diperbarui')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui password: $e')),
                    );
                  }
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text('Login'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profil Anggota',
          style: TextStyle(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.green.shade800),
        leading:
            widget.onBackToHome != null
                ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: widget.onBackToHome,
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.green.shade800),
            onPressed: () => _showEditProfileDialog(context, user!),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(user.uid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(
                          radius: 50,
                          child: CircularProgressIndicator(),
                        );
                      }

                      final data =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      final photoBase64 = data?['photoProfileBase64'];

                      if (photoBase64 != null) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundImage: MemoryImage(
                            base64Decode(photoBase64),
                          ),
                        );
                      } else if (user.photoURL != null) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(user.photoURL!),
                        );
                      } else {
                        return CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        );
                      }
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _uploadProfilePicture,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isUploading ? Colors.grey : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              user.displayName ?? 'Nama belum diatur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              user.email ?? 'Surel tidak tersedia',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.blue),
                      title: Text('Surel'),
                      subtitle: Text(user.email ?? '-'),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.verified_user, color: Colors.green),
                      title: Text('Verifikasi Surel'),
                      subtitle: Text(
                        user.emailVerified
                            ? 'Terverifikasi'
                            : 'Belum terverifikasi',
                      ),
                      trailing:
                          !user.emailVerified
                              ? TextButton(
                                onPressed: () => _verifyEmail(context, user),
                                child: Text('Verifikasi'),
                              )
                              : null,
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.attach_money, color: Colors.green),
                      title: Text('Sisa Hasil Usaha Tahun Ini'),
                      subtitle: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(_shu),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.history),
                        onPressed: () => _showShuHistory(context),
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.date_range, color: Colors.purple),
                      title: Text('Bergabung sejak'),
                      subtitle: Text(
                        user.metadata.creationTime?.toLocal().toString() ?? '-',
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.credit_card, color: Colors.orange),
                      title: Text('KTM'),
                      subtitle: FutureBuilder<DocumentSnapshot>(
                        future:
                            _firestore.collection('users').doc(user.uid).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Text('Belum diunggah');
                          }
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final base64Image = data['ktmBase64'];

                          if (base64Image == null) {
                            return Text('Belum diunggah');
                          }

                          final bytes = base64Decode(base64Image);
                          return Image.memory(bytes, height: 100);
                        },
                      ),
                      trailing:
                          _isUploading
                              ? CircularProgressIndicator()
                              : IconButton(
                                icon: Icon(Icons.upload),
                                onPressed: _uploadKTM,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.security, color: Colors.orange),
                      title: Text('Keamanan'),
                      subtitle: Text('Perbarui password'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => _showSecurityOptions(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
