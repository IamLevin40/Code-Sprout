import 'package:flutter/material.dart';

class CorrectLevelPopup {
  /// Show the correct answer popup. Returns when user taps Continue.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'CorrectPopup',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

        return Stack(
          children: [
            // animated background overlay
            GestureDetector(
              onTap: () {},
              child: Opacity(
                opacity: 0.4 * curved.value,
                child: Container(color: Colors.black),
              ),
            ),

            // slide-up container aligned to bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
                child: Container(
                  height: 192,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon (use a green check icon to match reference)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE6F7EE)),
                        child: const Center(
                          child: Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 44),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Correct', style: TextStyle(fontSize: 22, color: Color(0xFF27AE60), fontWeight: FontWeight.w700)),
                      const Text('Great job!', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 128,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Continue', style: TextStyle(fontSize: 16))
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
