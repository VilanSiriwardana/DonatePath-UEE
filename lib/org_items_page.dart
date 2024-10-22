import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'org_request_form.dart'; // Import your org_request_form.dart

class OrgItemsPage extends StatefulWidget {
  const OrgItemsPage({super.key});

  @override
  _MyItemsPageState createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<OrgItemsPage> {
  bool _isDropdownVisible = false;
  String? _selectedCategory;
  User? user;
  Future<Map<String, dynamic>?>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _userDataFuture = fetchUserData();
  }

  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(user!.uid)
            .get();

        if (snapshot.exists) {
          return snapshot.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data.')),
      );
    }
    return null;
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      _toggleDropdown(); // Close the dropdown after logout
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out. Please try again.')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDonationRequests() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs
        .map((doc) => {
              ...doc.data(),
              'docId': doc.id, // Include the document ID for deletion
            })
        .toList();
  }

  Future<void> _deleteRequest(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(docId)
          .delete();
      setState(() {}); // Refresh the UI after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete request. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        return Scaffold(
          body: Column(
            children: [
              SizedBox(height: 40), // Add space above the custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu),
                          onPressed: () {
                            // Handle menu action here
                          },
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Request Donations',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications),
                          onPressed: () {
                            // Handle notifications action here
                          },
                        ),
                        GestureDetector(
                          onTap: _toggleDropdown,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: snapshot.hasData &&
                                    snapshot.data?['logoUrl'] != null
                                ? NetworkImage(snapshot.data!['logoUrl'])
                                : AssetImage('assets/images/default_avatar.png')
                                    as ImageProvider,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24), // Add space above the categories
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              buildCategoryImage(
                                  'assets/images/stationery.png', 'Stationery'),
                              buildCategoryImage(
                                  'assets/images/shoes.png', 'Shoes'),
                              buildCategoryImage(
                                  'assets/images/electronics.png',
                                  'Electronics'),
                              buildCategoryImage(
                                  'assets/images/bags.png', 'Bags'),
                              buildCategoryImage(
                                  'assets/images/food.png', 'Food'),
                              buildCategoryImage(
                                  'assets/images/furniture.png', 'Furniture'),
                              buildCategoryImage(
                                  'assets/images/cloths.png', 'Clothes'),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchDonationRequests(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                  child: Text('No donation requests found.'));
                            }

                            final donationRequests = snapshot.data!;
                            final filteredRequests = _selectedCategory != null
                                ? donationRequests
                                    .where((request) =>
                                        request['category'] ==
                                        _selectedCategory)
                                    .toList()
                                : donationRequests;

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: filteredRequests.length,
                              itemBuilder: (context, index) {
                                final request = filteredRequests[index];
                                final title =
                                    request['itemName'] ?? 'Unknown Item';
                                final imageUrl = request['imageUrl'] ??
                                    'https://via.placeholder.com/150';
                                final category = request['category'] ?? 'Other';
                                final description =
                                    request['description'] ?? 'No Description';
                                final quantity = request['quantity'] ?? 0;
                                final docId = request['docId'];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 15.0),
                                  child: buildItemCard(title, imageUrl,
                                      category, description, quantity, docId),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        DonationRequestForm()), // Navigate to OrgRequestForm
              );
            },
            backgroundColor: Color(0xFFD7F6AB),
            tooltip: 'Request Donation',
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget buildCategoryImage(String imagePath, String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  isSelected ? Colors.green : Colors.lightGreen[200],
              backgroundImage: AssetImage(imagePath),
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItemCard(String title, String imageUrl, String category,
      String description, int quantity, String docId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quantity: $quantity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _deleteRequest(docId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
