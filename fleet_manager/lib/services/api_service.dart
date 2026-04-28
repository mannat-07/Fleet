import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Central HTTP service. Update [baseUrl] to match your deployment.
/// Android emulator  → http://10.0.2.2:3000/api
/// iOS sim / web     → http://localhost:3000/api
class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Generic helpers ──────────────────────────────────────────────────────────

  static Future<dynamic> _get(String path) async {
    final headers = await _headers();
    final response = await http
        .get(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true) return body['data'];
      throw ApiException(body['message'] ?? 'Request failed');
    }
    if (response.statusCode == 404) return null;
    throw ApiException('HTTP ${response.statusCode}');
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final b = json.decode(response.body);
      if (b['success'] == true) return b['data'];
      throw ApiException(b['message'] ?? 'Request failed');
    }
    final b = json.decode(response.body);
    throw ApiException(b['message'] ?? 'HTTP ${response.statusCode}');
  }

  static Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final b = json.decode(response.body);
      if (b['success'] == true) return b['data'];
      throw ApiException(b['message'] ?? 'Request failed');
    }
    final b = json.decode(response.body);
    throw ApiException(b['message'] ?? 'HTTP ${response.statusCode}');
  }

  static Future<void> _delete(String path) async {
    final headers = await _headers();
    final response = await http
        .delete(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      final b = json.decode(response.body);
      throw ApiException(b['message'] ?? 'HTTP ${response.statusCode}');
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      return (await _get('/auth/profile')) as Map<String, dynamic>?;
    } catch (e) {
      throw ApiException('Failed to load profile: $e');
    }
  }

  // ── Trucks ───────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTrucks({String? status}) async {
    try {
      final path = status != null ? '/trucks?status=$status' : '/trucks';
      final data = await _get(path);
      if (data == null) return [];
      return ((data as Map)['trucks'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load trucks: $e');
    }
  }

  static Future<Map<String, dynamic>> addTruck(
    Map<String, dynamic> body,
  ) async {
    try {
      return (await _post('/trucks', body)) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to add truck: $e');
    }
  }

  static Future<void> deleteTruck(String truckId) async {
    try {
      await _delete('/trucks/$truckId');
    } catch (e) {
      throw ApiException('Failed to delete truck: $e');
    }
  }

  static Future<void> updateTruckStatus(String truckId, String status) async {
    try {
      await _patch('/trucks/$truckId/status', {'status': status});
    } catch (e) {
      throw ApiException('Failed to update truck: $e');
    }
  }

  // ── Drivers ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDrivers({String? status}) async {
    try {
      final path = status != null ? '/drivers?status=$status' : '/drivers';
      final data = await _get(path);
      if (data == null) return [];
      return ((data as Map)['drivers'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load drivers: $e');
    }
  }

  static Future<Map<String, dynamic>> addDriver(
    Map<String, dynamic> body,
  ) async {
    try {
      return (await _post('/drivers', body)) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to add driver: $e');
    }
  }

  static Future<void> deleteDriver(String driverId) async {
    try {
      await _delete('/drivers/$driverId');
    } catch (e) {
      throw ApiException('Failed to delete driver: $e');
    }
  }

  // ── Insurance ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getInsuranceRecords() async {
    try {
      final data = await _get('/insurance');
      if (data == null) return [];
      return ((data as Map)['insurance'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load insurance records: $e');
    }
  }

  static Future<Map<String, dynamic>> addInsuranceRecord(
    Map<String, dynamic> body,
  ) async {
    try {
      return (await _post('/insurance', body)) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to add insurance record: $e');
    }
  }

  static Future<Map<String, dynamic>> updateInsuranceRecord(
    String insuranceId,
    Map<String, dynamic> body,
  ) async {
    try {
      return (await _patch('/insurance/$insuranceId', body)) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to update insurance record: $e');
    }
  }

  static Future<void> deleteInsuranceRecord(String insuranceId) async {
    try {
      await _delete('/insurance/$insuranceId');
    } catch (e) {
      throw ApiException('Failed to delete insurance record: $e');
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final data = await _get('/notifications');
      if (data == null) return {'notifications': [], 'count': 0};
      return data as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to load notifications: $e');
    }
  }

  // ── Convenience filters ───────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getIdleTrucks() async {
    return getTrucks(status: 'idle');
  }

  static Future<List<Map<String, dynamic>>> getAvailableDrivers() async {
    return getDrivers(status: 'available');
  }

  // ── ESP32 Sensor Proxy ────────────────────────────────────────────────────

  /// Fetches live ESP32 sensor data via the backend proxy.
  /// The backend must be running on a PC connected to the ESP32 "TruckSystem" WiFi.
  static Future<Map<String, dynamic>> getEsp32Data() async {
    try {
      final data = await _get('/esp32/data');
      if (data == null) throw ApiException('No data from ESP32');
      return data as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('ESP32 data unavailable: $e');
    }
  }

  static Future<bool> checkEsp32Status() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/esp32/status'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final b = json.decode(response.body);
        return b['data']?['reachable'] == true || b['reachable'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getFleetSummary() async {
    try {
      return (await _get('/fleet/summary')) as Map<String, dynamic>?;
    } catch (e) {
      throw ApiException('Failed to load summary: $e');
    }
  }

  static Future<Map<String, dynamic>?> getEarnings({
    String period = 'weekly',
  }) async {
    try {
      return (await _get('/fleet/earnings?period=$period'))
          as Map<String, dynamic>?;
    } catch (e) {
      throw ApiException('Failed to load earnings: $e');
    }
  }

  // ── Driver role ──────────────────────────────────────────────────────────────

  /// Single call: returns { driver, truck, sensor }
  static Future<Map<String, dynamic>?> getDriverMe() async {
    try {
      return (await _get('/drivers/me')) as Map<String, dynamic>?;
    } catch (e) {
      throw ApiException('Failed to load driver data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getLatestSensorData(
    String truckId,
  ) async {
    try {
      final data = await _get('/iot/trucks/$truckId/latest');
      if (data == null) return null;
      final map = data as Map<String, dynamic>;
      return map.isEmpty ? null : map;
    } catch (e) {
      throw ApiException('Failed to load sensor data: $e');
    }
  }

  // ── Organization role ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getActiveTrucks() async {
    try {
      final data = await _get('/fleet/active-trucks');
      if (data == null) return [];
      return ((data as Map)['trucks'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiException('Failed to load active trucks: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllTrucks() async {
    return getTrucks();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
