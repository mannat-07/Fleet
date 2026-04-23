import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Central HTTP service. Update [baseUrl] to match your deployment.
/// Android emulator  → http://10.0.2.2:3000/api
/// iOS sim / web     → http://localhost:3000/api
class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, String>> _headers() async {
    final user  = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Generic helpers ──────────────────────────────────────────────────────────

  static Future<dynamic> _get(String path) async {
    final headers  = await _headers();
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
    final headers  = await _headers();
    final response = await http
        .post(Uri.parse('$baseUrl$path'),
            headers: headers, body: json.encode(body))
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
    final headers  = await _headers();
    final response = await http
        .patch(Uri.parse('$baseUrl$path'),
            headers: headers, body: json.encode(body))
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
    final headers  = await _headers();
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
    } catch (e) { throw ApiException('Failed to load profile: $e'); }
  }

  // ── Trucks ───────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTrucks() async {
    try {
      final data = await _get('/trucks');
      if (data == null) return [];
      return ((data as Map)['trucks'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) { throw ApiException('Failed to load trucks: $e'); }
  }

  static Future<Map<String, dynamic>> addTruck(Map<String, dynamic> body) async {
    try {
      return (await _post('/trucks', body)) as Map<String, dynamic>;
    } catch (e) { throw ApiException('Failed to add truck: $e'); }
  }

  static Future<void> deleteTruck(String truckId) async {
    try { await _delete('/trucks/$truckId'); }
    catch (e) { throw ApiException('Failed to delete truck: $e'); }
  }

  static Future<void> updateTruckStatus(String truckId, String status) async {
    try { await _patch('/trucks/$truckId/status', {'status': status}); }
    catch (e) { throw ApiException('Failed to update truck: $e'); }
  }

  // ── Drivers ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDrivers() async {
    try {
      final data = await _get('/drivers');
      if (data == null) return [];
      return ((data as Map)['drivers'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) { throw ApiException('Failed to load drivers: $e'); }
  }

  static Future<Map<String, dynamic>> addDriver(Map<String, dynamic> body) async {
    try {
      return (await _post('/drivers', body)) as Map<String, dynamic>;
    } catch (e) { throw ApiException('Failed to add driver: $e'); }
  }

  static Future<void> deleteDriver(String driverId) async {
    try { await _delete('/drivers/$driverId'); }
    catch (e) { throw ApiException('Failed to delete driver: $e'); }
  }

  // ── Fleet summary (owner dashboard) ─────────────────────────────────────────

  static Future<Map<String, dynamic>?> getFleetSummary() async {
    try {
      return (await _get('/fleet/summary')) as Map<String, dynamic>?;
    } catch (e) { throw ApiException('Failed to load summary: $e'); }
  }

  static Future<Map<String, dynamic>?> getEarnings({String period = 'weekly'}) async {
    try {
      return (await _get('/fleet/earnings?period=$period')) as Map<String, dynamic>?;
    } catch (e) { throw ApiException('Failed to load earnings: $e'); }
  }

  // ── Driver role ──────────────────────────────────────────────────────────────

  /// Single call: returns { driver, truck, sensor }
  static Future<Map<String, dynamic>?> getDriverMe() async {
    try {
      return (await _get('/drivers/me')) as Map<String, dynamic>?;
    } catch (e) { throw ApiException('Failed to load driver data: $e'); }
  }

  static Future<Map<String, dynamic>?> getLatestSensorData(String truckId) async {
    try {
      final data = await _get('/iot/trucks/$truckId/latest');
      if (data == null) return null;
      final map = data as Map<String, dynamic>;
      return map.isEmpty ? null : map;
    } catch (e) { throw ApiException('Failed to load sensor data: $e'); }
  }

  // ── Organization role ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getActiveTrucks() async {
    try {
      final data = await _get('/fleet/active-trucks');
      if (data == null) return [];
      return ((data as Map)['trucks'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) { throw ApiException('Failed to load active trucks: $e'); }
  }

  static Future<List<Map<String, dynamic>>> getAllTrucks() async {
    try {
      final data = await _get('/trucks');
      if (data == null) return [];
      return ((data as Map)['trucks'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) { throw ApiException('Failed to load trucks: $e'); }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
