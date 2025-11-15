import 'package:flutter/material.dart';

class ModuleAccomplishedPopup {
  /// Show the module accomplished popup. `progressPercent` is 0.0-100.0
  static Future<void> show(BuildContext context, {required double progressPercent}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ModuleAccomplishedPopup',
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
                  height: 300,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon (trophy-like)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE9F5FF)),
                        child: const Center(
                          child: Icon(Icons.emoji_events, color: Color(0xFF2B6CB0), size: 40),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Module Accomplished!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const Text('You have successfully finished this module.', style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text('Progress: ${(progressPercent * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 128,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Complete', style: TextStyle(fontSize: 14))
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
