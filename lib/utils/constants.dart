class AppConstants {
  // App Info
  static const String appName = 'TravelConnect';
  static const String appVersion = '1.0.0';

  // Colors
  static const primaryColor = 0xFF2196F3;
  static const accentColor = 0xFF03A9F4;

  // Validation
  static const int minDescriptionLength = 50;
  static const int maxDescriptionLength = 500;
  static const int minReviewLength = 50;
  static const int maxReviewLength = 500;
  static const int maxMessageLength = 1000;

  // Storage Paths
  static const String profileImagesPath = 'profile_images';

  // Error Messages
  static const String networkError = 'Network error. Please try again.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String authError = 'Authentication failed. Please try again.';
}