import 'package:intl/intl.dart';

class Helpers {
  // Format timestamp to readable date
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date);
    } else if (difference.inDays < 365) {
      return DateFormat.MMMd().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  // Format timestamp to time
  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  // Format timestamp for messages
  static String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(time);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(time);
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}