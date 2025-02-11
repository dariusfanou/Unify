import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dio_instance.dart';

class CommentService {

  Dio api = configureDio();

  Future<Map<String, dynamic>> create (Map<String, dynamic> data, String id) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.post(
        'comments/',
        data: data,
        queryParameters: {"post_id": id}
    );

    return response.data;
  }

  Future<List<dynamic>> getAll(String id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get(
        'comments/',
        queryParameters: {"post_id": id}
    );

    return response.data;
  }

  Future<Map<String, dynamic>> get (String postId, String commentId) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get(
        'comments/$commentId/',
        queryParameters: {"post_id": postId}
    );

    return response.data;
  }

  Future<Map<String, dynamic>> update (Map<String, dynamic> data, String postId, String commentId) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.patch(
        'comments/$commentId/',
        data: data,
        queryParameters: {"post_id": postId}
    );

    return response.data;
  }

  Future<Map<String, dynamic>> delete (String postId, String commentId) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.delete(
        'comments/$commentId/',
        queryParameters: {"post_id": postId}
    );

    return response.data;
  }

}