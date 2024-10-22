import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'org_profile_page.dart';
import 'org_event_details_page.dart';
import 'org_request_form.dart';
import 'org_items_page.dart';
import 'org_events_page.dart';

class OrgHomePage extends StatefulWidget {
  final int selectedIndex;

  const OrgHomePage({super.key, this.selectedIndex = 0}); // Default to 0 if not provided
  @override
  _OrgHomePageState createState() => _OrgHomePageState();
}

class _OrgHomePageState extends State<OrgHomePage> {
  late int _selectedIndex = 0;
  Map<String, dynamic>? _eventDetails;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _pages = [
      HomeContent(
        onEventTap: _navigateToEventDetails,
      ),
      OrgItemsPage(),
      OrgEventsPage(),
      OrgProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _eventDetails =
          null; // Reset event details when navigating via bottom bar
    });
  }

  void _navigateToEventDetails(Map<String, dynamic> eventDetails) {
    setState(() {
      _eventDetails = eventDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _eventDetails == null
          ? IndexedStack(
              index: _selectedIndex,
              children: _pages.map((page) {
                if (page is HomeContent) {
                  return HomeContent(onEventTap: _navigateToEventDetails);
                }
                return page;
              }).toList(),
            )
          : OrgEventDetailsPage(
              title: _eventDetails!['eventName'],
              imagePath: _eventDetails!['imagePath'],
              date: _eventDetails!['eventDate'],
              description: _eventDetails!['eventDescription'],
              completion: _eventDetails!['completion'],
              organizerPhone: _eventDetails!['organizerPhone'],
              contributors: _eventDetails!['contributors'],
              items: _eventDetails!['items'],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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

class HomeContent extends StatefulWidget {
  final Function(Map<String, dynamic>) onEventTap;

  const HomeContent({super.key, required this.onEventTap});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isDropdownVisible = false;
  User? user;
  Future<Map<String, dynamic>?>? _userDataFuture;
  late Future<List<Map<String, dynamic>>> _eventsFuture;

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
          setState(() {
            _eventsFuture = fetchEvents(snapshot['name']);
          });
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

  Future<List<Map<String, dynamic>>> fetchEvents(
      String organizationName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('organization', isEqualTo: organizationName)
          .where('status', isEqualTo: 'accepted')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          'items': List<Map<String, dynamic>>.from(
              data['items'].map((item) => Map<String, dynamic>.from(item))),
        };
      }).toList();
    } catch (e) {
      print("Error fetching events: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching events.')),
      );
      return [];
    }
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      _toggleDropdown();
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading data'));
        } else if (snapshot.hasData && snapshot.data != null) {
          Map<String, dynamic> userData = snapshot.data!;
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          userData['name'] ?? 'Organization Name',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      buildRequestDonationsCard(context),
                      SizedBox(height: 20),
                      Text(
                        'Ongoing Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _eventsFuture,
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (eventSnapshot.hasError) {
                            return Center(child: Text('Error loading events'));
                          } else if (eventSnapshot.hasData &&
                              eventSnapshot.data!.isNotEmpty) {
                            List<Map<String, dynamic>> events =
                                eventSnapshot.data!;
                            return Column(
                              children: events.asMap().entries.map((entry) {
                                int index = entry.key;
                                Map<String, dynamic> event = entry.value;
                                String imagePath =
                                    'assets/images/event${(index % 3) + 1}.png';
                                return buildEventCard(
                                  event['eventName'],
                                  imagePath,
                                  event['eventDate'],
                                  event['eventTime'],
                                  event['eventDescription'],
                                  event['items'],
                                );
                              }).toList(),
                            );
                          } else {
                            return Center(child: Text('No events available.'));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 35,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu),
                            onPressed: () {},
                          ),
                          Text(
                            'Welcome Back!',
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
                            onPressed: () {},
                          ),
                          GestureDetector(
                            onTap: _toggleDropdown,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: userData['logoUrl'] != null
                                  ? NetworkImage(userData['logoUrl'])
                                  : AssetImage(
                                          'assets/images/default_avatar.png')
                                      as ImageProvider,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_isDropdownVisible)
                Positioned(
                  top: 80,
                  right: 16,
                  child: Material(
                    elevation: 5,
                    child: Container(
                      width: 200,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(userData['name'] ?? 'Organization Name',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(userData['email'] ?? 'info@example.com',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.person),
                            title: Text('Profile'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrgProfilePage(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.settings),
                            title: Text('Settings'),
                            onTap: () {
                              // Navigate to Settings Page
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.logout),
                            title: Text('Logout'),
                            onTap: () {
                              _logout(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          return Center(child: Text('No user data available'));
        }
      },
    );
  }

  Widget buildRequestDonationsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DonationRequestForm()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.lightGreen[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          image: DecorationImage(
            image: AssetImage('assets/images/request_donations.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget buildEventCard(String title, String imagePath, String date,
      String time, String description, List<Map<String, dynamic>> items) {
    return GestureDetector(
      onTap: () {
        widget.onEventTap({
          'eventName': title,
          'imagePath': imagePath,
          'eventDate': date,
          'eventTime': time,
          'eventDescription': description,
          'completion': 50, // example value
          'organizerPhone': '123-456-7890',
          'contributors': ['Contributor 1', 'Contributor 2'],
          'items': items,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 11.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 237, 243, 237),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 30),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('$date at $time'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'See Event Details →',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
