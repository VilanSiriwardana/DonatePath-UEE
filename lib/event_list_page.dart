import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_layout.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      headerText: 'Events',
      profileImage: '',
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _createEventBanner(context),
              _searchBar(),
              _eventsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createEventBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/createEvent');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Do you want to help those in need?\nOrganize a donation event here',
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              const Icon(Icons.add, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for the search bar
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onSubmitted: (value) {
          // Update the search query only when "Enter" is pressed
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
      ),
    );
  }

  // Widget to display the list of events
  Widget _eventsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
              child: Text('Error loading events. Please try again.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events found.'));
        }

        final events = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final eventName = (data['eventName'] ?? '').toString().toLowerCase();
          final organization =
              (data['organization'] ?? '').toString().toLowerCase();
          final eventDate = (data['eventDate'] ?? '').toString().toLowerCase();

          // Check if any field matches the search query
          return eventName.contains(_searchQuery) ||
              organization.contains(_searchQuery) ||
              eventDate.contains(_searchQuery);
        }).toList();

        if (events.isEmpty) {
          return const Center(child: Text('No matching events found.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            var event = events[index];
            return _eventCard(context, event);
          },
        );
      },
    );
  }

  Widget _eventCard(BuildContext context, QueryDocumentSnapshot event) {
    final data = event.data() as Map<String, dynamic>;

    final imageUrl = data['imageUrl'];
    final eventName = data['eventName'] ?? 'Unnamed Event';
    final eventDate = data['eventDate'] ?? 'No Date Provided';
    final completion =
        (data['completion'] != null) ? data['completion'] / 100 : 0.0;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/organizations1.png',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/organization1.png',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 10),
            Text(
              eventName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('Date: $eventDate'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: completion,
              color: Colors.green,
              backgroundColor: Colors.green.shade100,
            ),
            const SizedBox(height: 10),
            _participantCount(event.id),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/eventDetails',
                    arguments: event.id,
                  );
                },
                child: const Text('See Event Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display the number of participants based on the 'contributions' collection
  Widget _participantCount(String eventId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('contributions')
          .where('eventId', isEqualTo: eventId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading participants...');
        }
        if (snapshot.hasError) {
          return const Text('Error loading participants');
        }

        final count = snapshot.data?.docs.length ?? 0;

        return Text(
          'Total Participants: $count',
          style: const TextStyle(color: Colors.grey),
        );
      },
    );
  }
}
