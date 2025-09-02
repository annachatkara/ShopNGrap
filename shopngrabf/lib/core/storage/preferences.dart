// Shared preferences wrappers
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class Preferences {
  static final Preferences _instance = Preferences._internal();
  factory Preferences() => _instance;
  Preferences._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('Preferences not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // Theme mode
  Future<void> setThemeMode(String themeMode) async {
    await prefs.setString(AppConfig.themeKey, themeMode);
  }

  String getThemeMode() {
    return prefs.getString(AppConfig.themeKey) ?? 'system';
  }

  // Language
  Future<void> setLanguage(String languageCode) async {
    await prefs.setString(AppConfig.languageKey, languageCode);
  }

  String getLanguage() {
    return prefs.getString(AppConfig.languageKey) ?? 'en';
  }

  // Onboarding completion
  Future<void> setOnboardingCompleted(bool completed) async {
    await prefs.setBool(AppConfig.onboardingKey, completed);
  }

  bool isOnboardingCompleted() {
    return prefs.getBool(AppConfig.onboardingKey) ?? false;
  }

  // First launch
  Future<void> setFirstLaunch(bool isFirst) async {
    await prefs.setBool('first_launch', isFirst);
  }

  bool isFirstLaunch() {
    return prefs.getBool('first_launch') ?? true;
  }

  // Notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await prefs.setBool('notifications_enabled', enabled);
  }

  bool areNotificationsEnabled() {
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Push notifications enabled
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await prefs.setBool('push_notifications_enabled', enabled);
  }

  bool arePushNotificationsEnabled() {
    return prefs.getBool('push_notifications_enabled') ?? true;
  }

  // Email notifications enabled
  Future<void> setEmailNotificationsEnabled(bool enabled) async {
    await prefs.setBool('email_notifications_enabled', enabled);
  }

  bool areEmailNotificationsEnabled() {
    return prefs.getBool('email_notifications_enabled') ?? true;
  }

  // SMS notifications enabled
  Future<void> setSmsNotificationsEnabled(bool enabled) async {
    await prefs.setBool('sms_notifications_enabled', enabled);
  }

  bool areSmsNotificationsEnabled() {
    return prefs.getBool('sms_notifications_enabled') ?? false;
  }

  // Auto-sync enabled
  Future<void> setAutoSyncEnabled(bool enabled) async {
    await prefs.setBool('auto_sync_enabled', enabled);
  }

  bool isAutoSyncEnabled() {
    return prefs.getBool('auto_sync_enabled') ?? true;
  }

  // Wi-Fi only sync
  Future<void> setWifiOnlySync(bool enabled) async {
    await prefs.setBool('wifi_only_sync', enabled);
  }

  bool isWifiOnlySync() {
    return prefs.getBool('wifi_only_sync') ?? false;
  }

  // Cache images
  Future<void> setCacheImages(bool enabled) async {
    await prefs.setBool('cache_images', enabled);
  }

  bool shouldCacheImages() {
    return prefs.getBool('cache_images') ?? true;
  }

  // Analytics enabled
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await prefs.setBool('analytics_enabled', enabled);
  }

  bool isAnalyticsEnabled() {
    return prefs.getBool('analytics_enabled') ?? true;
  }

  // Crash reporting enabled
  Future<void> setCrashReportingEnabled(bool enabled) async {
    await prefs.setBool('crash_reporting_enabled', enabled);
  }

  bool isCrashReportingEnabled() {
    return prefs.getBool('crash_reporting_enabled') ?? true;
  }

  // Search history
  Future<void> addSearchHistory(String query) async {
    final history = getSearchHistory();
    history.remove(query); // Remove if already exists
    history.insert(0, query); // Add to beginning
    
    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    await prefs.setStringList('search_history', history);
  }

  List<String> getSearchHistory() {
    return prefs.getStringList('search_history') ?? [];
  }

  Future<void> clearSearchHistory() async {
    await prefs.remove('search_history');
  }

  // Recently viewed products
  Future<void> addRecentlyViewed(int productId) async {
    final recent = getRecentlyViewed();
    recent.remove(productId.toString()); // Remove if already exists
    recent.insert(0, productId.toString()); // Add to beginning
    
    // Keep only last 20 products
    if (recent.length > 20) {
      recent.removeRange(20, recent.length);
    }
    
    await prefs.setStringList('recently_viewed', recent);
  }

  List<int> getRecentlyViewed() {
    final strings = prefs.getStringList('recently_viewed') ?? [];
    return strings.map((s) => int.tryParse(s)).where((id) => id != null).cast<int>().toList();
  }

  Future<void> clearRecentlyViewed() async {
    await prefs.remove('recently_viewed');
  }

  // App rating
  Future<void> setAppRated(bool rated) async {
    await prefs.setBool('app_rated', rated);
  }

  bool isAppRated() {
    return prefs.getBool('app_rated') ?? false;
  }

  // App launch count
  Future<void> incrementLaunchCount() async {
    final count = getLaunchCount();
    await prefs.setInt('launch_count', count + 1);
  }

  int getLaunchCount() {
    return prefs.getInt('launch_count') ?? 0;
  }

  // Last app version
  Future<void> setLastAppVersion(String version) async {
    await prefs.setString('last_app_version', version);
  }

  String? getLastAppVersion() {
    return prefs.getString('last_app_version');
  }

  // Currency preference
  Future<void> setCurrency(String currency) async {
    await prefs.setString('currency', currency);
  }

  String getCurrency() {
    return prefs.getString('currency') ?? 'INR';
  }

  // Default address ID
  Future<void> setDefaultAddressId(int addressId) async {
    await prefs.setInt('default_address_id', addressId);
  }

  int? getDefaultAddressId() {
    return prefs.getInt('default_address_id');
  }

  Future<void> removeDefaultAddressId() async {
    await prefs.remove('default_address_id');
  }

  // Cart reminder
  Future<void> setCartReminderTime(DateTime time) async {
    await prefs.setInt('cart_reminder_time', time.millisecondsSinceEpoch);
  }

  DateTime? getCartReminderTime() {
    final time = prefs.getInt('cart_reminder_time');
    return time != null ? DateTime.fromMillisecondsSinceEpoch(time) : null;
  }

  // Wishlist reminder
  Future<void> setWishlistReminderEnabled(bool enabled) async {
    await prefs.setBool('wishlist_reminder_enabled', enabled);
  }

  bool isWishlistReminderEnabled() {
    return prefs.getBool('wishlist_reminder_enabled') ?? true;
  }

  // Filter preferences
  Future<void> setSortPreference(String sortBy) async {
    await prefs.setString('sort_preference', sortBy);
  }

  String getSortPreference() {
    return prefs.getString('sort_preference') ?? 'newest';
  }

  Future<void> setPriceRangeFilter(double min, double max) async {
    await prefs.setDouble('price_min', min);
    await prefs.setDouble('price_max', max);
  }

  Map<String, double> getPriceRangeFilter() {
    return {
      'min': prefs.getDouble('price_min') ?? 0.0,
      'max': prefs.getDouble('price_max') ?? 100000.0,
    };
  }

  // Performance settings
  Future<void> setImageQuality(String quality) async {
    await prefs.setString('image_quality', quality);
  }

  String getImageQuality() {
    return prefs.getString('image_quality') ?? 'high';
  }

  // Debug settings
  Future<void> setDebugMode(bool enabled) async {
    await prefs.setBool('debug_mode', enabled);
  }

  bool isDebugMode() {
    return prefs.getBool('debug_mode') ?? AppConfig.isDevelopment;
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await prefs.clear();
  }

  // Get all preferences (for debugging)
  Set<String> getAllKeys() {
    return prefs.getKeys();
  }

  // Custom preferences
  Future<void> setCustomString(String key, String value) async {
    await prefs.setString(key, value);
  }

  String? getCustomString(String key) {
    return prefs.getString(key);
  }

  Future<void> setCustomInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  int? getCustomInt(String key) {
    return prefs.getInt(key);
  }

  Future<void> setCustomBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  bool? getCustomBool(String key) {
    return prefs.getBool(key);
  }

  Future<void> setCustomDouble(String key, double value) async {
    await prefs.setDouble(key, value);
  }

  double? getCustomDouble(String key) {
    return prefs.getDouble(key);
  }

  Future<void> removeCustom(String key) async {
    await prefs.remove(key);
  }
}
