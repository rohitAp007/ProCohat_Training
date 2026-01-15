/// ============================================================================
/// CHAT EXCEPTIONS - CUSTOM ERROR TYPES FOR MESSAGING
/// ============================================================================
/// 
/// PURPOSE: Define specific errors for chat operations
/// 
/// LEARNING: Error handling best practices
///
/// ============================================================================

import 'package:supabase_flutter_app/core/error/exceptions.dart';

/// Base exception for chat-related errors
class ChatException extends AppException {
  const ChatException(
    super.message, {
    super.code,
    super.technicalDetails,
  });
}

/// Chat not found exception
class ChatNotFoundException extends ChatException {
  const ChatNotFoundException([String? details])
      : super(
          'Chat not found',
          code: 'CHAT_NOT_FOUND',
          technicalDetails: details,
        );
}

/// Message not found exception
class MessageNotFoundException extends ChatException {
  const MessageNotFoundException([String? details])
      : super(
          'Message not found',
          code: 'MESSAGE_NOT_FOUND',
          technicalDetails: details,
        );
}

/// Failed to send message exception
class MessageSendFailedException extends ChatException {
  final bool isRecoverable;

  const MessageSendFailedException(
    String message, {
    this.isRecoverable = true,
    String? details,
  }) : super(
          message,
          code: 'MESSAGE_SEND_FAILED',
          technicalDetails: details,
        );
}

/// Failed to load chat history exception
class ChatLoadFailedException extends ChatException {
  final bool isRecoverable;

  const ChatLoadFailedException(
    String message, {
    this.isRecoverable = true,
    String? details,
  }) : super(
          message,
          code: 'CHAT_LOAD_FAILED',
          technicalDetails: details,
        );
}

/// Media upload failed exception
class MediaUploadFailedException extends ChatException {
  final bool isRecoverable;

  const MediaUploadFailedException(
    String message, {
    this.isRecoverable = true,
    String? details,
  }) : super(
          message,
          code: 'MEDIA_UPLOAD_FAILED',
          technicalDetails: details,
        );
}
