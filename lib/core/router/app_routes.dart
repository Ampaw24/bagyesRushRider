abstract final class AppRoutes {
  static const splash = '/';
  static const intro = '/intro';
  static const login = '/login';
  static const signup = '/signup';
  static const otp = '/otp';
  /// Forgot password: the phone step is `ForgotPasswordSheet` on the login
  /// screen; these are the two screens that follow it.
  static const forgotPasswordOtp = '/forgot-password/verify';
  static const resetPassword = '/forgot-password/reset';
  static const vehicleInfo = '/vehicle-info';
  static const vehicleDetails = '/vehicle-details';
  static const termsAndConditions = '/terms-and-conditions';
  static const dashboard = '/dashboard';
  static const editProfile = '/dashboard/profile/edit';
  static const notifications = '/dashboard/notifications';
  static const settings = '/dashboard/settings';
  /// Profile verification checklist, driven by `/rider/me`.
  static const kyc = '/dashboard/kyc';

  /// One checklist step, by `KycSection.slug`.
  static String kycSection(String slug) => '$kyc/$slug';
}
