import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Setting<T> {
  final String key;
  final T defaultValue;
  T value;
  _Setting({
    required this.key,
    required this.defaultValue,
    required this.value,
  });
}

class SettingsProvider extends ChangeNotifier {
  late final Map<String, _Setting> _settings;

  SettingsProvider() {
    _settings = {
      'dark_mode': _Setting(
        key: 'dark_mode',
        defaultValue: false,
        value: false,
      ),
      'negative_stock': _Setting(
        key: 'negative_stock',
        defaultValue: false,
        value: false,
      ),
      'decimal_places': _Setting(
        key: 'decimal_places',
        defaultValue: 2,
        value: 2,
      ),
      'voice_announce': _Setting(
        key: 'voice_announce',
        defaultValue: false,
        value: false,
      ),
      'paper_type': _Setting(
        key: 'paper_type',
        defaultValue: 'A4',
        value: 'A4',
      ),
      'shop_name': _Setting(key: 'shop_name', defaultValue: '', value: ''),
      'shop_phone': _Setting(key: 'shop_phone', defaultValue: '', value: ''),
      'shop_address': _Setting(
        key: 'shop_address',
        defaultValue: '',
        value: '',
      ),
      'bank_account': _Setting(
        key: 'bank_account',
        defaultValue: '',
        value: '',
      ),
      'footer_text': _Setting(
        key: 'footer_text',
        defaultValue: '感谢您的惠顾，请妥善保管此单据',
        value: '感谢您的惠顾，请妥善保管此单据',
      ),
      'webdav_url': _Setting(key: 'webdav_url', defaultValue: '', value: ''),
      'webdav_user': _Setting(key: 'webdav_user', defaultValue: '', value: ''),
      'webdav_password': _Setting(
        key: 'webdav_password',
        defaultValue: '',
        value: '',
      ),
      'auto_backup': _Setting(
        key: 'auto_backup',
        defaultValue: false,
        value: false,
      ),
      'backup_frequency': _Setting(
        key: 'backup_frequency',
        defaultValue: 'daily',
        value: 'daily',
      ),
      'print_template': _Setting(
        key: 'print_template',
        defaultValue: 'default',
        value: 'default',
      ),
      'triple_form_enabled': _Setting(
        key: 'triple_form_enabled',
        defaultValue: true,
        value: true,
      ),
      'triple_form_mode': _Setting(
        key: 'triple_form_mode',
        defaultValue: 'continuous',
        value: 'continuous',
      ),
    };
  }

  List<int> _tripleFormCopies = [0, 1, 2];

  bool get darkMode => _settings['dark_mode']!.value;
  bool get negativeStock => _settings['negative_stock']!.value;
  int get decimalPlaces => _settings['decimal_places']!.value;
  bool get voiceAnnounce => _settings['voice_announce']!.value;
  String get paperType => _settings['paper_type']!.value;
  String get shopName => _settings['shop_name']!.value;
  String get shopPhone => _settings['shop_phone']!.value;
  String get shopAddress => _settings['shop_address']!.value;
  String get bankAccount => _settings['bank_account']!.value;
  String get footerText => _settings['footer_text']!.value;
  String get webdavUrl => _settings['webdav_url']!.value;
  String get webdavUser => _settings['webdav_user']!.value;
  String get webdavPassword => _settings['webdav_password']!.value;
  bool get autoBackup => _settings['auto_backup']!.value;
  String get backupFrequency => _settings['backup_frequency']!.value;
  String get printTemplate => _settings['print_template']!.value;
  bool get tripleFormEnabled => _settings['triple_form_enabled']!.value;
  List<int> get tripleFormCopies => _tripleFormCopies;
  String get tripleFormMode => _settings['triple_form_mode']!.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _settings.forEach((key, setting) {
      if (setting is _Setting<bool>) {
        setting.value = prefs.getBool(key) ?? setting.defaultValue;
      } else if (setting is _Setting<int>) {
        setting.value = prefs.getInt(key) ?? setting.defaultValue;
      } else if (setting is _Setting<String>) {
        setting.value = prefs.getString(key) ?? setting.defaultValue;
      }
    });
    _tripleFormCopies =
        (prefs.getStringList('triple_form_copies') ?? ['0', '1', '2'])
            .map(int.parse)
            .toList();
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

  Future<void> _saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  Future<void> _set<T>(String key, T value) async {
    _settings[key]!.value = value;
    await _save(key, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) => _set<bool>('dark_mode', v);
  Future<void> setNegativeStock(bool v) => _set<bool>('negative_stock', v);
  Future<void> setDecimalPlaces(int v) => _set<int>('decimal_places', v);
  Future<void> setVoiceAnnounce(bool v) => _set<bool>('voice_announce', v);
  Future<void> setPaperType(String v) => _set<String>('paper_type', v);
  Future<void> setShopName(String v) => _set<String>('shop_name', v);
  Future<void> setShopPhone(String v) => _set<String>('shop_phone', v);
  Future<void> setShopAddress(String v) => _set<String>('shop_address', v);
  Future<void> setBankAccount(String v) => _set<String>('bank_account', v);
  Future<void> setFooterText(String v) => _set<String>('footer_text', v);
  Future<void> setWebdavUrl(String v) => _set<String>('webdav_url', v);
  Future<void> setWebdavUser(String v) => _set<String>('webdav_user', v);
  Future<void> setWebdavPassword(String v) =>
      _set<String>('webdav_password', v);
  Future<void> setAutoBackup(bool v) => _set<bool>('auto_backup', v);
  Future<void> setBackupFrequency(String v) =>
      _set<String>('backup_frequency', v);
  Future<void> setPrintTemplate(String v) => _set<String>('print_template', v);
  Future<void> setTripleFormEnabled(bool v) =>
      _set<bool>('triple_form_enabled', v);
  Future<void> setTripleFormCopies(List<int> v) async {
    _tripleFormCopies = v;
    await _saveStringList(
      'triple_form_copies',
      v.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> setTripleFormMode(String v) =>
      _set<String>('triple_form_mode', v);
}
