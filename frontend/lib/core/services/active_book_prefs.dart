import 'package:shared_preferences/shared_preferences.dart';

class ActiveBookPrefs {
  static const activeBookIdKey = 'active_book_id';

  static Future<void> saveActiveBookId(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeBookIdKey, bookId);
  }

  static Future<String?> loadActiveBookId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(activeBookIdKey);
  }
}
