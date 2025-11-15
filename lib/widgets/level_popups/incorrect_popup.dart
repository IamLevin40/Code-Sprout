import 'package:flutter/material.dart';

class IncorrectLevelPopup {
  /// Show the incorrect answer popup. Returns when user taps Continue.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'IncorrectPopup',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

        return Stack(
          children: [
            GestureDetector(
              onTap: () {},
              child: Opacity(
                opacity: 0.4 * curved.value,
                child: Container(color: Colors.black),
              ),
            ),

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
                      // Icon (use a red sad icon to match reference)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFDECEE)),
                        child: const Center(
                          child: Icon(Icons.sentiment_dissatisfied, color: Color(0xFFE04B5A), size: 44),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Incorrect', style: TextStyle(fontSize: 22, color: Color(0xFFE04B5A), fontWeight: FontWeight.w700)),
                      const Text("Don't give up. Let's try again!", style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
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
