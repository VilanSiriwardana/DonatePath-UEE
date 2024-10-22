import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';

class EventDonationPage extends StatefulWidget {
  final String eventId;

  const EventDonationPage({super.key, required this.eventId});

  @override
  _EventDonationPageState createState() => _EventDonationPageState();
}

class _EventDonationPageState extends State<EventDonationPage> {
  List<Map<String, dynamic>> _items = [];
  Map<String, int> _itemQuantities = {};
  String? _eventName;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
    _fetchUserName();
  }

  Future<void> _fetchEventDetails() async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        final items = List<Map<String, dynamic>>.from(eventData['items']);

        setState(() {
          _eventName = eventData['eventName'];
          _items = items;
          _itemQuantities = {
            for (var item in items) item['name']: 0,
          };
        });
      }
    } catch (e) {
      print('Error fetching event items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error loading event items. Please try again.')),
      );
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void _incrementQuantity(String itemName, int availableQuantity) {
    setState(() {
      if (_itemQuantities[itemName]! < availableQuantity) {
        _itemQuantities[itemName] = (_itemQuantities[itemName] ?? 0) + 1;
      }
    });
  }

  void _decrementQuantity(String itemName) {
    setState(() {
      if ((_itemQuantities[itemName] ?? 0) > 0) {
        _itemQuantities[itemName] = (_itemQuantities[itemName]! - 1);
      }
    });
  }

  void _submitDonation() {
    Navigator.pushNamed(context, '/eventDonationConfirmation', arguments: {
      'eventId': widget.eventId,
      'donatedItems': _itemQuantities,
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      headerText: 'Donate',
      profileImage: '',
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0), // Added top padding
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bannerSection(),
              const SizedBox(height: 20),
              _greetingSection(),
              const SizedBox(height: 10),
              _introTextSection(),
              const SizedBox(height: 20),
              _itemListSection(),
              const SizedBox(height: 20),
              _styledDonateButton(),
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
          image: AssetImage('assets/images/items2.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          color: Colors.green.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            _eventName ?? 'Loading...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _greetingSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Hello!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _userName ?? 'Loading...',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _introTextSection() {
    return const Text(
      'You can select the items you like to donate. Here, we will display your contribution with the Participants section.',
      style: TextStyle(fontSize: 16),
    );
  }

  Widget _itemListSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final itemName = item['name'];
        final availableQuantity = item['quantity'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.green.shade100, // Light green shaded background
            borderRadius: BorderRadius.circular(10.0),
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
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/items2.png',
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('Available: $availableQuantity'),
                      ],
                    ),
                  ),
                  _quantityControl(itemName, availableQuantity),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quantityControl(String itemName, int availableQuantity) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _decrementQuantity(itemName),
        ),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '${_itemQuantities[itemName]}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _incrementQuantity(itemName, availableQuantity),
        ),
      ],
    );
  }

  // Styled Donate Button
  Widget _styledDonateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitDonation,
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
        child: const Text(
          'Donate',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
