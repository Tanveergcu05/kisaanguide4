import 'package:flutter/material.dart';

// 1. Auth Screens
import '../screens/auth/phone_input_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/user_details_screen.dart';

// 2. Home/Dashboard
import '../screens/home/dashboard_screen.dart';

// 3. Weather
import '../screens/weather/weather_screen.dart';

// 4. Crops & Orchards
import '../screens/crops/add_crop_screen.dart';
import '../screens/crops/orchard_details_screen.dart';

// 5. Finance (Hasab Katab) - Nayi Screen
// TODO: Jab aap Expenses wali screen bana lein, toh uska import yahan add kar lijiyega.
// import '../screens/finance/expenses_screen.dart'; 

class AppRouter {
  // Routes ke Unique Names (Constants)
  static const String phoneInput = '/';
  static const String otp = '/otp';
  static const String userDetail = '/user-detail';
  static const String dashboard = '/dashboard';
  static const String weather = '/weather';
  static const String addCrop = '/add-crop';
  static const String orchard = '/orchard';
  static const String expenses = '/expenses'; // Naya Path

  // Yeh function main.dart mein supply kiya jata hai
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      phoneInput: (context) => const PhoneInputScreen(),
      
      otp: (context) {
        // Router ke zariye data nikalne ke liye
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        
        return OTPVerificationScreen(
          verificationId: args?['verificationId'] ?? '',
          phoneNumber: args?['phoneNumber'] ?? '',
        );
      },
      
      userDetail: (context) => const UserDetailsScreen(),
      dashboard: (context) => const DashboardScreen(),
      weather: (context) => const WeatherScreen(),
      
      addCrop: (context) {
        // AddCropScreen ke required parameter 'isUrdu' ko arguments se nikal kar pass karne ke liye
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final bool isUrduLanguage = args?['isUrdu'] ?? true; // Default to true (Urdu) agar pass na ho
        
        return AddCropScreen(isUrdu: isUrduLanguage);
      },
      
      orchard: (context) => const OrchardDetailsScreen(),
      
      // TODO: Jab ExpensesScreen ban jaye, toh Placeholder widget ko actual screen se replace kar dena
      expenses: (context) => const Scaffold(
        body: Center(child: Text("Expenses Screen Coming Soon")),
      ),
    };
  }

  // Navigation Helpers (Poori app mein kahin se bhi call karne ke liye)
  static void goToExpenses(BuildContext context) {
    Navigator.pushNamed(context, expenses);
  }

  static void goToDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, dashboard);
  }
}