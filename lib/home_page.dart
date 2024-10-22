import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_layout.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0, // Index for the 'Home' tab
      headerText: 'WELCOME', // Dynamic header text for the Home Page
      profileImage: '',
      child: const HomeContent(), // The main content of the Home Page
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isDropdownVisible = false;

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
        const SnackBar(content: Text('Failed to sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content with space for the sticky header
        Padding(
          padding: const EdgeInsets.only(top: 30.0), // Space for sticky header
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                buildPictureButton(
                  context,
                  '',
                  'assets/images/donate_two.jpeg',
                  () {
                    // Navigate to Donate Items page or action
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/donate_page');
                  },
                ),
                const SizedBox(height: 20),
                buildPictureButton(
                  context,
                  '',
                  'assets/images/view_donations.jpeg',
                  () {
                    // Navigate to Items page or action
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/all_items');
                  },
                ),
                const SizedBox(height: 20),
                Section(
                  title: 'Orphanages',
                  items: [
                    SectionCard(
                      title: 'Caring Hearts',
                      imagePath: 'assets/images/caring_hearts.jpeg',
                      onTap: () {},
                    ),
                    SectionCard(
                      title: 'Guiding stars',
                      imagePath: 'assets/images/guiding_stars.jpeg',
                      onTap: () {
                        // Navigate to Tender Care details or page
                      },
                    ),
                    SectionCard(
                      title: 'Tender care',
                      imagePath: 'assets/images/tender_care.jpeg',
                      onTap: () {
                        // Navigate to Tender Care details or page
                      },
                    ),
                    SectionCard(
                      title: 'Kinder hearts',
                      imagePath: 'assets/images/kinder_hearts.jpeg',
                      onTap: () {
                        // Navigate to Tender Care details or page
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Section(
                  title: 'Elderly Homes',
                  items: [
                    SectionCard(
                      title: 'Golden Age',
                      imagePath: 'assets/images/elderly_one.jpeg',
                      onTap: () {
                        // Navigate to Golden Age details or page
                      },
                    ),
                    SectionCard(
                      title: 'Silver Care',
                      imagePath: 'assets/images/elderly_two.jpeg',
                      onTap: () {
                        // Navigate to Silver Care details or page
                      },
                    ),
                    SectionCard(
                      title: 'Peaceful pines',
                      imagePath: 'assets/images/elderly_three.jpeg',
                      onTap: () {
                        // Navigate to Silver Care details or page
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Section(
                  title: 'Events',
                  items: [
                    SectionCard(
                      title: 'Generosity gata',
                      imagePath: 'assets/images/event_one.jpeg',
                      onTap: () {
                        // Navigate to Golden Age details or page
                      },
                    ),
                    SectionCard(
                      title: 'Kind Hearts',
                      imagePath: 'assets/images/event_two.jpeg',
                      onTap: () {
                        // Navigate to Silver Care details or page
                      },
                    ),
                    SectionCard(
                      title: 'Blish Bash',
                      imagePath: 'assets/images/event_three.jpeg',
                      onTap: () {
                        // Navigate to Silver Care details or page
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Sticky header with profile icon
        // Dropdown menu when profile icon is tapped
        if (_isDropdownVisible)
          Positioned(
            top: 80,
            right: 16,
            child: Material(
              elevation: 5,
            ),
          ),
      ],
    );
  }
}

// Reusable Widget for Picture Button
Widget buildPictureButton(BuildContext context, String label, String imagePath,
    VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.lightGreen[100],
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Ensure text is readable over the image
          ),
        ),
      ),
    ),
  );
}

class Section extends StatelessWidget {
  final String title;
  final List<SectionCard> items;

  const Section({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items,
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const SectionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
