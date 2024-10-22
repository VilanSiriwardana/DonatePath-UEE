import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'org_home_page.dart';

class TopVolunteersPage extends StatelessWidget {
  final int selectedIndex;

  const TopVolunteersPage({super.key, this.selectedIndex = 2}); // Assuming '2' is for Events

  Future<List<Map<String, dynamic>>> fetchVolunteers() async {
    try {
      QuerySnapshot volunteerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'volunteer')
          .get();

      // Convert and filter the documents
      List<Map<String, dynamic>> volunteers = volunteerSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((volunteer) =>
              volunteer.containsKey('rating') && volunteer['rating'] is num)
          .toList();

      // Sort the list by rating in descending order
      volunteers
          .sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));

      return volunteers;
    } catch (e) {
      print('Error fetching volunteers: $e');
      return [];
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
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => _navigateToOrgEventsPage(context),
        ),
        title: Text(
          'Top Volunteers',
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
          SizedBox(width: 9),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchVolunteers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading volunteers'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> volunteers = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Material(
                      elevation: 8.0,
                      borderRadius: BorderRadius.circular(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.asset(
                          'assets/images/volun_banner.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: volunteers.length,
                      itemBuilder: (context, index) {
                        var volunteer = volunteers[index];
                        String name = volunteer['name'] ?? 'No Name';
                        String rating =
                            volunteer['rating']?.toString() ?? 'N/A';
                        String profileImage = volunteer['profileImage'] ?? '';

                        return Column(
                          children: [
                            Card(
                              color: const Color.fromARGB(255, 234, 240,
                                  239), // Custom light green color
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: profileImage.isNotEmpty
                                      ? NetworkImage(profileImage)
                                      : AssetImage(
                                              'assets/images/default_avatar.png')
                                          as ImageProvider,
                                  radius: 25,
                                ),
                                title: Text(name),
                                subtitle: Text('Rating: $rating'),
                                onTap: () {
                                  // Handle volunteer tap
                                },
                              ),
                            ),
                            SizedBox(height: 10), // Adds space between cards
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('No volunteers available.'));
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
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
