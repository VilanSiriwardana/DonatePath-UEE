import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Allows more than 3 items
        backgroundColor: Colors.white,
        currentIndex: selectedIndex,
        onTap: onTap,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        items: [
          _buildBottomNavigationBarItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: selectedIndex == 0,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.house_siding,
            label: 'Orphanages',
            isSelected: selectedIndex == 1,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.event,
            label: 'Events',
            isSelected: selectedIndex == 2,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.inventory,
            label: 'My Items',
            isSelected: selectedIndex == 3,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.person,
            label: 'Profile',
            isSelected: selectedIndex == 4,
          ),
        ],
      ),
    );
  }

  // Helper method to build BottomNavigationBarItem with selected state styling
  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(isSelected ? 6 : 0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: isSelected ? 28 : 24,
          color: isSelected ? Colors.green : Colors.grey,
        ),
      ),
      label: label,
    );
  }
}
