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
      otp: (context) => const OTPVerificationScreen(),
      userDetail: (context) => const UserDetailsScreen(),
      dashboard: (context) => const DashboardScreen(),
      weather: (context) => const WeatherScreen(),
      addCrop: (context) => const AddCropScreen(),
      orchard: (context) => const OrchardDetailsScreen(),// Nayi entry
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