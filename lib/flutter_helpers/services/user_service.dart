import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dio_instance.dart';

class UserService {

  Dio api = configureDio();

  Future<Map<String, dynamic>> login (Map<String, dynamic> data) async{

    final response =  await api.post('token/', data: data);

    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken (String refresh) async{

    final response =  await api.post('token/refresh/', data: {"refresh": refresh});

    return response.data;
  }

  Future<Map<String, dynamic>> create (Map<String, dynamic> data) async{

    final response = await api.post('users/', data: data);

    return response.data;
  }

  Future<List<dynamic>> getAll () async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get('users/');

    return response.data;
  }

  Future<Map<String, dynamic>> get (String id) async{

    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get('users/$id/');

    return response.data;
  }

  Future<void> partialUpdate(FormData data, int id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    await api.patch('users/$id/', data: data);
  }

  Future<void> update(FormData data, int id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    await api.put('users/$id/', data: data);
  }

  Future delete(int id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    await api.delete('users/$id/');
  }

  Future follow (int id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    await api.post('users/$id/follow/');
  }

  Future unfollow (int id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    await api.post('users/$id/unfollow/');
  }

  Future<Map<String, dynamic>> isFollowing (int id) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get('users/$id/is_following/');

    return response.data;
  }

  Future<Map<String, dynamic>> search (String query) async {
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString("token") ?? "";

    if (token != "") {
      api.options.headers['AUTHORIZATION'] = 'Bearer $token';
    }

    final response = await api.get(
        "search/",
        queryParameters: {
          "q": query
        }
    );

    return response.data;
  }

}