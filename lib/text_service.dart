import 'package:papa_pro_vision/enums.dart';

class TextService {
    static const Map<String, String> inputLanguageToCommunicationLanguage = {
      'en_IN': 'English',
      'mr_IN': 'Marathi',
    };

    String getPromptText(String inputLanguage, InteractionMode? mode) {
      switch (mode) {
        case InteractionMode.smartReading:
          switch (inputLanguage) {
            case 'mr_IN':
              return "चित्रातील मजकूर वाचा. मजकूर अपुरा दिसत असेल तर कॅमेरा कसा हलवायचा ते मला सांगा.";
            default:
              return "Read the text in the image. If the text appears cut off, let me know how to adjust the camera for a better view";
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

    String getSmartReaderText(String inputLanguage, bool isStart){
      switch(inputLanguage){
        case 'mr_IN':
          return 'स्मार्ट रीडर मोड ${isStart ? 'सुरु' : 'बंद'}';
        default:
          return 'Smart Reading Mode ${isStart ? 'Enabled' : 'Disabled'}';
      }
    }

    String getAutoReaderText(String inputLanguage, bool isStart){
      switch(inputLanguage){
        case 'mr_IN':
          return 'ऑटो रीडर मोड ${isStart ? 'सुरु' : 'बंद'}';
        default:
          return 'Auto Reading Mode ${isStart ? 'Enabled' : 'Disabled'}';
      }
    }
}