import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'org_event_request_page.dart'; // Import your Event Requests Page
import 'org_topVolunteers_page.dart'; // Import your Top Volunteers Page

class OrgEventsPage extends StatefulWidget {
  const OrgEventsPage({super.key});

  @override
  _OrgEventsPageState createState() => _OrgEventsPageState();
}

class _OrgEventsPageState extends State<OrgEventsPage> {
  bool _isDropdownVisible = false;
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        return Scaffold(
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventRequestsPage(),
                            ),
                          );
                        },
                        child: Material(
                          elevation: 8.0,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/events_banner.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TopVolunteersPage(),
                            ),
                          );
                        },
                        child: Material(
                          elevation: 8.0,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/volun_banner.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'My Recently Held Events',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            buildEventCard('assets/images/event1.png',
                                'Hands of Hope Event'),
                            buildEventCard('assets/images/event2.png',
                                'Charity for Children Campaign'),
                            buildEventCard('assets/images/event3.png',
                                'Health and Wellness Drive'),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Global Events',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            buildEventCard('assets/images/global_event1.png',
                                'Orphanage Support Drive'),
                            buildEventCard('assets/images/global_event2.png',
                                'Elderly Care Campaign'),
                            buildEventCard('assets/images/global_event3.png',
                                'Community Donation Drive'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
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
                            'Events',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
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
                  top: 90,
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
                            child: Text(
                              snapshot.hasData && snapshot.data?['name'] != null
                                  ? snapshot.data!['name']
                                  : 'John Doe',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              snapshot.hasData &&
                                      snapshot.data?['email'] != null
                                  ? snapshot.data!['email']
                                  : 'john.doe@example.com',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.person),
                            title: Text('Profile'),
                            onTap: () {
                              _toggleDropdown();
                              Navigator.pushNamed(context, '/profile');
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.settings),
                            title: Text('Settings'),
                            onTap: () {
                              _toggleDropdown();
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
          ),
        );
      },
    );
  }

  Widget buildEventCard(String imagePath, String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
