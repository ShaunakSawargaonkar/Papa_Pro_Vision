enum ConversationState {
  idle, // waiting for user
  listening, // recording user input
  processing, // playing TTS audio and processing via gemini
  speaking, // playing TTS audio
  failed, // error occurred while setting up speech understanding
}

enum InteractionMode { normal, smartView, autoReading }
