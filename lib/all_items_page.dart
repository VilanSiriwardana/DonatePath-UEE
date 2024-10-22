import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_layout.dart';

class AllItemsPage extends StatefulWidget {
  const AllItemsPage({super.key});

  @override
  _AllItemsPageState createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      headerText: "All Items",
      profileImage: "",
      selectedIndex: 3,
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryIcon('All', Icons.all_inclusive, "all.png"),
                    _buildCategoryIcon(
                        'Stationary', Icons.note, "stationery.png"),
                    _buildCategoryIcon(
                        'Shoes', Icons.directions_run, "shoes.png"),
                    _buildCategoryIcon(
                        'Electronics', Icons.devices, "electronics.png"),
                    _buildCategoryIcon('Bags', Icons.backpack, "bags.png"),
                    _buildCategoryIcon('Food', Icons.fastfood, "food.png"),
                    _buildCategoryIcon(
                        'Furniture', Icons.chair, "furniture.png"),
                    _buildCategoryIcon(
                        'Clothes', Icons.checkroom, "cloths.png"),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collectionGroup('items')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print("error :${snapshot.error}");
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No items found'));
                    }

                    List<QueryDocumentSnapshot> allItems = snapshot.data!.docs;

                    if (_selectedCategory != 'All') {
                      allItems = allItems
                          .where((doc) => doc['category'] == _selectedCategory)
                          .toList();
                    }

                    return GridView.builder(
                      padding: EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        final item =
                            allItems[index].data() as Map<String, dynamic>;
                        return Card(
                          elevation: 3,
                          color: Colors.lightGreen[100],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(4.0)),
                                  child: Image.network(
                                    item['item_images'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(child: Icon(Icons.error));
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Name: ${item['item_name']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item['location'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                        );
                      },
                    );
                  },
                ),
              ),
            ],
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
