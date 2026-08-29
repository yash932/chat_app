import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class LightboxScreen extends StatefulWidget {
  final String imageUrl;
  final String filename;
  final int size;

  const LightboxScreen({
    super.key,
    required this.imageUrl,
    required this.filename,
    this.size = 0,
  });

  @override
  State<LightboxScreen> createState() => _LightboxScreenState();
}

class _LightboxScreenState extends State<LightboxScreen> {
  int _rotationQuarters = 0;
  final TransformationController _transformController = TransformationController();

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = _getFullUrl(widget.imageUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.filename,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.size > 0)
              Text(
                _formatSize(widget.size),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Rotate 90°',
            onPressed: () {
              setState(() {
                _rotationQuarters = (_rotationQuarters + 1) % 4;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Zoom',
            onPressed: () {
              _transformController.value = Matrix4.identity();
              setState(() {
                _rotationQuarters = 0;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 4.0,
          child: RotatedBox(
            quarterTurns: _rotationQuarters,
            child: CachedNetworkImage(
              imageUrl: fullUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.indigoAccent),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.redAccent, size: 48),
                    SizedBox(height: 8),
                    Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
