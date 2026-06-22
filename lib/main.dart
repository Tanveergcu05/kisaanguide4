import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; 
import 'package:kisaanguide4/core/app_router.dart';

// Screens ke standard classes aur paths
import 'screens/auth/phone_input_screen.dart'; 
import 'screens/home/dashboard_screen.dart';

// Global variable taake check kiya ja sake ke user pehle se logged in hai ya nahi
bool isUserLoggedIn = false;

void main() async { 
  // Hardware aur native plugins (Firebase/SharedPreferences) initialize karne ke liye zaroori line
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ko project ke sath initialize kiya gaya hai
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // SharedPreferences se local data read kar rahe hain (Yeh internet ka intezar nahi karta)
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Agar 'isLoggedIn' khali (null) milega to default false set ho jayega
  final bool prefsLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool hasFirebaseSession = FirebaseAuth.instance.currentUser != null;
  isUserLoggedIn = prefsLoggedIn && hasFirebaseSession;

  // Status bar ko professional transparent look dene ke liye
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const KisaanGuideApp());
}

class KisaanGuideApp extends StatelessWidget {
  const KisaanGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kisaan Guide',

      // Professional Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),

      // BULLET SPEED DIRECT ROUTING:
      // Dynamically load Dashboard if logged in, otherwise Phone Input Screen as root.
      initialRoute: '/',
      
      // Map routes: Dynamically override the '/' root route to avoid history stack contamination.
      routes: (() {
        final Map<String, WidgetBuilder> r = AppRouter.getRoutes();
        r['/'] = (context) => isUserLoggedIn ? const DashboardScreen() : const PhoneInputScreen();
        return r;
      })(),

      // Agar koi route galti se miss ho jaye toh handle karne ke liye
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Screen not found!')),
          ),
        );
      },
    );
  }
}
