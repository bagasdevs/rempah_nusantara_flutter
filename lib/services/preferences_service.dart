import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app preferences using SharedPreferences
class PreferencesService {
  static SharedPreferences? _prefs;

  // Keys
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyPushNotifications = 'push_notifications';
  static const String _keyEmailNotifications = 'email_notifications';
  static const String _keyOrderUpdates = 'order_updates';
  static const String _keyPromotions = 'promotions';
  static const String _keyNewProducts = 'new_products';
  static const String _keyPriceDrops = 'price_drops';
  static const String _keyRestock = 'restock';
  static const String _keyMessages = 'messages';
  static const String _keyReviews = 'reviews';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyFirstLaunch = 'first_launch';

  /// Initialize the preferences service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  static Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ==================== THEME ====================

  /// Get dark mode setting
  static Future<bool> getDarkMode() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  /// Set dark mode setting
  static Future<bool> setDarkMode(bool value) async {
    final prefs = await _getPrefs();
    return prefs.setBool(_keyDarkMode, value);
  }

  // ==================== LANGUAGE ====================

  /// Get language code (default: 'id' for Indonesian)
  static Future<String> getLanguage() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyLanguage) ?? 'id';
  }

  /// Set language code
  static Future<bool> setLanguage(String languageCode) async {
    final prefs = await _getPrefs();
    return prefs.setString(_keyLanguage, languageCode);
  }

  // ==================== NOTIFICATION PREFERENCES ====================

  /// Get all notification preferences
  static Future<Map<String, bool>> getNotificationPreferences() async {
    final prefs = await _getPrefs();
    return {
      'push_notifications': prefs.getBool(_keyPushNotifications) ?? true,
      'email_notifications': prefs.getBool(_keyEmailNotifications) ?? true,
      'order_updates': prefs.getBool(_keyOrderUpdates) ?? true,
      'promotions': prefs.getBool(_keyPromotions) ?? true,
      'new_products': prefs.getBool(_keyNewProducts) ?? false,
      'price_drops': prefs.getBool(_keyPriceDrops) ?? false,
      'restock': prefs.getBool(_keyRestock) ?? true,
      'messages': prefs.getBool(_keyMessages) ?? true,
      'reviews': prefs.getBool(_keyReviews) ?? false,
    };
  }

  /// Set a single notification preference
  static Future<bool> setNotificationPreference(String key, bool value) async {
    final prefs = await _getPrefs();
    final prefKey = _getNotificationKey(key);
    if (prefKey != null) {
      return prefs.setBool(prefKey, value);
    }
    return false;
  }

  /// Set all notification preferences at once
  static Future<void> setAllNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    for (final entry in preferences.entries) {
      await setNotificationPreference(entry.key, entry.value);
    }
  }

  /// Reset notification preferences to defaults
  static Future<void> resetNotificationPreferences() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyPushNotifications, true);
    await prefs.setBool(_keyEmailNotifications, true);
    await prefs.setBool(_keyOrderUpdates, true);
    await prefs.setBool(_keyPromotions, true);
    await prefs.setBool(_keyNewProducts, false);
    await prefs.setBool(_keyPriceDrops, false);
    await prefs.setBool(_keyRestock, true);
    await prefs.setBool(_keyMessages, true);
    await prefs.setBool(_keyReviews, false);
  }

  static String? _getNotificationKey(String key) {
    switch (key) {
      case 'push_notifications':
        return _keyPushNotifications;
      case 'email_notifications':
        return _keyEmailNotifications;
      case 'order_updates':
        return _keyOrderUpdates;
      case 'promotions':
        return _keyPromotions;
      case 'new_products':
        return _keyNewProducts;
      case 'price_drops':
        return _keyPriceDrops;
      case 'restock':
        return _keyRestock;
      case 'messages':
        return _keyMessages;
      case 'reviews':
        return _keyReviews;
      default:
        return null;
    }
  }

  // ==================== APP STATE ====================

  /// Check if onboarding is complete
  static Future<bool> isOnboardingComplete() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  /// Set onboarding as complete
  static Future<bool> setOnboardingComplete(bool value) async {
    final prefs = await _getPrefs();
    return prefs.setBool(_keyOnboardingComplete, value);
  }

  /// Check if this is the first launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await _getPrefs();
    final isFirst = prefs.getBool(_keyFirstLaunch) ?? true;
    if (isFirst) {
      await prefs.setBool(_keyFirstLaunch, false);
    }
    return isFirst;
  }

  // ==================== CLEAR ====================

  /// Clear all preferences (for logout)
  static Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  /// Clear only user-specific preferences (keep app settings)
  static Future<void> clearUserData() async {
    // Keep theme and language settings
    final darkMode = await getDarkMode();
    final language = await getLanguage();

    final prefs = await _getPrefs();
    await prefs.clear();

    // Restore app settings
    await setDarkMode(darkMode);
    await setLanguage(language);
  }
}
