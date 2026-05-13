import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Is import ko check karlein ke aapke project ka folder name 'kisaanguide4' hi hai na?
import 'package:kisaanguide4/core/app_router.dart';

void main() {
  // Yeh line zaroori hai agar hum hardware ya system settings (jaise orientation) use karein
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar ko professional look dene ke liye (Optional)
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
      // Debug banner ko khatam karna professional lagta hai
      debugShowCheckedModeBanner: false,
      
      title: 'Kisaan Guide',

      // Professional Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        // Kisaan App ke liye Green color scheme behtreen hai
        colorSchemeSeed: Colors.green,
        
        // Fonts aur Text styling ko yahan se poori app mein control kiya ja sakta hai
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),

      // Professional Routing Setup
      // initialRoute wo screen hai jo app khulne par sabse pehle dikhegi
      initialRoute: AppRouter.phoneInput,
      
      // Saari screens ka rasta AppRouter sambhale ga
      routes: AppRouter.getRoutes(),

      // Agar koi route galti se miss ho jaye toh error se bachne ke liye
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