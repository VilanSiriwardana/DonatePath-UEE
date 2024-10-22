import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'org_home_page.dart';

class EventRequestsPage extends StatefulWidget {
  final int selectedIndex;

  const EventRequestsPage({super.key, this.selectedIndex = 2});

  @override
  _EventRequestsPageState createState() => _EventRequestsPageState();
}

class _EventRequestsPageState extends State<EventRequestsPage> {
  Future<List<Map<String, dynamic>>> fetchPendingEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Fetch the organization's name from Firestore
      DocumentSnapshot orgSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(user.uid)
          .get();

      String organizationName = orgSnapshot['name'];

      // Fetch events with status 'pending' and matching the organization's name
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'pending')
          .where('organization', isEqualTo: organizationName)
          .get();

      return eventSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<void> updateEventStatus(String eventId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating event status: $e');
    }
  }

  void _navigateToOrgEventsPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrgHomePage(selectedIndex: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => _navigateToOrgEventsPage(context),
        ),
        title: Text(
          'List of Pending Events',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              // Handle notifications action here
            },
          ),
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPendingEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading events'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> events = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Material(
                      elevation: 6.0,
                      borderRadius: BorderRadius.circular(12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.asset(
                          'assets/images/events_banner.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        var event = events[index];
                        return Card(
                          color: const Color(0xFFF9FEF9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation:
                              4.0, // Add some elevation for shadow effect
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  event['eventName'] ?? 'No Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                                subtitle: Text(
                                  event['eventDescription'] ?? 'No Description',
                                  style: TextStyle(color: Colors.green[700]),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await updateEventStatus(
                                          event['id'], 'accepted');
                                      setState(() {
                                        events.removeAt(index);
                                      });
                                    },
                                    child: Text(
                                      'Accept',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await updateEventStatus(
                                          event['id'], 'notAccepted');
                                      setState(() {
                                        events.removeAt(index);
                                      });
                                    },
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('No pending events available.'));
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.selectedIndex,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrgHomePage(selectedIndex: index),
            ),
          );
        },
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
}
