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
            return "चित्रातील मजकूर वाचा. मजकूर अपुरा दिसत असेल तर कॅमेरा कसा हलवायचा ते मला सांगा.";
          default:
            return "Read the text in the image. If the text appears cut off, let me know how to adjust the camera for a better view";
          //Shrini TODO
          // return """You are an AI assistant helping blind users understand images.
          //  Start with a 3-4 line overview, then provide detailed descriptions.
          //  If the image contains predominantly text, read it clearly. If text or image is unclear,
          //   suggest camera adjustments.""";

          // return """तुम्ही आंधळ्या वापरकर्त्यांना चित्र समजावून सांगणारे AI सहाय्यक आहात.
          //  प्रथम ३-४ ओळींत चित्राचा सारांश द्या, नंतर तपशीलवार वर्णन करा.
          //  जर चित्रात मुख्यतः मजकूर असेल तर तो स्पष्टपणे वाचा. मजकूर किंवा चित्र अस्पष्ट असेल तर,
          //  कॅमेरा कसा समायोजित करावा याचे सूचन द्या.""";
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
    switch (inputLanguage) {
      case 'mr_IN':
        return "कृपया प्रतीक्षा करा. विचार करतोय";
      default:
        return "Please wait. Thinking";
    }
  }

  String getSmartViewText(String inputLanguage, bool isStart) {
    switch (inputLanguage) {
      case 'mr_IN':
        return 'स्मार्ट व्ह्यू मोड ';
      default:
        return 'Smart View Mode }';
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
