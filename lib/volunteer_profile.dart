import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'main_layout.dart';

class VolunteerProfile extends StatefulWidget {
  const VolunteerProfile({super.key});

  @override
  _VolunteerProfileState createState() => _VolunteerProfileState();
}

class _VolunteerProfileState extends State<VolunteerProfile>
    with TickerProviderStateMixin {
  File? _profileImage;
  final picker = ImagePicker();
  String? _profileImageUrl;
  String? _name;
  String? _email;
  num? _years;
  num? _rating;
  num? _feedbacks;
  num? _followers;
  List<String> _photoUrls = [];
  String? _address;
  String? _phone;
  num? _age;
  String? _gender;
  String? _nic;
  String? _district;

  late TabController _tabController; // Declare the TabController

  List<DocumentSnapshot> _feedbackList = [];
  Map<String, bool> _expandedFeedbacks = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load user data from Firestore based on the currently authenticated user
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data()!;
          setState(() {
            _profileImageUrl = userData['profileImage'] ?? '';
            _name = userData['name'] ?? 'N/A';
            _email = userData['email'] ?? 'N/A';
            _years = userData['years'] ?? 0;
            _rating = userData['rating'] ?? 0.0;
            _feedbacks = userData['feedbacks'] ?? 0;
            _followers = userData['followers'] ?? 0;
            _photoUrls = List<String>.from(userData['photos'] ?? []);
            _address = userData['address'] ?? 'N/A';
            _phone = userData['phone'] ?? 'N/A';
            _age = userData['age'] ?? 0;
            _gender = userData['gender'] ?? 'N/A';
            _nic = userData['nic'] ?? 'N/A';
            _district = userData['district'] ?? 'N/A';
          });
          await _fetchFeedbacks();
        } else {
          Fluttertoast.showToast(
            msg: "User data does not exist in Firestore.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "No user is currently signed in.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error loading user data: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Function to pick an image from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _uploadImageToFirebase();
      }
    } catch (e) {
      print('Error picking image: $e');
      Fluttertoast.showToast(
        msg: "Error picking image: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Upload the image to Firebase Storage and save the URL in Firestore
  Future<void> _uploadImageToFirebase() async {
    if (_profileImage == null) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String fileName = 'profile_${user.uid}.png';
        Reference storageRef =
            FirebaseStorage.instance.ref().child('profileImages/$fileName');
        UploadTask uploadTask = storageRef.putFile(_profileImage!);

        TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Save the image URL in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImage': downloadUrl});

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        Fluttertoast.showToast(
          msg: "Profile image updated successfully.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      Fluttertoast.showToast(
        msg: "Error uploading image: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _pickAndUploadPhoto(int index) async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        String fileName =
            'photo_${FirebaseAuth.instance.currentUser!.uid}_$index.png';
        Reference storageRef =
            FirebaseStorage.instance.ref().child('userPhotos/$fileName');
        UploadTask uploadTask = storageRef.putFile(imageFile);

        TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update the photo URL list and save it to Firestore
        setState(() {
          if (_photoUrls.length > index) {
            _photoUrls[index] = downloadUrl;
          } else {
            _photoUrls.add(downloadUrl);
          }
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'photos': _photoUrls});

        Fluttertoast.showToast(
          msg: "Photo uploaded successfully.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error uploading photo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _removePhoto(int index) async {
    try {
      setState(() {
        _photoUrls.removeAt(index); // Remove the photo from the list
      });

      // Update Firestore with the modified list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'photos': _photoUrls});

      Fluttertoast.showToast(
        msg: "Photo removed successfully.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error removing photo: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _fetchFeedbacks() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _feedbackList = feedbackSnapshot.docs;
        _expandedFeedbacks = {for (var doc in _feedbackList) doc.id: false};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 4,
      headerText: 'Profile',
      profileImage: _profileImageUrl ?? '',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                buildTopProfileSection(),
                buildStatsSection(),
                buildTabBar(),
                buildTabBarView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTopProfileSection() => Container(
        padding: const EdgeInsets.only(top: 0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                width: 200, // Adjust width and height to fit the CircleAvatar
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green, // Green border color
                    width: 4, // Border width
                  ),
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: _profileImageUrl != null &&
                          _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
                  child: _profileImageUrl == null
                      ? Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey[700],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _name ?? 'Loading...',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            _email != null
                ? Text(
                    _email!,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  )
                : const CircularProgressIndicator(),
          ],
        ),
      );

  Widget buildStatsSection() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildStatItem(
                Icons.people, _followers?.toString() ?? '0', 'Followers'),
            buildStatItem(Icons.calendar_today, '${_years ?? 0}+', 'Years'),
            buildStatItem(
                Icons.star, _rating?.toStringAsFixed(1) ?? '0.0', 'Rating'),
            buildStatItem(Icons.feedback, '${_feedbacks ?? 0}+', 'Reviews'),
          ],
        ),
      );

  Widget buildStatItem(IconData icon, String count, String label) => Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.green),
              const SizedBox(width: 5),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      );

  Widget buildTabBar() => Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Photos'),
            Tab(text: 'Details'),
            Tab(text: 'Feedbacks'),
          ],
        ),
      );

  Widget buildTabBarView() => ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 500.0,
        maxHeight: 650.0,
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          buildPhotoGrid(),
          buildDetailsSection(),
          buildFeedbacksSection(),
        ],
      ),
    );


  Widget buildDetailsSection() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDetailRow(Icons.cake, 'Age', _age?.toString()),
            buildDetailRow(Icons.person, 'Gender', _gender),
            buildDetailRow(Icons.phone, 'Phone', _phone),
            buildDetailRow(Icons.credit_card, 'NIC', _nic),
            buildDetailRow(Icons.home, 'Address', _address),
            buildDetailRow(Icons.location_city, 'District', _district),
          ],
        ),
      );

  Widget buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column for the icon
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(
              width: 15), // Set padding to 10 pixels between icon and label
          // Column for the label
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Column for the value
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Not available',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFeedbacksSection() => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_feedbackList.isNotEmpty) ...[
              _buildFeedbackList(),
            ] else ...[
              const Text('No feedbacks available.'),
            ],
          ],
        ),
      );

  Widget _buildFeedbackList() {
    return Column(
      children: _feedbackList.map((feedbackDoc) {
        final feedback = feedbackDoc.data() as Map<String, dynamic>;
        return _buildFeedbackCard(feedbackDoc.id, feedback);
      }).toList(),
    );
  }

  Widget _buildFeedbackCard(String feedbackId, Map<String, dynamic> feedback) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedFeedbacks[feedbackId] = !_expandedFeedbacks[feedbackId]!;
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              feedback['senderName'] == 'Anonymous'
                  ? _buildAnonymousFeedbackRow()
                  : _buildProfileImageRow(feedback),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: Text(
                  feedback['description'] ?? 'No feedback provided',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  feedback['description'] ?? 'No feedback provided',
                ),
                crossFadeState: _expandedFeedbacks[feedbackId]!
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousFeedbackRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: const NetworkImage(
              'https://via.placeholder.com/150'), // Placeholder image
        ),
        const SizedBox(width: 10),
        _buildSenderInfo({'senderName': 'Anonymous', 'rating': 0}),
      ],
    );
  }

  Widget _buildProfileImageRow(Map<String, dynamic> feedback) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(feedback['senderId'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: const NetworkImage(
                    'https://via.placeholder.com/150'), // Placeholder while loading
              ),
              const SizedBox(width: 10),
              _buildSenderInfo(feedback),
            ],
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: const NetworkImage(
                    'https://via.placeholder.com/150'), // Placeholder for error
              ),
              const SizedBox(width: 10),
              _buildSenderInfo(feedback),
            ],
          );
        } else {
          final userDoc = snapshot.data!;
          final profileImageUrl =
              userDoc['profileImage'] ?? 'https://via.placeholder.com/150';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
              const SizedBox(width: 10),
              _buildSenderInfo(feedback),
            ],
          );
        }
      },
    );
  }

  Widget _buildSenderInfo(Map<String, dynamic> feedback) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              feedback['senderName'] ?? 'Anonymous',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < (feedback['rating'] ?? 0)
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 16.0,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildPhotoGrid() => GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photoUrls.isEmpty
            ? 0
            : (_photoUrls.length < 6
                ? _photoUrls.length + 1
                : _photoUrls.length),
        itemBuilder: (context, index) {
          if (index < _photoUrls.length) {
            return GestureDetector(
              onTap: () =>
                  _showPhotoOptionsDialog(index), // Show options when tapped
              child: Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Image.network(
                  _photoUrls[index],
                  fit: BoxFit.cover,
                ),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () => _pickAndUploadPhoto(index),
              child: Card(
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.add_a_photo,
                      size: 50, color: Colors.grey[700]),
                ),
              ),
            );
          }
        },
      );

  // Show dialog to choose between camera and gallery
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoOptionsDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Photo Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(index); // Replace the existing photo
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
