import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileLocalStore {
  final String accountKey;

  const ProfileLocalStore(this.accountKey);

  String get _prefix => 'bc_profile.${accountKey.trim().toLowerCase()}';

  String get _phoneKey => '$_prefix.phone';

  String get _photoKey => '$_prefix.photo';

  Future<String?> loadPhone() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_phoneKey);
  }

  Future<void> savePhone(String phone) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_phoneKey, phone.trim());
  }

  Future<Uint8List?> loadPhoto() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_photoKey);

    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePhoto(Uint8List bytes) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_photoKey, base64Encode(bytes));
  }
}
