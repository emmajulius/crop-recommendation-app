import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/firestore_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/translator.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  late final AuthProvider _authProvider;
  late final FirestoreService _firestoreService;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  File? _newImage;
  String? _profileImageUrl;

  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider = Provider.of<AuthProvider>(context);
    _firestoreService = FirestoreService();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = _authProvider.currentUser;
      if (user == null) {
        _showError(translate(context, 'no_user_logged_in'));
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final data = await _firestoreService.getUserData();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
      }

      _usernameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _profileImageUrl = user.photoURL;
    } catch (e) {
      _showError("${translate(context, 'load_profile_error')}: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final ref = FirebaseStorage.instance
          .ref('profile_pictures/${_authProvider.currentUser!.uid}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      _showError('${translate(context, 'upload_image_error')}: $e');
      return null;
    }
  }

  void _updateProfile() async {
    try {
      String? uploadedImageUrl = _profileImageUrl;

      if (_newImage != null) {
        uploadedImageUrl = await _uploadImage(_newImage!);
      }

      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      await _firestoreService.updateUserData(data);

      await _authProvider.updateProfile(
        displayName: _usernameController.text.trim(),
        photoUrl: uploadedImageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context, 'profile_updated'))),
      );

      if (mounted) setState(() => _profileImageUrl = uploadedImageUrl);
    } catch (e) {
      _showError("${translate(context, 'update_profile_error')}: $e");
    }
  }

  void _deleteAccount() async {
    try {
      await _firestoreService.deleteUserData();
      await _authProvider.deleteAccount();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      _showError("${translate(context, 'delete_account_error')}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate(context, 'manage_account')),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage:
                                _newImage != null ? FileImage(_newImage!) : null,
                            child: _newImage == null && _profileImageUrl == null
                                ? Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        translate(context, 'edit_account'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(
                        controller: _usernameController,
                        label: translate(context, 'username'),
                        icon: Icons.account_circle_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: translate(context, 'full_name'),
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: translate(context, 'email'),
                        icon: Icons.email_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: translate(context, 'phone'),
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 30),
                      _buildButton(
                        label: translate(context, 'update_profile'),
                        icon: Icons.save,
                        onPressed: _updateProfile,
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        label: translate(context, 'delete_account'),
                        icon: Icons.delete,
                        onPressed: _deleteAccount,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.green,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
