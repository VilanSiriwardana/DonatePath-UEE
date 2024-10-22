import 'package:donate_path/org_items_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class DonationRequestForm extends StatefulWidget {
  final int selectedIndex;

  const DonationRequestForm({super.key, this.selectedIndex = 1});

  @override
  _DonationRequestFormState createState() => _DonationRequestFormState();
}

class _DonationRequestFormState extends State<DonationRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  final List<String> _categories = [
    'Food',
    'Clothes',
    'Furniture',
    'Electronics',
    'Shoes',
    'Bags',
    'Stationery',
    'Other'
  ];
  int _quantity = 1;
  String? _selectedCategory;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user logged in. Please log in first.')),
        );
        return;
      }

      String itemName = _itemNameController.text;
      String category = _selectedCategory!;
      String description = _descriptionController.text;
      String imageUrl = await _uploadImage();

      if (imageUrl.isEmpty) return;

      Map<String, dynamic> requestData = {
        'userId': user.uid,
        'itemName': itemName,
        'category': category,
        'description': description,
        'quantity': _quantity,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('requests').add(requestData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation request submitted successfully!')),
      );

      _clearForm();
    }
  }

  Future<String> _uploadImage() async {
    if (_imageFile == null) return '';

    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref =
          FirebaseStorage.instance.ref().child('donation_images/$fileName');
      UploadTask uploadTask = ref.putFile(File(_imageFile!.path));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image. Please try again.')),
      );
      return '';
    }
  }

  void _clearForm() {
    _itemNameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _quantity = 1;
      _imageFile = null;
    });
  }

  Future<void> _pickImage() async {
    try {
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image. Please try again.')),
      );
    }
  }

  void _onItemTapped(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrgItemsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Donations'),
        backgroundColor: const Color.fromARGB(255, 216, 241, 218),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                _buildTextField('Item Name', _itemNameController),
                _buildDropdown(),
                _buildTextField('Item Description', _descriptionController,
                    maxLines: 3),
                SizedBox(height: 20),
                _buildQuantitySelector(),
                SizedBox(height: 20),
                _buildImagePicker(),
                if (_imageFile != null) _buildImagePreview(),
                SizedBox(height: 20),
                _buildButtonRow(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: AssetImage('assets/images/request_items_banner.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.green[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Select Category',
          filled: true,
          fillColor: Colors.green[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
        ),
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a category';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Quantity: $_quantity',
          style: TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: Colors.green),
              onPressed: () {
                setState(() {
                  if (_quantity > 1) _quantity--;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.add, color: Colors.green),
              onPressed: () {
                setState(() {
                  _quantity++;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return ElevatedButton.icon(
      onPressed: _pickImage,
      icon: Icon(Icons.image, color: Colors.white),
      label: Text('Pick Image'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[100],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          File(_imageFile!.path),
          height: 100,
          width: 100,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Reduced button radius
              ),
            ),
            child: Text(
              'Request More',
              style: TextStyle(color: Colors.white), // Set text color to white
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Reduced button radius
              ),
            ),
            child: Text(
              'Submit Request',
              style: TextStyle(color: Colors.white), // Set text color to white
            ),
          ),
        ),
      ],
    );
  }
}
