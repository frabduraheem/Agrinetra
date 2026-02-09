import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// TODO: Run `flutterfire configure` to generate this file
import 'firebase_options.dart'; 
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Uncomment the following lines after running `flutterfire configure`
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrinetra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/register': (context) => const RegistrationPage(),
      },
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const DashboardPage();
          }
          return const WelcomePage();
        },
      ),
    );
  }
}
