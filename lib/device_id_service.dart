import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const String _key = "device_uuid";

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_key);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_key, deviceId);
    }

    return deviceId;
  }
}
