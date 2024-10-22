import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class OrgSignupPage extends StatefulWidget {
  const OrgSignupPage({super.key});

  @override
  _OrgSignupPageState createState() => _OrgSignupPageState();
}

class _OrgSignupPageState extends State<OrgSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _visionController = TextEditingController();
  final _missionController = TextEditingController();
  final _communityEngagementController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  File? _selectedLogo;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedLogo = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadLogo(User user) async {
    if (_selectedLogo == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('organization_logos/${user.uid}.png');
      UploadTask uploadTask = storageRef.putFile(_selectedLogo!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading logo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading logo. Please try again.')),
      );
      return null;
    }
  }

  Future<void> _orgSignUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await userCredential.user!.updateDisplayName(_nameController.text);

        String? logoUrl = await _uploadLogo(userCredential.user!);

        await FirebaseFirestore.instance
            .collection('organizations')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'name': _nameController.text,
          'vision': _visionController.text.trim(),
          'mission': _missionController.text.trim(),
          'communityEngagement': _communityEngagementController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'logoUrl': logoUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up successful! Please sign in.')),
        );

        Navigator.of(context).pushReplacementNamed('/signin');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Sign Up'),
        backgroundColor: Colors.lightGreen[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Organization Name',
                  icon: Icons.business,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Organization Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Organization Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _visionController,
                  label: 'Organization Vision',
                  icon: Icons.visibility,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _missionController,
                  label: 'Organization Mission',
                  icon: Icons.lightbulb_outline, // Changed icon here
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _communityEngagementController,
                  label: 'Community Engagement',
                  icon: Icons.people,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _addressController,
                  label: 'Organization Address',
                  icon: Icons.location_on,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickLogo,
                      icon: Icon(Icons.upload),
                      label: Text('Select Logo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[50],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedLogo != null
                            ? 'Logo selected'
                            : 'No logo selected',
                        style: TextStyle(
                          color:
                              _selectedLogo != null ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _orgSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Text('Sign Up as an Organization'),
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
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Colors.green), // Set the border color when enabled
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color:
                  Colors.lightGreen[600]!), // Set the border color when focused
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }
}
