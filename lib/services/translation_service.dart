class TranslationService {
  // Simple Luganda to English dictionary for common shop terms
  static final Map<String, String> lugandaToEnglish = {
    // Common transaction words
    'nsigadde': 'sold',
    'bintu': 'items',
    'musaayi': 'sold',
    'kintu': 'item',
    'nfunye': 'received',
    'yakuba': 'gave',
    'kusigala': 'remain',
    'kugula': 'buy',
    'kweyuza': 'sell',
    'ensimbi': 'money',
    'ennyumba': 'house',
    
    // Common items
    'buki': 'book',
    'mmere': 'food',
    'm亚特': 'meat',
    'ekyapa': 'soap',
    'kisindi': 'bag',
    'ebikole': 'school fees',
    'ebiri kugula': 'things I bought',
    'kunsanze': 'market',
    
    // Amounts
    'shilingi': 'shillings',
    'maka': 'thousand',
    'ffe': 'money',
  };

  static String translateToEnglish(String lugandaText) {
    String translated = lugandaText;
    
    // Replace Luganda words with English equivalents
    lugandaToEnglish.forEach((lug, eng) {
      translated = translated.replaceAll(lug, eng);
    });
    
    return translated;
  }

  static String translateToLuganda(String englishText) {
    String translated = englishText;
    
    // Reverse translation
    lugandaToEnglish.forEach((lug, eng) {
      translated = translated.replaceAll(eng, lug);
    });
    
    return translated;
  }

  // Detect if text is likely Luganda
  static bool isLuganda(String text) {
    String lowerText = text.toLowerCase();
    
    // Check for common Luganda words
    List<String> lugandaIndicators = [
      'nsigadde', 'bintu', 'musaayi', 'kintu', 'nfunye', 
      'yakuba', 'kusigala', 'kugula', 'kweyuza', 'enyumba',
      'shilingi', 'maka', 'ffe', 'kunsanze', 'ekyapa'
    ];
    
    return lugandaIndicators.any((word) => lowerText.contains(word));
  }

  // Process text for NLP (translate if needed)
  static String processText(String input, String targetLanguage) {
    if (targetLanguage == 'lg') {
      // User speaking Luganda, translate to English for NLP
      if (isLuganda(input)) {
        return translateToEnglish(input);
      }
    }
    return input;
  }
}
