import 'package:flutter/material.dart';

// 1. Auth Screens
import 'package:kisaanguide4/screens/auth/phone_input_screen.dart';
import 'package:kisaanguide4/screens/auth/otp_verification_screen.dart';
import 'package:kisaanguide4/screens/auth/user_details_screen.dart';

// 2. Home/Dashboard
import 'package:kisaanguide4/screens/home/dashboard_screen.dart';
import 'package:kisaanguide4/screens/land_management_screen.dart';

// 3. Weather
import 'package:kisaanguide4/screens/weather/weather_screen.dart';

// 4. Crops & Orchards
import 'package:kisaanguide4/screens/crops/add_crop_screen.dart';
import 'package:kisaanguide4/screens/crops/orchard_details_screen.dart';

// 5. Finance (Hasab Katab)
import 'package:kisaanguide4/data/models/expense_tracker/screens/expense_main_screen.dart';

class AppRouter {
  // Routes ke Unique Names (Constants)
  static const String phoneInput = '/';
  static const String otp = '/otp';
  static const String userDetail = '/user-detail';
  static const String dashboard = '/dashboard';
  static const String weather = '/weather';
  static const String addCrop = '/add-crop';
  static const String orchard = '/orchard';
  static const String expenses = '/expenses';
  static const String landManagement = '/land-management'; // New Screen Route

  // Yeh function main.dart mein supply kiya jata hai
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      phoneInput: (context) => const PhoneInputScreen(),
      
      otp: (context) {
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
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final bool isUrduLanguage = args?['isUrdu'] ?? true;
        
        return AddCropScreen(isUrdu: isUrduLanguage);
      },
      
      orchard: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final bool initialIsEnglish = args?['initialIsEnglish'] ?? true;
        return OrchardDetailsScreen(initialIsEnglish: initialIsEnglish);
      },
      
      expenses: (context) => const ExpenseMainScreen(),

      landManagement: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final bool isUrduLanguage = args?['isUrdu'] ?? true;
        return LandManagementScreen(isUrdu: isUrduLanguage);
      },
    };
  }

  // Navigation Helpers
  static void goToExpenses(BuildContext context) {
    Navigator.pushNamed(context, expenses);
  }

  static void goToDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, dashboard);
  }

  static void goToLandManagement(BuildContext context, {bool isUrdu = true}) {
    Navigator.pushNamed(context, landManagement, arguments: {'isUrdu': isUrdu});
  }
}
