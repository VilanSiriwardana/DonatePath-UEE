import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'main_layout.dart';

class EventCreationPage extends StatefulWidget {
  const EventCreationPage({super.key});

  @override
  _EventCreationPageState createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();

  String? _selectedOrganization;
  List<String> _organizations = []; // Placeholder for organizations

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  Future<void> _fetchOrganizations() async {
    try {
      // Fetch the list of organizations from Firestore
      final snapshot =
          await FirebaseFirestore.instance.collection('organizations').get();
      setState(() {
        _organizations = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data != null && data['name'] != null
                  ? data['name'].toString()
                  : null;
            })
            .whereType<String>() // Filter out null values
            .toList();
      });
    } catch (e) {
      print('Error fetching organizations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      headerText: 'Create Event',
      profileImage: '',
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0), // Add top padding
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bannerSection(),
              const SizedBox(height: 20),
              _formContainer(),
              const SizedBox(height: 30), // Spacing between form and button
              _styledButton(context), // Moved outside the form container
            ],
          ),
        ),
      ),
    );
  }

  // Banner section with a background image and event details
  Widget _bannerSection() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(
              'assets/images/organization5.png'), // Placeholder image
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          color: Colors.green.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: const Text(
            'Event Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Container for the form with a green background
  Widget _formContainer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade100, // Light green background
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _styledTextField('Event Name', _eventNameController),
          const SizedBox(height: 20),
          _styledDropdownField(), // Keep the dropdown inside main form
          const SizedBox(height: 20),
          _styledTextField(
            'Event Description',
            _eventDescriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          _DateFieldWidget(), // Isolated date picker
          const SizedBox(height: 20),
          _TimeFieldWidget(), // Isolated time picker
        ],
      ),
    );
  }

  // Styled text fields
  Widget _styledTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
    );
  }

  // Styled dropdown field for organization selection
  Widget _styledDropdownField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return DropdownButtonFormField<String>(
          value: _selectedOrganization,
          hint: const Text('Select Organization'),
          items: _organizations.map((organization) {
            return DropdownMenuItem(
              value: organization,
              child: Text(organization),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedOrganization = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'Select Organization',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          ),
        );
      },
    );
  }

  // Styled button placed outside the form container
  Widget _styledButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (_eventNameController.text.isNotEmpty &&
              _eventDescriptionController.text.isNotEmpty &&
              _selectedOrganization != null) {
            Navigator.pushNamed(
              context,
              '/eventItemList',
              arguments: {
                'eventName': _eventNameController.text,
                'eventDescription': _eventDescriptionController.text,
                'organization': _selectedOrganization!,
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill in all fields before proceeding.'),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: const Text(
          'List Items',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// Date field widget with its own state
class _DateFieldWidget extends StatefulWidget {
  @override
  __DateFieldWidgetState createState() => __DateFieldWidgetState();
}

class __DateFieldWidgetState extends State<_DateFieldWidget> {
  final TextEditingController _eventDateController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _eventDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _eventDateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Event Date',
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.green),
          onPressed: () => _selectDate(context),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// Time field widget with its own state
class _TimeFieldWidget extends StatefulWidget {
  @override
  __TimeFieldWidgetState createState() => __TimeFieldWidgetState();
}

class __TimeFieldWidgetState extends State<_TimeFieldWidget> {
  final TextEditingController _eventTimeController = TextEditingController();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _eventTimeController.text = pickedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _eventTimeController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Event Time',
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time, color: Colors.green),
          onPressed: () => _selectTime(context),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
