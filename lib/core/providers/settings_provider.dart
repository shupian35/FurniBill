import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  bool _negativeStock = false;
  int _decimalPlaces = 2;
  bool _voiceAnnounce = false;
  String _paperType = 'A4';
  String _shopName = '';
  String _shopPhone = '';
  String _shopAddress = '';
  bool _showRetailPrice = false;
  bool _showCostPrice = false;
  String _footerText = '感谢您的惠顾，请妥善保管此单据';

  // WebDAV
  String _webdavUrl = '';
  String _webdavUser = '';
  String _webdavPassword = '';
  bool _autoBackup = false;
  String _backupFrequency = 'daily'; // daily, weekly

  bool get darkMode => _darkMode;
  bool get negativeStock => _negativeStock;
  int get decimalPlaces => _decimalPlaces;
  bool get voiceAnnounce => _voiceAnnounce;
  String get paperType => _paperType;
  String get shopName => _shopName;
  String get shopPhone => _shopPhone;
  String get shopAddress => _shopAddress;
  bool get showRetailPrice => _showRetailPrice;
  bool get showCostPrice => _showCostPrice;
  String get footerText => _footerText;
  String get webdavUrl => _webdavUrl;
  String get webdavUser => _webdavUser;
  String get webdavPassword => _webdavPassword;
  bool get autoBackup => _autoBackup;
  String get backupFrequency => _backupFrequency;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _negativeStock = prefs.getBool('negative_stock') ?? false;
    _decimalPlaces = prefs.getInt('decimal_places') ?? 2;
    _voiceAnnounce = prefs.getBool('voice_announce') ?? false;
    _paperType = prefs.getString('paper_type') ?? 'A4';
    _shopName = prefs.getString('shop_name') ?? '';
    _shopPhone = prefs.getString('shop_phone') ?? '';
    _shopAddress = prefs.getString('shop_address') ?? '';
    _showRetailPrice = prefs.getBool('show_retail_price') ?? false;
    _showCostPrice = prefs.getBool('show_cost_price') ?? false;
    _footerText = prefs.getString('footer_text') ?? '感谢您的惠顾，请妥善保管此单据';
    _webdavUrl = prefs.getString('webdav_url') ?? '';
    _webdavUser = prefs.getString('webdav_user') ?? '';
    _webdavPassword = prefs.getString('webdav_password') ?? '';
    _autoBackup = prefs.getBool('auto_backup') ?? false;
    _backupFrequency = prefs.getString('backup_frequency') ?? 'daily';
    notifyListeners();
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> setDarkMode(bool v) async { _darkMode = v; await _save('dark_mode', v); notifyListeners(); }
  Future<void> setNegativeStock(bool v) async { _negativeStock = v; await _save('negative_stock', v); notifyListeners(); }
  Future<void> setDecimalPlaces(int v) async { _decimalPlaces = v; await _save('decimal_places', v); notifyListeners(); }
  Future<void> setVoiceAnnounce(bool v) async { _voiceAnnounce = v; await _save('voice_announce', v); notifyListeners(); }
  Future<void> setPaperType(String v) async { _paperType = v; await _save('paper_type', v); notifyListeners(); }
  Future<void> setShopName(String v) async { _shopName = v; await _save('shop_name', v); notifyListeners(); }
  Future<void> setShopPhone(String v) async { _shopPhone = v; await _save('shop_phone', v); notifyListeners(); }
  Future<void> setShopAddress(String v) async { _shopAddress = v; await _save('shop_address', v); notifyListeners(); }
  Future<void> setShowRetailPrice(bool v) async { _showRetailPrice = v; await _save('show_retail_price', v); notifyListeners(); }
  Future<void> setShowCostPrice(bool v) async { _showCostPrice = v; await _save('show_cost_price', v); notifyListeners(); }
  Future<void> setFooterText(String v) async { _footerText = v; await _save('footer_text', v); notifyListeners(); }
  Future<void> setWebdavUrl(String v) async { _webdavUrl = v; await _save('webdav_url', v); notifyListeners(); }
  Future<void> setWebdavUser(String v) async { _webdavUser = v; await _save('webdav_user', v); notifyListeners(); }
  Future<void> setWebdavPassword(String v) async { _webdavPassword = v; await _save('webdav_password', v); notifyListeners(); }
  Future<void> setAutoBackup(bool v) async { _autoBackup = v; await _save('auto_backup', v); notifyListeners(); }
  Future<void> setBackupFrequency(String v) async { _backupFrequency = v; await _save('backup_frequency', v); notifyListeners(); }
}
