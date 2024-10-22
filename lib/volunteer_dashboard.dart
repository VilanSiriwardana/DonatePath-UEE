import 'package:flutter/material.dart';
import 'main_layout.dart'; // Import MainLayout

class VolunteerDashboard extends StatelessWidget {
  const VolunteerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0, // Adjust this index according to your navigation bar setup
      headerText: 'Volunteer Dashboard',
      profileImage: '', // Pass the profile image URL if available, otherwise keep it empty
      child: Center(
        child: const Text(
          'Welcome to the Volunteer Dashboard!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
