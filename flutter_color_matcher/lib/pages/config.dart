class AppConfig {
  static const String appName = 'Color Matcher Pro';
  static const String version = '1.0.0';
  
  // APIs
  static const String geminiModel = 'gemini-pro';
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Local Storage Keys
  static const String authKey = 'isAuth';
  static const String themeKey = 'isDarkMode';
  static const String historyKey = 'searchHistory';
}
