/// Central registry for the brand Lottie animations in `assets/lottie/` —
/// the same files the customer/vendor app ships. Play them through
/// `AppStatusAnimation` rather than `Lottie.asset` directly.
class LottieAssets {
  LottieAssets._();

  static const error = 'assets/lottie/error.json';
  static const info = 'assets/lottie/info.json';
  static const processing = 'assets/lottie/processing.json';
  static const searching = 'assets/lottie/searching.json';
  static const success = 'assets/lottie/success.json';
  static const warning = 'assets/lottie/warning.json';
}
