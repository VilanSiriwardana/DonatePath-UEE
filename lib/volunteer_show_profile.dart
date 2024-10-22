import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';

class VolunteerShowProfile extends StatefulWidget {
  final Map<String, dynamic> volunteerData;

  const VolunteerShowProfile({super.key, required this.volunteerData});

  @override
  _VolunteerShowProfileState createState() => _VolunteerShowProfileState();
}

class _VolunteerShowProfileState extends State<VolunteerShowProfile>
    with TickerProviderStateMixin {
  late TabController _tabController;
  double? _selectedRating;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isAnonymous = false; // Default is not anonymous
  bool _showFeedbackSection = false;
  Map<String, bool> _expandedFeedbacks = {}; // Track feedback expansion
  List<DocumentSnapshot> _feedbacks = [];
  bool _isFollowing = false;
  num? _age;
String? _gender;
String? _phone;
String? _nic;
String? _address;
String? _district;


  @override
void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this);
  _fetchFeedbacks();
  _checkFollowingStatus();
  
  // Populate the details from volunteerData
  _age = widget.volunteerData['age'];
  _gender = widget.volunteerData['gender'];
  _phone = widget.volunteerData['phone'];
  _nic = widget.volunteerData['nic'];
  _address = widget.volunteerData['address'];
  _district = widget.volunteerData['district'];
}


  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String feedbackDescription = _feedbackController.text;

      if (currentUser != null) {
        String senderName = 'Anonymous'; // Default to anonymous
        if (!_isAnonymous) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            senderName = userDoc['name'] ??
                'Anonymous'; // Use the actual name if not anonymous
          }
        }

        String? userId = widget.volunteerData['id'];
        if (userId == null || userId.isEmpty) {
          userId = widget.volunteerData['documentId'];
        }

        if (userId != null && userId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('feedbacks').add({
            'userId': userId, // Profile owner's ID
            'senderId': currentUser.uid, // Logged-in user ID
            'senderName': senderName, // Sender's name or "Anonymous"
            'description': feedbackDescription, // Feedback text
            'rating': _selectedRating, // Rating value
            'timestamp': FieldValue.serverTimestamp(), // Timestamp
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted successfully')),
          );

          // Reset the form
          _feedbackController.clear();
          setState(() {
            _selectedRating = null;
            _isAnonymous = false; // Reset the anonymous toggle
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid profile ID')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    }
  }

  Future<void> _fetchFeedbacks() async {
    String? userId =
        widget.volunteerData['id'] ?? widget.volunteerData['documentId'];
    if (userId != null && userId.isNotEmpty) {
      QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        _feedbacks = feedbackSnapshot.docs;
        // Initialize the expansion state for each feedback
        _expandedFeedbacks = {for (var doc in _feedbacks) doc.id: false};
      });
    }
  }

  Future<void> _checkFollowingStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(widget.volunteerData['id'])
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        List<dynamic> followerList = userDoc.data()!['followerList'] ?? [];
        setState(() {
          _isFollowing = followerList.contains(currentUser.uid);
        });
      }
    }
  }

Future<void> _toggleFollow() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  String? userId = widget.volunteerData['id'];
  if (userId == null || userId.isEmpty) return;

  try {
    DocumentReference<Map<String, dynamic>> userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    DocumentSnapshot<Map<String, dynamic>> userDoc = await userRef.get();
    if (userDoc.exists && userDoc.data() != null) {
      List<dynamic> followerList = userDoc.data()!['followerList'] ?? [];

      if (_isFollowing) {
        // Unfollow the user
        followerList.remove(currentUser.uid);
        await userRef.update({
          'followerList': followerList,
          'followers': FieldValue.increment(-1),
        });
      } else {
        // Follow the user
        followerList.add(currentUser.uid);
        await userRef.update({
          'followerList': followerList,
          'followers': FieldValue.increment(1),
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating follow status: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 4,
      headerText: 'Profile',
      profileImage: widget.volunteerData['profileImage'] ?? '',
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
      padding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200, // Adjust the width and height to fit the CircleAvatar
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
                  backgroundImage: widget.volunteerData['profileImage'] != null &&
                          widget.volunteerData['profileImage'].isNotEmpty
                      ? NetworkImage(widget.volunteerData['profileImage'])
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.volunteerData['name'] ?? 'Loading...',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              widget.volunteerData['email'] != null
                  ? Text(
                      widget.volunteerData['email'],
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    )
                  : const Text(
                      'No email provided',
                      textAlign: TextAlign.center,
                    ),
            ],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _toggleFollow,
              child: Row(
                children: [
                  Icon(
                    _isFollowing ? Icons.how_to_reg : Icons.person_add,
                    color: _isFollowing ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isFollowing ? 'Unfollow' : 'Follow',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isFollowing ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  Widget buildStatsSection() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildStatItem(
                Icons.people,
                widget.volunteerData['followers']?.toString() ?? '0',
                'Followers'),
            buildStatItem(Icons.calendar_today,
                '${widget.volunteerData['years'] ?? 0}+', 'Years'),
            buildStatItem(
                Icons.star,
                '${widget.volunteerData['rating']?.toStringAsFixed(1) ?? '0.0'}',
                'Rating'),
            buildStatItem(Icons.feedback,
                '${widget.volunteerData['feedbacks'] ?? 0}+', 'Reviews'),
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

  Widget buildTabBarView() => SizedBox(
        height: 650.0,
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
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showFeedbackSection = !_showFeedbackSection;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                textStyle: const TextStyle(color: Colors.white),
              ),
              child: Text(
                _showFeedbackSection ? 'Hide Feedback' : 'Add Feedback',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (_showFeedbackSection) ...[
              _buildFeedbackForm(),
            ] else ...[
              _buildFeedbackList(),
            ],
          ],
        ),
      );

  Widget _buildFeedbackList() {
    return Column(
      children: _feedbacks.map((feedbackDoc) {
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
              // Check if the sender is anonymous
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

  Widget _buildFeedbackForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share your thoughts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        // Group the anonymous toggle switch and rating stars in a single row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Anonymous toggle switch
            Row(
              children: [
                const Text('Anonymous'),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: _isAnonymous,
                    activeTrackColor: Colors.green,
                    inactiveTrackColor: Colors.grey,
                    inactiveThumbColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Rating stars
            _buildRatingStars(),
          ],
        ),

        const SizedBox(height: 10),
        TextField(
          controller: _feedbackController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add your comments...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                _feedbackController.clear();
                setState(() {
                  _selectedRating = null;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.green),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                textStyle: const TextStyle(color: Colors.white),
              ),
              onPressed: _submitFeedback,
              child: const Text(
                'SUBMIT',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize
          .min, // Ensure the row only takes up as much space as needed
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = index + 1.0;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 2.0), // Reduce spacing for closer alignment
            child: Icon(
              index < (_selectedRating ?? 0) ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 28.0, // Adjust the size if needed
            ),
          ),
        );
      }),
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
        itemCount: widget.volunteerData['photos']?.length ?? 0,
        itemBuilder: (context, index) {
          final photoUrl = widget.volunteerData['photos'][index];
          return Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
            ),
          );
        },
      );
}
