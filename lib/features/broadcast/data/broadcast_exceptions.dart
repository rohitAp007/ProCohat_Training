/// ============================================================================
/// BROADCAST EXCEPTIONS - CUSTOM EXCEPTIONS FOR BROADCAST OPERATIONS
/// ============================================================================

/// Base exception for broadcast operations
abstract class BroadcastException implements Exception {
  final String message;
  
  const BroadcastException(this.message);
  
  @override
  String toString() => message;
}

/// Thrown when a broadcast list is not found
class BroadcastListNotFoundException extends BroadcastException {
  const BroadcastListNotFoundException([
    String message = 'Broadcast list not found',
  ]) : super(message);
}

/// Thrown when trying to create/send broadcast with empty recipient list
class EmptyRecipientListException extends BroadcastException {
  const EmptyRecipientListException([
    String message = 'Broadcast list must have at least one recipient',
  ]) : super(message);
}

/// Thrown when broadcast message sending fails
class BroadcastSendFailedException extends BroadcastException {
  const BroadcastSendFailedException([
    String message = 'Failed to send broadcast message',
  ]) : super(message);
}

/// Thrown when user doesn't have permission for broadcast operation
class BroadcastPermissionException extends BroadcastException {
  const BroadcastPermissionException([
    String message = 'You do not have permission to perform this action',
  ]) : super(message);
}

/// Thrown when broadcast list name is invalid
class InvalidBroadcastNameException extends BroadcastException {
  const InvalidBroadcastNameException([
    String message = 'Broadcast list name cannot be empty',
  ]) : super(message);
}

/// Thrown when recipient is not found in profiles
class RecipientNotFoundException extends BroadcastException {
  const RecipientNotFoundException([
    String message = 'One or more recipients not found',
  ]) : super(message);
}

/// Thrown when trying to add duplicate recipient
class DuplicateRecipientException extends BroadcastException {
  const DuplicateRecipientException([
    String message = 'Recipient already exists in this list',
  ]) : super(message);
}

/// Thrown when network error occurs
class BroadcastNetworkException extends BroadcastException {
  const BroadcastNetworkException([
    String message = 'Network error. Please check your connection.',
  ]) : super(message);
}

/// Thrown for unknown broadcast errors
class UnknownBroadcastException extends BroadcastException {
  const UnknownBroadcastException([
    String message = 'An unexpected error occurred',
  ]) : super(message);
}
