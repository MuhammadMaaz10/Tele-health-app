import 'package:flutter/material.dart';

class SnackbarService {
  SnackbarService._();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showError(String message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 20,
          left: 16,
          right: 16,
          top: 50,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(String message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          // bottom: 20,
          left: 16,
          right: 16,
          top: 50,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}


