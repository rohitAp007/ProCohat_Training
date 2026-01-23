/// ============================================================================
/// MESSAGE INPUT WIDGET
/// ============================================================================
/// 
/// PURPOSE: Text input field with send button
/// 
/// LEARNING: TextEditingController + callback pattern
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter_app/features/chat/utils/chat_constants.dart';

/// MessageInput - Input field for typing messages
/// 
/// **Features:**
/// - Multi-line text input
/// - Send button
/// - Validation callback
class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
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
                  // Hide counter unless close to limit
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
}
