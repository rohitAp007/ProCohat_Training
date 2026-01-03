import 'package:flutter/material.dart';

/// Loading overlay that can be shown on top of any screen
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  /// Show loading overlay
  static void show(
    BuildContext context, {
    String? message,
  }) {
    // Remove existing overlay if any
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hide loading overlay
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
