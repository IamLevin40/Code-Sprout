import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A dialog for confirming logout action
class LogoutDialog extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;

  const LogoutDialog({
    super.key,
    this.onLogoutSuccess,
  });

  /// Shows the logout confirmation dialog
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onLogoutSuccess,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LogoutDialog(
        onLogoutSuccess: onLogoutSuccess,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the dialog
        onLogoutSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.logout, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text('Logout'),
        ],
      ),
      content: const Text(
        'Are you sure you want to logout?',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () => _handleLogout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Logout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
