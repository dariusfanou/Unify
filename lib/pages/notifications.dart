import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/auth_provider.dart';
import 'package:unify/custom_appbar.dart';
import 'package:unify/flutter_helpers/services/notification_service.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  bool isLoading = false;
  final notificationService = NotificationService();
  List<dynamic> notifications = [];
  late AuthProvider authProvider;
  final userService = UserService();

  getAll() async {

    setState(() {
      isLoading = true;
    });

    try {
      notifications = await notificationService.getAll();
      setState(() {});
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
              notifications = await notificationService.getAll();
              setState(() {});
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la récupération des publications.");
        }
      }
    } catch (e) {
      print(e);
      if (e is SocketException) {
        Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
      } else {
        Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }

  }

  updateNotificationVisibility(int id) async {

    try {

      Map<String, dynamic> data = {
        "is_read": true
      };

      await notificationService.update(data, id);

    } on DioException catch (e) {
      // Gérer les erreurs de la requête
      print(e.response?.statusCode);
      if (e.response?.statusCode == 401) {
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? refresh = prefs.getString("refresh");
          if (refresh != null) {
            final refreshToken = await userService.refreshToken(refresh);
            if (refreshToken.containsKey("access") && refreshToken.containsKey("refresh")) {
              await prefs.setString("token", refreshToken["access"]);
              await prefs.setString("refresh", refreshToken["refresh"]);

              Map<String, dynamic> data = {
                "is_read": true
              };

              await notificationService.update(data, id);
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la modification de la notification.");
        }
      }
    } catch (e) {
      // Gérer d'autres types d'erreurs
      if (e is SocketException) {
        Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
      } else {
        Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
      }
      Fluttertoast.showToast(msg: "Une erreur inattendue s'est produite.");
    }

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Notifications", leading: false),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: (!notifications[index]["is_read"]) ? Color(0x204CB669) : Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: (notifications[index]["sender"]["profile"] != null && notifications[index]["sender"]["profile"].isNotEmpty)
                            ? NetworkImage(notifications[index]["sender"]["profile"])
                            : null,
                        child: (notifications[index]["sender"]["profile"] == null || notifications[index]["sender"]["profile"].isEmpty)
                            ? Icon(Icons.person, size: 40, color: Colors.black54)
                            : null,
                      ),
                      title: Text("${notifications[index]["content"]}"),
                      onTap: () async {
                        if (notifications[index]["type"] == "user") {
                          context.push("/user/${notifications[index]["link_id"]}");
                          await updateNotificationVisibility(notifications[index]["id"]);
                        } else if (notifications[index]["type"] == "post") {
                          context.push("/${notifications[index]["link_id"]}/comments");
                          await updateNotificationVisibility(notifications[index]["id"]);
                        }
                      },
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
