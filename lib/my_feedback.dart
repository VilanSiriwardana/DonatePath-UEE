import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';

class MyFeedbackPage extends StatefulWidget {
  const MyFeedbackPage({super.key});

  @override
  _MyFeedbackPageState createState() => _MyFeedbackPageState();
}

class _MyFeedbackPageState extends State<MyFeedbackPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 1, // Assuming this is the appropriate tab for feedback
      headerText: 'My Feedbacks',
      profileImage: '', // Profile image can be fetched and passed here if needed
      child: FutureBuilder<User?>(
        future: _getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching feedback data.'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No user is currently signed in.'));
          } else {
            User? user = snapshot.data;
            return _buildFeedbackList(user!.uid);
          }
        },
      ),
    );
  }

  Future<User?> _getCurrentUser() async {
    return _auth.currentUser;
  }

  Widget _buildFeedbackList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('feedbacks')
          .where('senderId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading feedbacks.'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No feedbacks submitted.'));
        } else {
          List<DocumentSnapshot> feedbackDocs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> feedbackData =
                  feedbackDocs[index].data() as Map<String, dynamic>;
              return _buildFeedbackCard(feedbackData);
            },
          );
        }
      },
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedbackData) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(feedbackData['userId']).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(); // If user data not found, return an empty space
        } else {
          Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>;
          String profileImageUrl = userData['profileImage'] ?? '';
          String receiverName = userData['name'] ?? 'Unknown User';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receiverName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < feedbackData['rating']
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16.0,
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          feedbackData['description'] ?? 'No description provided',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
