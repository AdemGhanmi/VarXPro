
import 'dart:convert';
import 'package:VarXPro/views/pages/LiveStream/model/category.dart';
import 'package:VarXPro/views/pages/LiveStream/model/channel.dart';
import 'package:http/http.dart' as http;


class ApiService {
  static const String baseUrl = "http://proiptv.tn:1234";
  static const String username = "177171818198265";
  static const String password = "181887373733883";

  Future<List<Category>> fetchCategories() async {
    final url =
        '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_categories';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  Future<List<Channel>> fetchChannels() async {
    final url =
        '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Channel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load channels: ${response.statusCode}');
    }
  }

  String getStreamUrl(String streamId) {
    return '$baseUrl/live/$username/$password/$streamId.m3u8';
  }
}
