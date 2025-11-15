import 'package:flutter/material.dart';

class BackConfirmationPopup {
  /// Shows a slide-up confirmation dialog asking user to leave the module.
  /// Returns `true` if user confirms Leave, otherwise `false`.
  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'BackConfirmationPopup',
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
                      // Icon (exit)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFF6E6)),
                        child: const Center(
                          child: Icon(Icons.exit_to_app, color: Color(0xFF3B3B3B), size: 34),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Proceed to Leave?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const Text('Your progress in this module may not be saved.', style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 128,
                            height: 32,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Leave', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 128,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
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

    return result ?? false;
  }
}
