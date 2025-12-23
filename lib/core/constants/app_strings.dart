class AppStrings {
  // Prevent instantiation
  const AppStrings._();

  static const String signUpTitle = 'Create Account';
  static const String signUpSubtitle = 'Sign up to get started';

  static const String nameLabel = 'Full Name';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';

  static const String signUpButton = 'Sign Up';

  static const String successMessage = 'Sign Up Successful!';

  // Validation Messages
  static const String nameRequired = 'Please enter your name';
  static const String emailRequired = 'Please enter your email';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Please enter a password';
  static const String passwordLength = 'Password must be at least 6 characters';

  // Error fallback
  static const String defaultError = 'Sign up failed';
}
