import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/attachment.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/lightbox_screen.dart';

class AttachmentView extends StatelessWidget {
  final List<Attachment> attachments;

  const AttachmentView({
    super.key,
    required this.attachments,
  });

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

  IconData _getFileIcon(String filename) {
    final parts = filename.split('.');
    final ext = parts.isNotEmpty ? parts.last.toLowerCase() : '';
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['zip', 'rar', '7z', 'tar'].contains(ext)) return Icons.folder_zip;
    if (['doc', 'docx', 'txt'].contains(ext)) return Icons.description;
    if (['mp3', 'wav', 'ogg', 'webm'].contains(ext)) return Icons.audiotrack;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.movie;
    if (['js', 'ts', 'dart', 'py', 'json', 'html', 'css'].contains(ext)) return Icons.code;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: attachments.map((att) {
          if (att.isImage) {
            final fullUrl = _getFullUrl(att.url);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LightboxScreen(
                        imageUrl: att.url,
                        filename: att.originalName,
                        size: att.size,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
                    decoration: BoxDecoration(
                      color: c.surfaceSunken,
                      border: Border.all(color: c.mist),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CachedNetworkImage(
                          imageUrl: fullUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            height: 140,
                            color: c.surfaceSunken,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: c.cobalt),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 100,
                            color: c.surfaceSunken,
                            child: Icon(Icons.broken_image, color: c.inkTertiary),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatSize(att.size),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            // General File / Audio
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.mist),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getFileIcon(att.originalName), color: c.cobalt, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          att.originalName,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: c.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatSize(att.size),
                          style: TextStyle(fontSize: 10.5, color: c.inkTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.download, color: c.cobalt, size: 18),
                ],
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}
