import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ProfilPage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  ProfilPage({this.onBackToHome, Key? key}) : super(key: key);
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data profil: ${e.toString()}')),
      );
    }
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

        setState(() {});
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

  void _showEditProfileDialog(BuildContext context, User user) {
    final nameController = TextEditingController(text: user.displayName);
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false; // To prevent multiple updates

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  onPressed:
                      isUpdating
                          ? null
                          : () async {
                            if (formKey.currentState!.validate()) {
                              setState(() => isUpdating = true);
                              try {
                                await user.updateDisplayName(
                                  nameController.text,
                                );
                                await _firestore
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'name': nameController.text});
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Profil berhasil diperbarui'),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal memperbarui profil: $e',
                                    ),
                                  ),
                                );
                              } finally {
                                setState(() => isUpdating = false);
                              }
                            }
                          },
                  child:
                      isUpdating
                          ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                          : Text('Simpan'),
                ),
              ],
            );
          },
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async {
        // Tambahkan logika jika diperlukan, misalnya menampilkan dialog konfirmasi
        return true; // Mengizinkan navigasi kembali
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Profil Kamu',
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
            if (user != null)
              IconButton(
                icon: Icon(Icons.edit, color: Colors.green.shade800),
                onPressed: () => _showEditProfileDialog(context, user),
              ),
          ],
        ),
        body:
            user == null
                ? Center(child: Text('Tidak ada data pengguna yang tersedia.'))
                : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future:
                                  _firestore
                                      .collection('users')
                                      .doc(user.uid)
                                      .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircleAvatar(
                                    radius: 50,
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final data =
                                    snapshot.data?.data()
                                        as Map<String, dynamic>?;
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
                                    backgroundImage: NetworkImage(
                                      user.photoURL!,
                                    ),
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
                                onTap:
                                    _isUploading ? null : _uploadProfilePicture,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        _isUploading
                                            ? Colors.grey
                                            : Colors.blue,
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email ?? 'Surel tidak tersedia',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
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
                                leading: Icon(
                                  Icons.verified_user,
                                  color: Colors.green,
                                ),
                                title: Text('Verifikasi Surel'),
                                subtitle: Text(
                                  user.emailVerified
                                      ? 'Terverifikasi'
                                      : 'Belum terverifikasi',
                                ),
                                trailing:
                                    !user.emailVerified
                                        ? TextButton(
                                          onPressed:
                                              () => _verifyEmail(context, user),
                                          child: Text('Verifikasi'),
                                        )
                                        : null,
                              ),
                              Divider(),
                              ListTile(
                                leading: Icon(
                                  Icons.date_range,
                                  color: Colors.purple,
                                ),
                                title: Text('Bergabung sejak'),
                                subtitle: Text(
                                  user.metadata.creationTime
                                          ?.toLocal()
                                          .toString() ??
                                      '-',
                                ),
                              ),
                              Divider(),
                              ListTile(
                                leading: Icon(
                                  Icons.credit_card,
                                  color: Colors.orange,
                                ),
                                title: Text('KTM'),
                                subtitle: FutureBuilder<DocumentSnapshot>(
                                  future:
                                      _firestore
                                          .collection('users')
                                          .doc(user.uid)
                                          .get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData ||
                                        !snapshot.data!.exists) {
                                      return Text('Belum diunggah');
                                    }
                                    final data =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>;
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
                                leading: Icon(
                                  Icons.security,
                                  color: Colors.orange,
                                ),
                                title: Text('Keamanan'),
                                subtitle: Text('Perbarui password'),
                                trailing: Icon(Icons.chevron_right),
                                onTap: () => _showUpdatePasswordDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
