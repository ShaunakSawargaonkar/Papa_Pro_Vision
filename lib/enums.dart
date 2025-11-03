enum ConversationState {
  idle, // waiting for user
  listening, // recording user input
  processing, // playing TTS audio and processing via gemini
  speaking, // playing TTS audio
  videoRecording, // recording video
  failed, // error occurred while setting up speech understanding
}

enum InteractionMode { normal, smartView, autoReading, video }

enum UserType {single, organization }


enum UserStatus {
  errorState,  // contact support
  notRegistered, // continue to registration process
  firstPaymentPending, // continue to first payment process
  paymentPending, // continue to payment process
  active, // continue to home screen
}