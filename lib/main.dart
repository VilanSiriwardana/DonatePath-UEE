import 'package:donate_path/orphanages.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'all_items_page.dart';
import 'donate_page.dart';
import 'events.dart';
import 'my_items_page.dart';
import 'theme_notifier.dart';
import 'language_notifier.dart';
import 'auth_wrapper.dart';
import 'settings_page.dart';
import 'signup_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'volunteer_profile.dart';
import 'volunteer_list.dart';
import 'my_feedback.dart';
import 'volunteer_dashboard.dart';
import 'volunteer_register.dart';
import 'event_list_page.dart';
import 'create_event_page.dart';
import 'event_item_list_page.dart';
import 'event_details_page.dart';
import 'event_donation_page.dart';
import 'event_donation_confirmation_page.dart';
import 'event_contributions_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LanguageNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, LanguageNotifier>(
      builder: (context, themeNotifier, languageNotifier, child) {
        return MaterialApp(
          title: 'Donations App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.green,
          ),
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(languageNotifier.currentLanguage),
          initialRoute: '/',
          routes: {
            '/': (context) => AuthWrapper(),
            '/signup': (context) => SignUpPage(),
            '/signin': (context) => LoginPage(),
            '/home': (context) => HomePage(),
            '/profile': (context) => const VolunteerProfile(),
            '/settings': (context) => const SettingsPage(),
            '/volunteer_dashboard': (context) => VolunteerDashboard(),
            '/volunteer_register': (context) => VolunteerRegisterPage(),
            '/volunteer_list': (context) => VolunteerListPage(),
            '/my_feedback': (context) => MyFeedbackPage(),
            '/orphanages': (context) => OrphanagePage(),
            '/my_items': (context) => MyItemsPage(),
            '/events': (context) => EventPage(),
            '/donate_page': (context) => DonatePage(),
            '/all_items': (context) => AllItemsPage(),
            '/eventsList': (context) => const EventListPage(),
            '/createEvent': (context) => const CreateEventPage(),
            '/eventItemList': (context) {
              // Retrieve arguments passed to this route safely
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is Map<String, dynamic>) {
                return EventItemListPage(eventDetails: args);
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('Invalid event details. Please try again.'),
                  ),
                );
              }
            },
            '/eventDetails': (context) {
              // Retrieve the event ID passed as argument
              final eventId = ModalRoute.of(context)?.settings.arguments;
              if (eventId is String) {
                return EventDetailsPage(eventId: eventId);
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('Invalid event ID. Please try again.'),
                  ),
                );
              }
            },
            '/eventDonation': (context) {
              // Retrieve the event ID passed as argument
              final eventId = ModalRoute.of(context)?.settings.arguments;
              if (eventId is String) {
                return EventDonationPage(eventId: eventId);
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('Invalid event ID. Please try again.'),
                  ),
                );
              }
            },
            '/eventDonationConfirmation': (context) {
              // Retrieve the arguments passed as a Map
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is Map<String, dynamic> &&
                  args.containsKey('eventId') &&
                  args.containsKey('donatedItems')) {
                return EventDonationConfirmationPage(
                  eventId: args['eventId'],
                  donatedItems: args['donatedItems'],
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child:
                        Text('Invalid donation information. Please try again.'),
                  ),
                );
              }
            },
            '/eventContributions': (context) {
              // Retrieve the event ID passed as argument
              final eventId = ModalRoute.of(context)?.settings.arguments;
              if (eventId is String) {
                return EventContributionsPage(eventId: eventId);
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('Invalid event ID. Please try again.'),
                  ),
                );
              }
            },
          },
        );
      },
    );
  }
}
