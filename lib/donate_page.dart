import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'main_layout.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  _DonatePageState createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _donatorNameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _categoryValue;
  XFile? _pickedImage;

  final List<String> _categories = [
    'Stationary',
    'Shoes',
    'Electronics',
    'Bags',
    'Food',
    'Furniture',
    'Clothes'
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _pickedImage = image;
    });
  }

  Future<void> _addDonation() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User not logged in!')));
      return;
    }

    if (_pickedImage != null && _categoryValue != null) {
      try {
        // Step 1: Upload image to Firebase Storage
        final Reference storageRef = _storage.ref().child(
            'donations/${DateTime.now().millisecondsSinceEpoch}_${_pickedImage!.name}');
        final UploadTask uploadTask =
            storageRef.putFile(File(_pickedImage!.path));
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Step 2: Store item data in Firestore
        await _firestore
            .collection('donations')
            .doc(user.uid)
            .collection('items')
            .add({
          'item_name': _itemNameController.text,
          'location': _locationController.text,
          'category': _categoryValue,
          'donator_name': _donatorNameController.text,
          'contact_number': _contactNumberController.text,
          'item_images': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Donation added successfully!')));
        _resetFields();
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add donation!')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image and category!')));
    }
  }

  void _resetFields() {
    setState(() {
      _itemNameController.clear();
      _locationController.clear();
      _donatorNameController.clear();
      _contactNumberController.clear();
      _categoryValue = null;
      _pickedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      headerText: 'Add Donation',
      profileImage: '',
      selectedIndex: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15),
              _buildTextField(_itemNameController, 'Item Name'),
              _buildTextField(_locationController, 'Location'),
              _buildTextField(_donatorNameController, 'Donator Name'),
              _buildTextField(_contactNumberController, 'Contact Number',
                  keyboardType: TextInputType.phone),
              SizedBox(height: 16),
              _buildDropdown(),
              SizedBox(height: 24),
              _buildImagePicker(),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addDonation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Add Donation'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetFields,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white60,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _categoryValue,
      items: _categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _categoryValue = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Image',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _pickedImage == null
                ? Center(
                    child: Icon(Icons.add_a_photo,
                        size: 50, color: Colors.grey[600]),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
