import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class VolunteerFeedback extends StatefulWidget {
  const VolunteerFeedback({super.key});

  @override
  _VolunteerFeedbackState createState() => _VolunteerFeedbackState();
}

class _VolunteerFeedbackState extends State<VolunteerFeedback> {
  double _rating = 4.0; // Default rating
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          buildTopProfileSection(),
          SizedBox(height: 20),
          buildFeedbackForm(),
        ],
      ),
    );
  }

  Widget buildTopProfileSection() => Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_pic.jpg'), // Replace with NetworkImage if pulling from Firestore
            ),
            SizedBox(height: 10),
            Text(
              'Victoria Robertson',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'A mantra goes here',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildStatItem(Icons.people, '116', 'Followers'),
                buildStatItem(Icons.check_circle, '3+', 'Years'),
                buildStatItem(Icons.star, '4.9', 'Rating'),
                buildStatItem(Icons.comment, '90+', 'Reviews'),
              ],
            ),
          ],
        ),
      );

  Widget buildStatItem(IconData icon, String count, String label) => Column(
        children: [
          Icon(icon, color: Colors.green),
          SizedBox(height: 5),
          Text(
            count,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );

  Widget buildFeedbackForm() => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your thoughts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add your comments...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      _submitFeedback();
                    },
                    child: Text('SUBMIT'),
                  ),
                ],
              )
            ],
          ),
        ),
      );

  // Function to submit feedback (e.g., save to Firestore)
  void _submitFeedback() {
    String comment = _commentController.text;
    double rating = _rating;

    // Logic to save feedback to the database (e.g., Firestore)
    print('Rating: $rating, Comment: $comment');

    // Clear the form after submission
    _commentController.clear();
    setState(() {
      _rating = 4.0; // Reset to default rating
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback submitted successfully!')),
    );
  }
}

void main() => runApp(MaterialApp(home: VolunteerFeedback()));
