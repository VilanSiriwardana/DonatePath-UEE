import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:donate_path/login_page.dart';
import 'package:donate_path/home_page.dart';
import 'package:donate_path/org_home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Hello, World 1');

        if (snapshot.hasData) {
          print('Hello, World 3');
          print(snapshot.data!.displayName);

          int index = snapshot.data!.email!.indexOf('@');
          String result = snapshot.data!.email!.substring(index + 1);
          print(result);
          if (result == "org.com") {
            print("This is an Organization");
            return OrgHomePage();
          } else {
            print("This is a user");
            return HomePage();
          }
        } else {
          return LoginPage();
        }
      },
    );
  }
}
