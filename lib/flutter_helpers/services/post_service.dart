import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dio_instance.dart';

class PostService {

  Dio api = configureDio();

  Future<Map<String, dynamic>> create (FormData data) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.post('posts/', data: data);

    return response.data;
  }

  Future<List<dynamic>> getAll({int author = 0}) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = (author == 0) ?
    await api.get('posts/') :
    await api.get(
      "posts/",
      queryParameters: {
        "author_id": author
      }
    );

    return response.data;
  }

  Future<Map<String, dynamic>> get (int id) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get('posts/$id/');

    return response.data;
  }

  Future<Map<String, dynamic>> update (Map<String, dynamic> data, int id) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.patch('posts/$id/', data: data);

    return response.data;
  }

  Future<Map<String, dynamic>> delete (int id) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.delete('posts/$id/');

    return response.data;
  }

  Future<Map<String, dynamic>> like (int id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.put('posts/$id/like/');

    return response.data;
  }

  Future<Map<String, dynamic>> getLikes (String id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get('posts/$id/like/');

    return response.data;
  }

}