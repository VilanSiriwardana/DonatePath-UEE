import 'package:donate_path/main_layout.dart';
import 'package:flutter/material.dart';

class EventPage extends StatelessWidget {
  const EventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      headerText: 'Events',
      profileImage: '',
      child: const EventsContent(),
    );
  }
}

class EventsContent extends StatelessWidget {
  const EventsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Events"));
  }
}
