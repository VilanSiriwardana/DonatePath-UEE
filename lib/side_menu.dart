import 'package:donate_path/volunteer_list.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'settings_page.dart';
import 'logout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'volunteer_register.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  Future<Map<String, dynamic>> _getUserData() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = auth.currentUser;

    if (user != null) {
      DocumentSnapshot doc =
          await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return {
          'name': doc['name'] ?? 'Guest',
          'profileImage': doc['profileImage'] ?? '',
          'userType': doc['userType'] ?? '',
        };
      }
    }
    return {'name': 'Guest', 'profileImage': '', 'userType': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error loading user data: ${snapshot.error}');
            return const Center(child: Text('Error loading user data'));
          } else {
            final userData = snapshot.data!;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                  ),
                  accountName: Text(userData['name']),
                  accountEmail: const Text('Volunteer App'),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: userData['profileImage'].isNotEmpty
                        ? NetworkImage(userData['profileImage'])
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                ),
                _buildMenuSection(
                  context,
                  title: 'Navigation',
                  items: [
                    _buildMenuItem(
                      context,
                      icon: Icons.home,
                      label: 'Volunteer',
                      onTap: () async {
                        await _navigateBasedOnUserType(context);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.feedback,
                      label: 'Feedbacks',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my_feedback');
                      },
                    ),
                  ],
                ),
                _buildMenuSection(
                  context,
                  title: 'Settings',
                  items: [
                    _buildMenuItem(
                      context,
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
                _buildMenuSection(
                  context,
                  title: 'Account',
                  items: [
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () => Logout.performLogout(context),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Future<void> _navigateBasedOnUserType(BuildContext context) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? user = auth.currentUser;

      if (user != null) {
        DocumentSnapshot doc =
            await firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          String userType = doc['userType'] ?? '';
          if (userType == 'volunteer') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VolunteerListPage(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VolunteerRegisterPage(),
              ),
            );
          }
        } else {
          _showToast("User data not found.");
        }
      } else {
        _showToast("No user signed in.");
      }
    } catch (e) {
      _showToast("Error checking user type: $e");
    }
  }

  Widget _buildMenuSection(BuildContext context,
      {required String title, required List<Widget> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[700]),
            ),
          ),
          const Divider(),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String label,
      required Function() onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(label),
      onTap: onTap,
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
