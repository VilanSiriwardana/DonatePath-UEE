import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donate_path/main_layout.dart';

class MyItemsPage extends StatelessWidget {
  const MyItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 3,
      headerText: 'My Items',
      profileImage: '',
      child: MyItemsContent(),
    );
  }
}

class MyItemsContent extends StatefulWidget {
  const MyItemsContent({super.key});

  @override
  _MyItemsContentState createState() => _MyItemsContentState();
}

class _MyItemsContentState extends State<MyItemsContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedCategory = 'All';

  void _showItemDetails(
      BuildContext context, Map<String, dynamic> item, String documentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(item['item_images']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                item['item_name'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Category: ${item['category']}'),
              Text('Location: ${item['location']}'),
              Text('Donator Name: ${item['donator_name']}'),
              Text('Contact Number: ${item['contact_number']}'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                    onPressed: () {
                      Navigator.pop(context);
                      _editItem(context, item, documentId);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Delete'),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteItem(documentId);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _editItem(
      BuildContext context, Map<String, dynamic> item, String documentId) {
    TextEditingController nameController =
        TextEditingController(text: item['item_name']);
    TextEditingController locationController =
        TextEditingController(text: item['location']);
    TextEditingController donatorNameController =
        TextEditingController(text: item['donator_name']);
    TextEditingController contactNumberController =
        TextEditingController(text: item['contact_number']);
    String category = item['category'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: donatorNameController,
                  decoration: InputDecoration(labelText: 'Donator Name'),
                ),
                TextField(
                  controller: contactNumberController,
                  decoration: InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  items: [
                    'Stationary',
                    'Shoes',
                    'Electronics',
                    'Bags',
                    'Food',
                    'Furniture',
                    'Clothes'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      category = newValue;
                    }
                  },
                  decoration: InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _updateItem(documentId, {
                  'item_name': nameController.text,
                  'location': locationController.text,
                  'category': category,
                  'donator_name': donatorNameController.text,
                  'contact_number': contactNumberController.text,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateItem(String documentId, Map<String, dynamic> newData) {
    final User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('donations')
          .doc(user.uid)
          .collection('items')
          .doc(documentId)
          .update(newData);
    }
  }

  void _deleteItem(String documentId) {
    final User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('donations')
          .doc(user.uid)
          .collection('items')
          .doc(documentId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text("User not signed in"),
                )
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('donations')
                .doc(user.uid)
                .collection('items')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No items found'));
              }

              List<QueryDocumentSnapshot> donationList = snapshot.data!.docs;

              if (_selectedCategory != 'All') {
                donationList = donationList
                    .where((doc) => doc['category'] == _selectedCategory)
                    .toList();
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: buildPictureButton(
                        context,
                        '',
                        'assets/images/my_donations_two.jpeg',
                        () {
                          // Navigate to Donate Items page or action
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryIcon(
                              'All', Icons.all_inclusive, "all.png"),
                          _buildCategoryIcon(
                              'Stationary', Icons.note, "stationery.png"),
                          _buildCategoryIcon(
                              'Shoes', Icons.directions_run, "shoes.png"),
                          _buildCategoryIcon(
                              'Electronics', Icons.devices, "electronics.png"),
                          _buildCategoryIcon(
                              'Bags', Icons.backpack, "bags.png"),
                          _buildCategoryIcon(
                              'Food', Icons.fastfood, "food.png"),
                          _buildCategoryIcon(
                              'Furniture', Icons.chair, "furniture.png"),
                          _buildCategoryIcon(
                              'Clothes', Icons.checkroom, "cloths.png"),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: donationList.length,
                      itemBuilder: (context, index) {
                        final item =
                            donationList[index].data() as Map<String, dynamic>;
                        final documentId = donationList[index].id;
                        return GestureDetector(
                          onTap: () =>
                              _showItemDetails(context, item, documentId),
                          child: Card(
                            elevation: 3,
                            color: Colors.lightGreen[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10)),
                                  child: Image.network(
                                    item['item_images'],
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['item_name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        item['location'],
                                        style: TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        item['category'],
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget buildPictureButton(BuildContext context, String label,
      String imagePath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.lightGreen[100],
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category, IconData icon, String imageName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _selectedCategory == category
                  ? Colors.lightGreen[200]
                  : Colors.grey[300],
              backgroundImage:
                  AssetImage('assets/images/$imageName'), // Add this line
              child: _selectedCategory == category
                  ? null
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
            SizedBox(height: 5),
            Text(category),
          ],
        ),
      ),
    );
  }
}
