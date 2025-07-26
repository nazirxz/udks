import 'package:flutter/material.dart';
import '../screens/reset_password_screen.dart';

class DeepLinkHandler {
  static void handleResetPasswordLink(BuildContext context, String url) {
    try {
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];
      
      if (token != null && email != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: token,
              email: email,
            ),
          ),
        );
      } else {
        _showErrorDialog(context, 'Link reset password tidak valid');
      }
    } catch (e) {
      _showErrorDialog(context, 'Terjadi kesalahan saat memproses link');
    }
  }
  
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
