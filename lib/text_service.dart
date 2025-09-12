import 'package:papa_pro_vision/enums.dart';

class TextService {
  static const Map<String, String> inputLanguageToCommunicationLanguage = {
    'en_IN': 'English',
    'mr_IN': 'Marathi',
  };

  String getPromptText(String inputLanguage, InteractionMode? mode) {
    switch (mode) {
      case InteractionMode.smartView:
        switch (inputLanguage) {
          case 'mr_IN':
            return "प्रतिमेत तुम्हाला काय दिसते ते वर्णन करा. प्रतिमा मुख्यतः मजकूराची असेल तर तो स्पष्टपणे वाचा. मजकूर किंवा प्रतिमा अस्पष्ट दिसत असेल तर कॅमेरा कसा समायोजित करावा हे सुचवा.";
          default:
            return "Describe what you see in the image. If the image is predominantly text, read it clearly. If text or image is unclear, suggest camera adjustments.";
        }
      case InteractionMode.autoReading:
        switch (inputLanguage) {
          case 'mr_IN':
            return "चित्रातील मजकूर वाचा.";
          default:
            return "Read the text in the image.";
        }
      default:
        switch (inputLanguage) {
          case 'mr_IN':
            return "तुम्हाला या चित्रात काय दिसते? आंधळ्या व्यक्तीसाठी त्याचे वर्णन करा.";
          default:
            return "What do you see in the image? Describe it for a blind person";
        }
    }
  }

  String getProcessingResponseText(String inputLanguage) {
    return "Processing response";
  }

  String getSmartViewText(String inputLanguage, bool isStart) {
    switch (inputLanguage) {
      case 'mr_IN':
        return 'प्रोसेसिंग स्मार्ट व्ह्यू ';
      default:
        return 'Processing Smart View ';
    }
  }

  String getAutoReaderText(String inputLanguage, bool isStart) {
    switch (inputLanguage) {
      case 'mr_IN':
        return 'रीडर मोड ';
      default:
        return 'Reading Mode ';
    }
  }
}
