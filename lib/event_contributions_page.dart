import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_layout.dart';

class EventContributionsPage extends StatefulWidget {
  final String eventId;

  const EventContributionsPage({super.key, required this.eventId});

  @override
  _EventContributionsPageState createState() => _EventContributionsPageState();
}

class _EventContributionsPageState extends State<EventContributionsPage> {
  String? _eventName;
  List<Map<String, dynamic>> _contributions = [];

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
    _fetchContributions();
  }

  Future<void> _fetchEventDetails() async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (eventDoc.exists) {
        setState(() {
          _eventName = eventDoc.data()?['eventName'];
        });
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
  }

  Future<void> _fetchContributions() async {
    try {
      final contributionsSnapshot = await FirebaseFirestore.instance
          .collection('contributions')
          .where('eventId', isEqualTo: widget.eventId)
          .get();

      final contributions =
          await Future.wait(contributionsSnapshot.docs.map((doc) async {
        final userId = doc['userId'];
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        return {
          'userId': userId,
          'userName': userDoc.data()?['name'] ?? 'Unknown User',
          'userLocation': userDoc.data()?['district'] ?? 'Unknown Location',
          'userImage':
              userDoc.data()?['profileImage'] ?? '', // Profile image URL
          'timestamp': doc['timestamp'],
          'phone': userDoc.data()?['phone'] ?? 'No phone number',
          'donatedItems': doc['items'],
        };
      }).toList());

      setState(() {
        _contributions = contributions;
      });
    } catch (e) {
      print('Error fetching contributions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      headerText: 'Contributions',
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
              const Text(
                'Thank you for your contributions!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _contributorsList(),
            ],
          ),
        ),
      ),
    );
  }

  // Banner section with the event name as text
  Widget _bannerSection() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        image: DecorationImage(
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

  // List of contributors
  Widget _contributorsList() {
    if (_contributions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _contributions.length,
      itemBuilder: (context, index) {
        final contribution = _contributions[index];
        return _contributorCard(contribution);
      },
    );
  }

  // Widget for each contributor card
  Widget _contributorCard(Map<String, dynamic> contribution) {
    final userName = contribution['userName'];
    final userLocation = contribution['userLocation'];
    final userImage = contribution['userImage'];
    final timestamp = (contribution['timestamp'] as Timestamp).toDate();
    final formattedDate =
        '${timestamp.day}/${timestamp.month}/${timestamp.year}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: userImage.isNotEmpty
              ? NetworkImage(userImage)
              : AssetImage('assets/images/user4.png') as ImageProvider,
        ),
        title:
            Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(userLocation),
        trailing: Text(formattedDate),
        onTap: () => _showContributorDetails(contribution),
      ),
    );
  }

  // Detailed view of each contributor with their donated items
  void _showContributorDetails(Map<String, dynamic> contribution) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final donatedItems =
            List<Map<String, dynamic>>.from(contribution['donatedItems']);
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: contribution['userImage'].isNotEmpty
                        ? NetworkImage(contribution['userImage'])
                        : AssetImage('assets/images/user4.png')
                            as ImageProvider,
                    radius: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contribution['userName'],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(contribution['phone']),
                      ],
                    ),
                  ),
                  const Icon(Icons.call, color: Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Your Donation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: donatedItems.length,
                  itemBuilder: (context, index) {
                    final item = donatedItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: Image.asset(
                          'assets/images/items2.png',
                          height: 40,
                          width: 40,
                        ),
                        title: Text(item['name']),
                        trailing: Text(item['quantity'].toString()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
