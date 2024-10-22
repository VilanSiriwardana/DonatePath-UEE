import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';

class EventDonationConfirmationPage extends StatefulWidget {
  final String eventId;
  final Map<String, int> donatedItems;

  const EventDonationConfirmationPage(
      {super.key, required this.eventId, required this.donatedItems});

  @override
  _EventDonationConfirmationPageState createState() =>
      _EventDonationConfirmationPageState();
}

class _EventDonationConfirmationPageState
    extends State<EventDonationConfirmationPage> {
  String? _userName;
  String? _eventName;
  List<Map<String, dynamic>> _donatedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchEventDetails();
    _prepareDonatedItems();
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

  Future<void> _fetchEventDetails() async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (eventDoc.exists) {
        setState(() {
          _eventName = eventDoc.data()?['eventName'] ?? 'Event';
        });
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
  }

  void _prepareDonatedItems() {
    final donatedItems = widget.donatedItems;
    setState(() {
      _donatedItems = donatedItems.entries
          .where((entry) => entry.value > 0)
          .map((entry) => {'name': entry.key, 'quantity': entry.value})
          .toList();
    });
  }

  Future<void> _confirmDonation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        int donatedTotal = _donatedItems.fold<int>(
            0, (sum, item) => sum + (item['quantity'] as int));

        final eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .get();

        if (eventDoc.exists) {
          final currentDonatedCount = eventDoc.data()?['donatedCount'] ?? 0;

          // Update the event's donatedCount field in Firestore
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .update({
            'donatedCount': (currentDonatedCount as int) + donatedTotal,
          });

          // Add the donation details to the contributions collection
          await FirebaseFirestore.instance.collection('contributions').add({
            'userId': user.uid,
            'eventId': widget.eventId,
            'items': _donatedItems,
            'timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation confirmed!')),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/eventDetails',
            arguments: widget.eventId,
            (route) => route.isFirst,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event not found.')),
          );
        }
      }
    } catch (e) {
      print('Error saving donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error confirming donation. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      headerText: 'Confirm Donation',
      profileImage: '',
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eventBanner(),
              const SizedBox(height: 20),
              _thankYouImage(),
              const SizedBox(height: 20),
              _userGreeting(),
              const SizedBox(height: 10),
              _introText(),
              const SizedBox(height: 20),
              _donationSummary(),
              const SizedBox(height: 20),
              _styledConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventBanner() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/organization1.png'),
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

  Widget _thankYouImage() {
    return Center(
      child: Image.asset(
        'assets/images/thank_you.jpg',
        height: 200,
        width: 200,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _userGreeting() {
    return Text(
      'Thank you, ${_userName ?? 'Loading...'}!',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _introText() {
    return const Text(
      'May the "father of understanding" guide you!',
      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
    );
  }

  Widget _donationSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Donation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Column(
          children: _donatedItems.map((item) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                            item['name'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('Quantity: ${item['quantity']}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _styledConfirmButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _confirmDonation,
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
          'Continue',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
