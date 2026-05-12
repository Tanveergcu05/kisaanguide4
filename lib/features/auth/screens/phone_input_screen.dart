import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/constants/app_colors.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatelessWidget {
  const PhoneInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 48, 177, 55), AppColors.gradientBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100), // Top space barha di takay design balanced lagay
            
            // Welcome Section (Centered and Double Size)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Welcome to KisanGuide",
                textAlign: TextAlign.center, // Center Align
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 56, // Double Size (28 * 2)
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.2,
                  height: 1.1, // Line spacing for large text
                ),
              ),
            ),
            
            const Spacer(),
            
            // Glassmorphism Card
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Verify with Phone Number",
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.primaryGreen
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Phone Number", 
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)
                  ),
                  const SizedBox(height: 12),
                  IntlPhoneField(
                    initialCountryCode: 'PK',
                    showCountryFlag: true,
                    dropdownIconPosition: IconPosition.trailing,
                    cursorColor: AppColors.primaryGreen,
                    decoration: InputDecoration(
                      hintText: '3xx xxxxxxx',
                      filled: true,
                      fillColor: AppColors.softGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Continue Button (Circular Type)
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OTPVerificationScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        elevation: 5,
                        shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                        // Sides se Circle (Capsule) karne ke liye 30 radius
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), 
                      ),
                      child: const Text(
                        "Continue", 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}