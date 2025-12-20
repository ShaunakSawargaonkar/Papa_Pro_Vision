enum ConversationState {
  idle, // waiting for user
  listening, // recording user input
  processing, // playing TTS audio and processing via gemini
  speaking, // playing TTS audio
  videoRecording, // recording video
  failed, // error occurred while setting up speech understanding
}

enum InteractionMode { normal, smartView, autoReading, video }

enum UserType { single, organization }

enum UserStatus {
  errorState, // contact support
  notRegistered, // continue to registration process
  firstPaymentPending, // continue to first payment process
  paymentPending, // continue to payment process
  active, // continue to home screen
  noInternet, // no internet connection
  apkKilled, // APK version is killed
}

enum SubscriptionBundleType {
  firstMonthFree,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear;

  @override
  String toString() {
    switch (this) {
      case SubscriptionBundleType.firstMonthFree:
        return 'First Month Free';
      case SubscriptionBundleType.oneMonth:
        return '1 Month';
      case SubscriptionBundleType.threeMonths:
        return '3 Months';
      case SubscriptionBundleType.sixMonths:
        return '6 Months';
      case SubscriptionBundleType.oneYear:
        return '1 Year';
      default:
        return name;
    }
  }

  int getDaysDuration() {
    switch (this) {
      case SubscriptionBundleType.firstMonthFree:
        return 30;
      case SubscriptionBundleType.oneMonth:
        return 30;
      case SubscriptionBundleType.threeMonths:
        return 90;
      case SubscriptionBundleType.sixMonths:
        return 180;
      case SubscriptionBundleType.oneYear:
        return 365;
      default:
        return 30;
    }
  }

}

enum SubscriptionTier{
  free,
  paid,
}
