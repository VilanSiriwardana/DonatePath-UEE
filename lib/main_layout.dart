import 'package:flutter/material.dart';
import 'bottom_navigation_bar.dart';
import 'side_menu.dart';
import 'custom_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final String headerText;

  const MainLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.headerText,
    required String profileImage,
  });

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  Future<String?> _fetchProfileImageUrl() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return userDoc['profileImage'];
        } else {
          _showToast("User document does not exist.");
          return null;
        }
      } else {
        _showToast("No user signed in.");
        return null;
      }
    } catch (e) {
      _showToast("Error fetching profile image URL: $e");
      return null;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/orphanages');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/eventsList');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/my_items');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        drawer: SideMenu(),
        body: FutureBuilder<String?>(
          future: _fetchProfileImageUrl(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading profile image.'));
            } else {
              String? profileImageUrl = snapshot.data;

              return Column(
                children: [
                  CustomHeader(
                    headerText: widget.headerText,
                    onMenuPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    onNotificationPressed: () {
                      // Handle notification press
                    },
                    onProfilePressed: () {
                      // Handle profile picture press
                    },
                    profileImage: profileImageUrl,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 0), // Adjust top padding if needed
                      child: widget
                          .child, // This is where your page content will appear
                    ),
                  ),
                ],
              );
            }
          },
        ),
        bottomNavigationBar: BottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}
