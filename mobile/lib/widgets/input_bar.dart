import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class InputBar extends StatefulWidget {
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final Function(String text, List<Attachment> attachments) onSend;
  final Function(bool isTyping)? onTyping;

  const InputBar({
    super.key,
    this.replyingTo,
    this.onCancelReply,
    required this.onSend,
    this.onTyping,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pendingImages = [];
  final List<PlatformFile> _pendingFiles = [];
  bool _isUploading = false;
  bool _isTyping = false;

  void _handleTextChange(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTyping?.call(true);
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      widget.onTyping?.call(false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(source: source);
        if (photo != null) setState(() => _pendingImages.add(photo));
      } else {
        final photos = await _picker.pickMultiImage();
        if (photos.isNotEmpty) setState(() => _pendingImages.addAll(photos));
      }
    } catch (_) {}
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pendingFiles.addAll(result.files));
      }
    } catch (_) {}
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    final hasAttachments = _pendingImages.isNotEmpty || _pendingFiles.isNotEmpty;

    if (text.isEmpty && !hasAttachments) return;

    List<Attachment> uploaded = [];

    if (hasAttachments) {
      setState(() => _isUploading = true);
      if (_pendingImages.isNotEmpty) {
        final imgAtts = await ApiService.uploadImages(_pendingImages);
        uploaded.addAll(imgAtts);
      }
      if (_pendingFiles.isNotEmpty) {
        final fileAtts = await ApiService.uploadFiles(_pendingFiles);
        uploaded.addAll(fileAtts);
      }
      setState(() {
        _isUploading = false;
        _pendingImages.clear();
        _pendingFiles.clear();
      });
    }

    widget.onSend(text, uploaded);
    _textController.clear();
    _handleTextChange('');
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.mist)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply Preview Banner
            if (widget.replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: c.cobaltTint,
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 16, color: c.cobalt),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to @${widget.replyingTo!.senderName}: ${widget.replyingTo!.text.isEmpty ? "[Attachment]" : widget.replyingTo!.text}',
                        style: TextStyle(fontSize: 12, color: c.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: c.inkSecondary),
                      onPressed: widget.onCancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Pending Attachments Preview Shelf
            if (_pendingImages.isNotEmpty || _pendingFiles.isNotEmpty)
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._pendingImages.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.cobalt),
                        ),
                        child: Stack(
                          children: [
                            Center(child: Icon(Icons.image, color: c.cobalt, size: 20)),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _pendingImages.removeAt(entry.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 10, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    ..._pendingFiles.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.mist),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.insert_drive_file, size: 15, color: c.cobalt),
                            const SizedBox(width: 6),
                            Text(
                              entry.value.name,
                              style: TextStyle(fontSize: 11, color: c.ink),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _pendingFiles.removeAt(entry.key)),
                              child: Icon(Icons.close, size: 13, color: c.inkSecondary),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Text Input Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: c.inkSecondary, size: 20),
                    tooltip: 'Attach',
                    onPressed: _pickFiles,
                  ),
                  IconButton(
                    icon: Icon(Icons.photo_outlined, color: c.inkSecondary, size: 20),
                    tooltip: 'Photos',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surfaceSunken,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.mist),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _textController,
                        onChanged: _handleTextChange,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontSize: 14, color: c.ink),
                        decoration: InputDecoration(
                          hintText: 'Write a message…',
                          hintStyle: TextStyle(fontSize: 14, color: c.inkTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_isUploading)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.cobalt),
                      ),
                    )
                  else
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.cobalt,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_upward, color: c.onCobalt, size: 18),
                        onPressed: _handleSend,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
