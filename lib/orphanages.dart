import 'package:donate_path/main_layout.dart';
import 'package:flutter/material.dart';

class OrphanagePage extends StatelessWidget {
  const OrphanagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 1,
      headerText: 'Orphanages',
      profileImage: '',
      child: const OrphanageContent(),
    );
  }
}

class OrphanageContent extends StatelessWidget {
  const OrphanageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Orphanages"));
  }
}
