import 'package:flutter/material.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const CustomText(
          text: 'Home',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textColor,
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: const Center(
        child: CustomText(
          text: 'Welcome to Telehealth Services',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textColor,
        ),
      ),
    );
  }
}

