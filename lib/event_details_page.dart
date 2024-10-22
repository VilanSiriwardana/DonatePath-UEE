import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_layout.dart';

class EventDetailsPage extends StatelessWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  Future<Map<String, dynamic>?> _fetchEventDetails() async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      if (eventDoc.exists) {
        return eventDoc.data();
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchOrganizerDetails(
      String organizerId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(organizerId)
          .get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      print('Error fetching organizer details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchEventDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading event details.'));
        }

        final eventData = snapshot.data!;
        final organizerId = eventData['eventOrganizerId'];

        return Scaffold(
          body: MainLayout(
            selectedIndex: 2,
            headerText: 'Details',
            profileImage: '',
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0), // Add top padding
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eventImage(eventData),
                    const SizedBox(height: 20),
                    Text(
                      eventData['eventName'] ?? 'Unnamed Event',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _organizerSection(organizerId),
                    const SizedBox(height: 10),
                    _contactCard(
                      icon: Icons.location_on,
                      title: eventData['organization'] ?? 'Unknown Organization',
                      subtitle: eventData['organizationContact'] ??
                          'No contact provided',
                    ),
                    const SizedBox(height: 20),
                    _completionSection(eventData),
                    const SizedBox(height: 20),
                    Text(
                      eventData['eventDescription'] ?? 'No description available.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    _eventDateTime(eventData),
                    const SizedBox(height: 20),
                    _contributionsSection(context),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to Event Donation Page
                          Navigator.pushNamed(context, '/eventDonation', arguments: eventId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Donate Now',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    )

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget for the event image with a fallback asset
  Widget _eventImage(Map<String, dynamic> eventData) {
    final imageUrl = eventData['imageUrl'];

    return imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Use local asset image if network image fails
              return Image.asset(
                'assets/images/organization1.png',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            },
          )
        : Image.asset(
            'assets/images/organization1.png',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          );
  }

  // Widget to display the organizer section using eventOrganizerId
  Widget _organizerSection(String organizerId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchOrganizerDetails(organizerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Error loading organizer details.');
        }

        final organizerData = snapshot.data!;
        return _contactCard(
          icon: Icons.person,
          title: organizerData['name'] ?? 'Unknown Organizer',
          subtitle: organizerData['phone'] ?? 'No phone number provided',
        );
      },
    );
  }

  // Widget for contact information cards
  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  // Widget to display the event completion section
  Widget _completionSection(Map<String, dynamic> eventData) {
    final totalItems = eventData['itemsCount'] ?? 1;
    final completedItems = eventData['donatedCount'] ?? 0;
    final completionPercent = (completedItems / totalItems).clamp(0.0, 1.0);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Completion', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: completionPercent,
              color: Colors.green,
              backgroundColor: Colors.green.shade100,
            ),
            const SizedBox(height: 10),
            Text('${(completionPercent * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  // Widget for event date and time
  Widget _eventDateTime(Map<String, dynamic> eventData) {
    final eventDate = eventData['eventDate'] ?? 'No date provided';
    final eventTime = eventData['eventTime'] ?? 'No time provided';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(eventDate, style: const TextStyle(fontSize: 16)),
        Text(eventTime, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  // Widget to display contributions and handle navigation
  Widget _contributionsSection(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('contributions')
          .where('eventId', isEqualTo: eventId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Error loading contributions.');
        }

        final contributions = snapshot.data!.docs;
        final contributorsCount =
            contributions.map((doc) => doc['userId']).toSet().length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 30),
                const SizedBox(width: 5),
                Text('+ $contributorsCount', style: const TextStyle(fontSize: 18)),
              ],
            ),
            GestureDetector(
              onTap: () {
                // Navigate to Event Contributions Page
                Navigator.pushNamed(context, '/eventContributions',
                    arguments: eventId);
              },
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 5),
                  Text('Contributions'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
