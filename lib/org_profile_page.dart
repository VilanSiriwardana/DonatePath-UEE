import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class OrgProfilePage extends StatefulWidget {
  const OrgProfilePage({super.key});

  @override
  _OrgProfilePageState createState() => _OrgProfilePageState();
}

class _OrgProfilePageState extends State<OrgProfilePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _organizationName;
  String? _vision;
  String? _mission;
  String? _communityEngagement;
  String? _phone;
  String? _address;
  String? _logoUrl; // To store the logo URL
  bool _isDropdownVisible = false;
  late TabController _tabController;
  late Future<void> organizationDetailsFuture;
  List<String> _organizationImages = [];

  void _toggleDropdown() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
    });
  }

  Future<void> _fetchOrganizationDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('organizations').doc(user.uid).get();
      setState(() {
        _organizationName = doc['name'];
        _vision = doc['vision'];
        _mission = doc['mission'];
        _communityEngagement = doc['communityEngagement'];
        _phone = doc['phone'];
        _address = doc['address'];
        _logoUrl = doc['logoUrl']; // Fetch the logo URL
        _organizationImages = List<String>.from(doc['images'] ?? []);
      });
    } else {
      throw Exception("User not logged in");
    }
  }

  Future<void> _uploadImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String fileName =
          '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.png';

      try {
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;

        String imageUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('organizations').doc(user.uid).update({
          'images': FieldValue.arrayUnion([imageUrl])
        });

        setState(() {
          _organizationImages.add(imageUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!')),
        );
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image. Please try again.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    organizationDetailsFuture = _fetchOrganizationDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
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
    return Scaffold(
      body: FutureBuilder<void>(
        future: organizationDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading organization details. Please try again.',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else {
            return _buildContent();
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _organizationName ?? 'Organization Name',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800]),
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: _uploadImage,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Established in 2000',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.green[800],
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green,
                  tabs: [
                    Tab(text: 'Details'),
                    Tab(text: 'Contact Info'),
                  ],
                ),
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(),
                      _buildContactInfoTab(),
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
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () {},
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Profile',
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
                        backgroundImage: _logoUrl != null
                            ? NetworkImage(_logoUrl!)
                            : AssetImage('assets/images/default_avatar.png')
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
                      child: Text(_organizationName ?? 'Organization Name',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          _auth.currentUser?.email ??
                              'organization@example.com',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Profile'),
                      onTap: () {
                        _toggleDropdown();
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
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Vision', _vision ?? 'Not provided'),
          SizedBox(height: 10),
          _buildInfoCard('Mission', _mission ?? 'Not provided'),
          SizedBox(height: 10),
          _buildInfoCard(
              'Community Engagement', _communityEngagement ?? 'Not provided'),
          SizedBox(height: 20),
          Text(
            'Organization Photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 10),
          _buildImageGallery(),
        ],
      ),
    );
  }

  Widget _buildContactInfoTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Phone Number', _phone ?? 'Not provided'),
          SizedBox(height: 10),
          _buildInfoCard(
              'Email Address', _auth.currentUser?.email ?? 'Not provided'),
          SizedBox(height: 10),
          _buildInfoCard('Address', _address ?? 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              content,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _organizationImages.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(_organizationImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
