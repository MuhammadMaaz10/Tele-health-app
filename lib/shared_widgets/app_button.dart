import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height = 50,
    this.borderRadius = 25,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final isDisabled = onPressed == null && !isLoading;
    final txtColor = textColor ?? Colors.white;
    final resolvedBgColor = isDisabled ? Colors.grey.shade400 : bgColor;
    final resolvedTxtColor = isDisabled ? Colors.grey.shade100 : txtColor;

    return GestureDetector(
      onTap: isLoading || isDisabled ? null : onPressed,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLoading ? resolvedBgColor.withValues(alpha: 0.6) : resolvedBgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : Text(
          text,
          style: TextStyle(
            color: resolvedTxtColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
