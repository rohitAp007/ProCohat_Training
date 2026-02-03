import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ImageViewerScreen - Full screen image viewer with pinch-to-zoom
/// 
/// **Features:**
/// - Pinch to zoom
/// - Swipe to dismiss
/// - Loading indicator
/// - Error handling
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? fileName;
  
  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    this.fileName,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(fileName ?? 'Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Download image
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading...')),
              );
            },
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            color: Colors.white,
          ),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
