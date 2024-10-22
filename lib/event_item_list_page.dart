import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';

class EventItemListPage extends StatefulWidget {
  final Map<String, dynamic> eventDetails;

  const EventItemListPage({super.key, required this.eventDetails});

  @override
  _EventItemListPageState createState() => _EventItemListPageState();
}

class _EventItemListPageState extends State<EventItemListPage> {
  List<Map<String, dynamic>> _items = [];
  List<String> _categories = [
    'bags',
    'cloths',
    'electronics',
    'food',
    'furniture',
    'shoes',
    'stationery'
  ];
  List<TextEditingController> _itemNameControllers = [];
  List<ValueNotifier<int>> _quantityNotifiers = [];

  @override
  void initState() {
    super.initState();
    _addItem(); // Add initial item section
  }

  void _addItem() {
    setState(() {
      _items.add({
        'name': '',
        'category': null,
        'quantity': 1,
      });
      _itemNameControllers.add(TextEditingController());
      _quantityNotifiers.add(ValueNotifier<int>(1));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _itemNameControllers[index].dispose();
      _quantityNotifiers[index].dispose();
      _itemNameControllers.removeAt(index);
      _quantityNotifiers.removeAt(index);
    });
  }

  void _updateItem(int index, String key, dynamic value) {
    _items[index][key] = value;
  }

  int _calculateTotalQuantity() {
    return _items.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  Future<void> _submitEvent() async {
    try {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item.')),
        );
        return;
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in. Please sign in.')),
        );
        return;
      }

      // Calculate total quantity of all items
      final int totalQuantity = _calculateTotalQuantity();

      // Save event details to Firestore
      await FirebaseFirestore.instance.collection('events').add({
        ...widget.eventDetails,
        'items': _items,
        'itemsCount': totalQuantity,
        'donatedCount': 0,
        'status': 'pending',
        'eventOrganizerId': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event submitted for approval!')),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/eventsList',
        (route) => false,
      );
    } catch (e) {
      print("Error saving event: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error submitting event. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      headerText: 'Create Event',
      profileImage: '',
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _bannerSection(),
              const SizedBox(height: 20),
              _itemList(),
              const SizedBox(height: 20),
              _addButton(),
              const SizedBox(height: 20),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerSection() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/items1.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          color: Colors.green.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: const Text(
            'Items List',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return _buildItemSection(index);
      },
    );
  }

  Widget _buildItemSection(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _itemNameControllers[index],
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateItem(index, 'name', value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _items[index]['category'],
                hint: const Text('Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _updateItem(index, 'category', value);
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_quantityNotifiers[index].value > 1) {
                            _quantityNotifiers[index].value--;
                            _updateItem(index, 'quantity',
                                _quantityNotifiers[index].value);
                          }
                        },
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _quantityNotifiers[index],
                        builder: (context, value, child) {
                          return Text(value.toString());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _quantityNotifiers[index].value++;
                          _updateItem(index, 'quantity',
                              _quantityNotifiers[index].value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (_items.length > 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _removeItem(index),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Remove Item'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addButton() {
    return ElevatedButton.icon(
      onPressed: _addItem,
      icon: const Icon(Icons.add),
      label: const Text('Add Item'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: _submitEvent,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: const Text('Request Approval'),
    );
  }
}
