class Attachment {
  final String id;
  final String? messageId;
  final String filename;
  final String originalName;
  final String mimetype;
  final int size;
  final String url;

  Attachment({
    required this.id,
    this.messageId,
    required this.filename,
    required this.originalName,
    required this.mimetype,
    required this.size,
    required this.url,
  });

  bool get isImage => mimetype.startsWith('image/');
  bool get isAudio => mimetype.startsWith('audio/');
  bool get isVideo => mimetype.startsWith('video/');

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id']?.toString() ?? '',
      messageId: json['message_id']?.toString(),
      filename: json['filename']?.toString() ?? '',
      originalName: json['original_name']?.toString() ?? json['originalName']?.toString() ?? 'file',
      mimetype: json['mimetype']?.toString() ?? 'application/octet-stream',
      size: int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'filename': filename,
      'originalName': originalName,
      'mimetype': mimetype,
      'size': size,
      'url': url,
    };
  }
}
