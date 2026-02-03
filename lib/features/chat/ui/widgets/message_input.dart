/// ============================================================================
/// MESSAGE INPUT WITH MULTIMEDIA SUPPORT
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_constants.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String imagePath)? onImageSelected;
  final Function(String videoPath)? onVideoSelected;
  final Function(String filePath, String fileName)? onFileSelected;
  
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onImageSelected,
    this.onVideoSelected,
    this.onFileSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              onPressed: () => _showAttachmentOptions(context),
            ),
            
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: ChatConstants.messageInputHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFF075E54)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: null,
                minLines: 1,
                maxLength: ChatConstants.maxMessageLength,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  if (currentLength > ChatConstants.maxMessageLength * 0.9) {
                    return Text(
                      '$currentLength/$maxLength',
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF075E54),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send Attachment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.pink,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _AttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _AttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'File',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null && onImageSelected != null) {
        onImageSelected!(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(minutes: 5),
      );
      
      if (video != null && onVideoSelected != null) {
        onVideoSelected!(video.path);
      }
    } catch (e) {
      print('Error picking video: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls', 'ppt', 'pptx'],
      );
      
      if (result != null && result.files.single.path != null && onFileSelected != null) {
        onFileSelected!(result.files.single.path!, result.files.single.name);
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
