import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/flutter_helpers/services/notification_service.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';

final userService = UserService();
final notificationService = NotificationService();
Map<String, dynamic>? authUser;

getAuthUser() async {
  try {
    final users = await userService.getAll();
    for (Map<String, dynamic> user in users) {
      if (user["is_current_user"]) {
        authUser = user;
      }
    }
  } on DioException catch (error) {
    print(error.response?.statusCode);
    if (error.response?.statusCode == 401) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? refresh = prefs.getString("refresh");
        if (refresh != null) {
          final refreshToken = await userService.refreshToken(refresh);
          if (refreshToken.containsKey("access") && refreshToken.containsKey("refresh")) {
            await prefs.setString("token", refreshToken["access"]);
            await prefs.setString("refresh", refreshToken["refresh"]);
            final users = await userService.getAll();
            for (Map<String, dynamic> user in users) {
              if (user["is_current_user"]) {
                authUser = user;
              }
            }
          }
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Erreur lors de la récupération de l'utilisateur connecté.");
      }
    }
  } catch (e) {
    print(e);
    if (e is SocketException) {
      Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
    } else {
      Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
    }
  }
}

follow(int userId) async {
  try {
    await userService.follow(userId);
    await createNotification("follow", userId);
  } on DioException catch (error) {
    print(error.response?.statusCode);
    if (error.response?.statusCode == 401) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? refresh = prefs.getString("refresh");
        if (refresh != null) {
          final refreshToken = await userService.refreshToken(refresh);
          if (refreshToken.containsKey("access") && refreshToken.containsKey("refresh")) {
            await prefs.setString("token", refreshToken["access"]);
            await prefs.setString("refresh", refreshToken["refresh"]);
            await userService.follow(userId);
            await createNotification("follow", userId);
          }
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Erreur lors de l'abonnement.");
      }
    }
  } catch (e) {
    print(e);
    if (e is SocketException) {
      Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
    } else {
      Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
    }
  }
}

createNotification(String action, int userId) async {

  await getAuthUser();

  try {

    Map<String, dynamic> data = {
      "content": (action == "follow") ? "${authUser!["username"]} a commencé à vous suivre" : "${authUser!["username"]} ne vous suit plus",
      'receiver': userId,
      "link_id": authUser!["id"],
      "type": "user"
    };

    await notificationService.create(data);
  } on DioException catch (error) {
    print(error.response?.statusCode);
    if (error.response?.statusCode == 401) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? refresh = prefs.getString("refresh");
        if (refresh != null) {
          final refreshToken = await userService.refreshToken(refresh);
          if (refreshToken.containsKey("access") && refreshToken.containsKey("refresh")) {
            await prefs.setString("token", refreshToken["access"]);
            await prefs.setString("refresh", refreshToken["refresh"]);
            Map<String, dynamic> data = {
              "content": (action == "follow") ? "${authUser!["username"]} a commencé à vous suivre" : "${authUser!["username"]} ne vous suit plus",
              'receiver': userId,
              "link_id": authUser!["id"],
              "type": "user"
            };

            await notificationService.create(data);
          }
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Erreur lors de la récupération des publications.");
      }
    }
  } catch (e) {
    print(e);
    // Gérer d'autres types d'erreurs
    if (e is SocketException) {
      Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
    } else {
      Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
    }
    Fluttertoast.showToast(msg: "Une erreur inattendue s'est produite.");
  }
}

unfollow(int userId) async {
  try {
    await userService.unfollow(userId);
    await createNotification("unfollow", userId);
  } on DioException catch (error) {
    print(error.response?.statusCode);
    if (error.response?.statusCode == 401) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? refresh = prefs.getString("refresh");
        if (refresh != null) {
          final refreshToken = await userService.refreshToken(refresh);
          if (refreshToken.containsKey("access") && refreshToken.containsKey("refresh")) {
            await prefs.setString("token", refreshToken["access"]);
            await prefs.setString("refresh", refreshToken["refresh"]);
            await userService.unfollow(userId);
            await createNotification("unfollow", userId);
          }
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Erreur lors du désabonnement.");
      }
    }
  } catch (e) {
    print(e);
    if (e is SocketException) {
      Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
    } else {
      Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
    }
  }
}