// lib/views/connexion/service/auth_service.dart
//
// AuthService avec DEBUG avancé :
// - Logs colorés/émoticônes (activés seulement en debug build)
// - Masquage email/mot de passe dans les logs
// - Mesure de latence par requête (Stopwatch)
// - Timeout réseau (configurable)
// - Décodage JSON "safe" (tolère les bodies non-JSON)
// - Cache local (token / role / user_json) avec logs
//
// Astuces de lecture dans la console :
// 🔵 Info requête / réponse
// 🟡 Avertissement (ex: body non-JSON)
// 🔴 Erreur (exceptions, 4xx/5xx)
// 🟢 Succès logique (auth OK, cache mis à jour)

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ---- CONFIG GLOBALE ---------------------------------------------------------
const String baseUrl = 'https://varxpro.com';

// Active la verbosité en debug uniquement.
// (Tu peux forcer à true pour investiguer en release, mais évite en prod)
const bool kVerboseAuthLogs = true;

// Timeout réseau par défaut
const Duration _kHttpTimeout = Duration(seconds: 20);

// Limite d’affichage des bodies dans la console
const int _kLogBodyMaxChars = 1200;

/// ---- HELPERS DEBUG ----------------------------------------------------------
class _Debug {
  static bool get _enabled => kDebugMode && kVerboseAuthLogs;

  static String _trim(String? s, [int max = _kLogBodyMaxChars]) {
    if (s == null) return '';
    if (s.length <= max) return s;
    return s.substring(0, max) + '…(trimmed ${s.length - max} chars)';
    }

  static void i(String msg, {Map<String, Object?> fields = const {}}) {
    if (!_enabled) return;
    final extra = fields.isEmpty ? '' : '  ' + jsonEncode(fields);
    // 🔵 Info
    // On uniformise le tag de service pour faciliter la recherche
    // Exemple: grep "[AuthService]" dans les logs
    // ignore: avoid_print
    print('🔵 [AuthService] $msg$extra');
  }

  static void s(String msg, {Map<String, Object?> fields = const {}}) {
    if (!_enabled) return;
    final extra = fields.isEmpty ? '' : '  ' + jsonEncode(fields);
    // 🟢 Success
    // ignore: avoid_print
    print('🟢 [AuthService] $msg$extra');
  }

  static void w(String msg, {Map<String, Object?> fields = const {}}) {
    if (!_enabled) return;
    final extra = fields.isEmpty ? '' : '  ' + jsonEncode(fields);
    // 🟡 Warning
    // ignore: avoid_print
    print('🟡 [AuthService] $msg$extra');
  }

  static void e(String msg, {Object? err, StackTrace? st, Map<String, Object?> fields = const {}}) {
    if (!_enabled) return;
    final extra = {
      if (fields.isNotEmpty) ...fields,
      if (err != null) 'error': err.toString(),
      if (st != null) 'stack': _trim(st.toString(), 2000),
    };
    // 🔴 Error
    // ignore: avoid_print
    print('🔴 [AuthService] $msg  ${jsonEncode(extra)}');
  }

  static void httpReq({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
  }) {
    if (!_enabled) return;
    final safeBody = body is String ? _trim(body) : body;
    // ignore: avoid_print
    print('🔵 [AuthService] → $method ${uri.toString()}  ${jsonEncode({
      if (headers != null && headers.isNotEmpty) 'headers': headers,
      if (safeBody != null) 'body': safeBody,
    })}');
  }

  static void httpRes({
    required String method,
    required Uri uri,
    required int status,
    required Duration latency,
    String? body,
  }) {
    if (!_enabled) return;
    // ignore: avoid_print
    print('🔵 [AuthService] ← $method ${uri.toString()}  ${jsonEncode({
      'status': status,
      'latency_ms': latency.inMilliseconds,
      if (body != null) 'body': _trim(body),
    })}');
  }
}

/// ---- HELPERS SÉCURITÉ LOGS --------------------------------------------------
String _maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 1) return '***@${email.substring(at + 1)}';
  final local = email.substring(0, at);
  final domain = email.substring(at + 1);
  final keep = local.length >= 4 ? 2 : 1;
  return '${local.substring(0, keep)}***@${domain}';
}

String _maskPassword(String _) => '***';

/// ---- HELPERS JSON -----------------------------------------------------------
dynamic _safeJsonDecode(String source) {
  try {
    return json.decode(source);
  } catch (_) {
    _Debug.w('Body non-JSON, renvoyé en texte brut');
    return source; // on renvoie le texte pour diagnostic
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

/// ---- SERVICE ---------------------------------------------------------------
class AuthService {
  /* ======================= Local Cache Helpers ======================= */

  static const _kToken = 'token';
  static const _kUserRole = 'user_role';
  static const _kUserJson = 'user_json';

  static Future<void> _cacheToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    _Debug.s('Token mis en cache');
  }

  static Future<void> _cacheRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserRole, role);
    _Debug.s('Rôle mis en cache', fields: {'role': role});
  }

  static Future<void> cacheUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserJson, json.encode(user));
    _Debug.s('Utilisateur mis en cache', fields: {
      'id': user['id'],
      'email': user['email'],
      'role': user['role'],
      'name': user['name'],
    });
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserJson);
    if (raw == null) {
      _Debug.i('Aucun user en cache');
      return null;
    }
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      _Debug.i('User récupéré du cache', fields: {
        'id': map['id'],
        'email': map['email'],
        'role': map['role'],
      });
      return map;
    } catch (e, st) {
      _Debug.e('Échec parse user_json depuis cache', err: e, st: st);
      return null;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserRole);
    await prefs.remove(_kUserJson);
    _Debug.i('Cache Auth nettoyé');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kToken);
    _Debug.i('getToken', fields: {'exists': t != null});
    return t;
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final r = prefs.getString(_kUserRole) ?? 'visitor';
    _Debug.i('getUserRole', fields: {'role': r});
    return r;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final ok = prefs.getString(_kToken) != null;
    _Debug.i('isLoggedIn', fields: {'value': ok});
    return ok;
  }

  /* ======================= HTTP LAYER (avec logs) ======================= */

  static Future<http.Response> _post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    String? bearer,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'VarXProApp/1.0 (Flutter)',
      if (headers != null) ...headers,
      if (bearer != null) 'Authorization': 'Bearer $bearer',
    };

    _Debug.httpReq(method: 'POST', uri: uri, headers: h, body: body);
    final sw = Stopwatch()..start();
    try {
      final res = await http
          .post(uri, headers: h, body: body)
          .timeout(_kHttpTimeout);
      sw.stop();
      _Debug.httpRes(
        method: 'POST',
        uri: uri,
        status: res.statusCode,
        latency: sw.elapsed,
        body: res.body,
      );
      return res;
    } on TimeoutException catch (e, st) {
      sw.stop();
      _Debug.e('POST timeout', err: e, st: st, fields: {'url': uri.toString(), 'latency_ms': sw.elapsed.inMilliseconds});
      rethrow;
    } catch (e, st) {
      sw.stop();
      _Debug.e('POST exception', err: e, st: st, fields: {'url': uri.toString(), 'latency_ms': sw.elapsed.inMilliseconds});
      rethrow;
    }
  }

  static Future<http.Response> _get(
    String path, {
    Map<String, String>? headers,
    String? bearer,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'VarXProApp/1.0 (Flutter)',
      if (headers != null) ...headers,
      if (bearer != null) 'Authorization': 'Bearer $bearer',
    };

    _Debug.httpReq(method: 'GET', uri: uri, headers: h);
    final sw = Stopwatch()..start();
    try {
      final res = await http.get(uri, headers: h).timeout(_kHttpTimeout);
      sw.stop();
      _Debug.httpRes(
        method: 'GET',
        uri: uri,
        status: res.statusCode,
        latency: sw.elapsed,
        body: res.body,
      );
      return res;
    } on TimeoutException catch (e, st) {
      sw.stop();
      _Debug.e('GET timeout', err: e, st: st, fields: {'url': uri.toString(), 'latency_ms': sw.elapsed.inMilliseconds});
      rethrow;
    } catch (e, st) {
      sw.stop();
      _Debug.e('GET exception', err: e, st: st, fields: {'url': uri.toString(), 'latency_ms': sw.elapsed.inMilliseconds});
      rethrow;
    }
  }

  /* ======================= API Calls ======================= */

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role, // 'user' or 'supervisor'
  }) async {
    _Debug.i('register()', fields: {
      'email': _maskEmail(email),
      'role': role,
    });

    try {
      final res = await _post(
        '/api/register',
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        }),
      );

      final payload = _safeJsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        _Debug.s('register OK');
        return {'success': true, 'data': payload};
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Registration failed';
        _Debug.w('register non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      _Debug.e('register exception', err: e, st: st);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendEmailOtp({required String email}) async {
    _Debug.i('sendEmailOtp()', fields: {'email': _maskEmail(email)});
    try {
      final res = await _post(
        '/api/email/send-otp',
        body: json.encode({'email': email}),
      );
      final payload = _safeJsonDecode(res.body);
      if (res.statusCode == 200) {
        _Debug.s('sendEmailOtp OK');
        return {'success': true, 'data': payload};
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Failed to send OTP';
        _Debug.w('sendEmailOtp non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      _Debug.e('sendEmailOtp exception', err: e, st: st);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    _Debug.i('verifyEmailOtp()', fields: {'email': _maskEmail(email), 'code_len': code.length});
    try {
      final res = await _post(
        '/api/email/verify',
        body: json.encode({'email': email, 'code': code}),
      );
      final payload = _safeJsonDecode(res.body);
      if (res.statusCode == 200) {
        _Debug.s('verifyEmailOtp OK');
        return {'success': true, 'data': payload};
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Verification failed';
        _Debug.w('verifyEmailOtp non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      _Debug.e('verifyEmailOtp exception', err: e, st: st);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _Debug.i('login()', fields: {'email': _maskEmail(email), 'pwd': _maskPassword(password)});
    try {
      final res = await _post(
        '/api/login',
        body: json.encode({'email': email, 'password': password}),
      );

      final payload = _safeJsonDecode(res.body);
      if (res.statusCode == 200) {
        final data = _asMap(payload);
        final token = data['token'] as String?;
        final user = _asMap(data['user']);
        final role = (user['role'] ?? 'visitor').toString();

        if (token != null && token.isNotEmpty) {
          await _cacheToken(token);
          await _cacheRole(role);
          await cacheUser(user);
          _Debug.s('login OK', fields: {'role': role, 'user_id': user['id']});
          return {'success': true, 'data': data};
        } else {
          _Debug.w('login 200 mais token manquant');
          return {'success': false, 'error': 'Missing token in response'};
        }
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Login failed';
        _Debug.w('login non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      _Debug.e('login exception', err: e, st: st);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    _Debug.i('logout()');
    final token = await getToken();
    if (token == null) {
      await clearCache();
      _Debug.s('logout sans token → cache nettoyé');
      return {'success': true, 'data': {}};
    }

    try {
      final res = await _post(
        '/api/logout',
        bearer: token,
      );

      await clearCache();

      final payload = _safeJsonDecode(res.body);
      if (res.statusCode == 200) {
        _Debug.s('logout OK côté serveur');
        return {'success': true, 'data': payload};
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Logout failed';
        _Debug.w('logout non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      await clearCache();
      _Debug.e('logout exception (cache déjà nettoyé)', err: e, st: st);
      // On considère la déconnexion locale suffisante
      return {'success': true, 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> sendForgotPasswordOtp({required String email}) async {
    _Debug.i('sendForgotPasswordOtp()', fields: {'email': _maskEmail(email)});
    try {
      final res = await _post(
        '/api/password/forgot/send-otp',
        body: json.encode({'email': email}),
      );

      final payload = _safeJsonDecode(res.body);
      if (res.statusCode == 200) {
        _Debug.s('sendForgotPasswordOtp OK');
        return {'success': true, 'data': payload};
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Failed to send OTP';
        _Debug.w('sendForgotPasswordOtp non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      _Debug.e('sendForgotPasswordOtp exception', err: e, st: st);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    _Debug.i('resetPassword()', fields: {
      'email': _maskEmail(email),
      'code_len': code.length,
    });
    try {
      final res = await _post(
        '/api/password/forgot/verify',
        body: json.encode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final payload = _safeJsonDecode(res.body);
      if (res.statusCode == 200) {
        _Debug.s('resetPassword OK');
        return {'success': true, 'data': payload};
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Reset failed';
        _Debug.w('resetPassword non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      _Debug.e('resetPassword exception', err: e, st: st);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    _Debug.i('getUserProfile()');
    final token = await getToken();
    if (token == null) {
      _Debug.w('getUserProfile sans token');
      return {'success': false, 'error': 'No token found'};
    }

    try {
      final res = await _get('/api/user', bearer: token);
      final payload = _safeJsonDecode(res.body);

      if (res.statusCode == 200) {
        final data = _asMap(payload);
        // keep cache in sync with server
        await cacheUser(data);
        await _cacheRole((data['role'] ?? 'visitor').toString());
        _Debug.s('getUserProfile OK', fields: {
          'id': data['id'],
          'email': data['email'],
          'role': data['role'],
        });
        return {'success': true, 'data': data};
      } else if (res.statusCode == 401) {
        _Debug.w('getUserProfile 401 → clear cache et invalider session');
        await clearCache();
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        final errMap = _asMap(payload);
        final msg = errMap['message'] ?? 'Failed to fetch user profile';
        _Debug.w('getUserProfile non-200', fields: {'status': res.statusCode, 'message': msg});
        return {'success': false, 'error': msg};
      }
    } catch (e, st) {
      _Debug.e('getUserProfile exception', err: e, st: st);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
