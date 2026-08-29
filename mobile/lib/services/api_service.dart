import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/channel.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/attachment.dart';

class ApiService {
  /// Default server the app talks to on a fresh install.
  ///
  /// Override at build time without editing this file:
  ///   flutter build apk --dart-define=PULSE_SERVER_URL=https://your-app.up.railway.app
  ///
  /// Users can also change it in-app: login screen -> "Server:", or Profile -> Settings.
  static const String defaultBaseUrl = String.fromEnvironment(
    'PULSE_SERVER_URL',
    defaultValue: 'https://your-app.up.railway.app',
  );

  static String baseUrl = defaultBaseUrl;

  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Bypass-Tunnel-Reminder': 'true',
  };

  static void setBaseUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    baseUrl = clean;
  }

  static dynamic _parseResponse(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      return jsonDecode(res.body);
    } catch (_) {
      if (res.statusCode == 502 || res.body.contains('Bad Gateway')) {
        throw Exception('Server unreachable (Bad Gateway). Please check your server and tunnel URL.');
      }
      throw Exception('Server returned status ${res.statusCode}: ${res.body.length > 80 ? res.body.substring(0, 80) : res.body}');
    }
  }

  static Future<User> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _defaultHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _parseResponse(res);
    if (res.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['user']);
    }
    throw Exception(data['error'] ?? 'Login failed');
  }

  static Future<User> signup(String username, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: _defaultHeaders,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    final data = _parseResponse(res);
    if (res.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['user']);
    }
    throw Exception(data['error'] ?? 'Signup failed');
  }

  static Future<List<Channel>> getConversations(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/conversations'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((c) => Channel.fromJson(c)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Channel?> createGroup(
    String name,
    String description,
    String icon,
    List<String> memberIds,
    String createdById,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/groups'),
        headers: _defaultHeaders,
        body: jsonEncode({
          'name': name,
          'description': description,
          'icon': icon,
          'memberIds': memberIds,
          'createdById': createdById,
        }),
      );
      if (res.statusCode == 200) {
        return Channel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Channel?> startDirectMessage(String user1Id, String user2Id) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/direct-messages'),
        headers: _defaultHeaders,
        body: jsonEncode({
          'user1Id': user1Id,
          'user2Id': user2Id,
        }),
      );
      if (res.statusCode == 200) {
        return Channel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Message>> getChannelMessages(String channelId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/channels/$channelId/messages'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((m) => Message.fromJson(m)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<User>> getAllUsers() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((u) => User.fromJson(u)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Attachment>> uploadImages(List<XFile> images) async {
    if (images.isEmpty) return [];
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'));
      request.headers['Bypass-Tunnel-Reminder'] = 'true';
      for (final img in images) {
        final bytes = await img.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: img.name,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List files = data['files'] ?? [];
        return files.map((f) => Attachment.fromJson(f)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Attachment>> uploadFiles(List<PlatformFile> files) async {
    if (files.isEmpty) return [];
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'));
      request.headers['Bypass-Tunnel-Reminder'] = 'true';
      for (final file in files) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ));
        } else if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'files',
            file.path!,
            filename: file.name,
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List filesData = data['files'] ?? [];
        return filesData.map((f) => Attachment.fromJson(f)).toList();
      }
    } catch (_) {}
    return [];
  }
}
