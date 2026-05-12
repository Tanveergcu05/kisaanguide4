import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'user_details_screen.dart'; // Navigation ke liye import

class OTPVerificationScreen extends StatelessWidget {
  const OTPVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leading: const BackButton(color: Colors.black)
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Logo Section: Text delete kar diya hai, sirf clean logo hai
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 50),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.softGrey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.verified_user_rounded, 
                size: 110, 
                color: AppColors.primaryGreen
              ),
            ),
            
            const SizedBox(height: 20),
            const Text("Enter 6-Digit Code", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text("+92 *** **** 123", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPBox(context)),
              ),
            ),
            
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {},
              child: const Text("Resend OTP", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Details Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserDetailsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Verify & Proceed", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPBox(BuildContext context) {
    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.softGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) {
          if (value.length == 1) FocusScope.of(context).nextFocus();
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(counterText: "", border: InputBorder.none),
      ),
    );
  }
}