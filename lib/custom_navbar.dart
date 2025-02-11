import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/flutter_helpers/services/message_service.dart';

import 'auth_provider.dart';
import 'flutter_helpers/services/notification_service.dart';
import 'flutter_helpers/services/user_service.dart';

class CustomNavBarScreen extends StatefulWidget {
  final Widget child;  // <- child est un Widget passé au constructeur

  CustomNavBarScreen({required this.child});

  @override
  State<CustomNavBarScreen> createState() => _CustomNavBarScreenState();
}

class _CustomNavBarScreenState extends State<CustomNavBarScreen> {

  int _selectedIndex = 0;
  int unreadNotifications = 0;
  int unreadMessages = 0;
  final notificationService = NotificationService();
  late AuthProvider authProvider;
  final userService = UserService();
  final messageService = MessageService();

  getAllNotif() async {

    try {
      final notifications = await notificationService.getAll();
      setState(() {
        unreadNotifications = notifications.where((notification) => notification["is_read"] == false).length;
      });
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
              final notifications = await notificationService.getAll();
              setState(() {
                unreadNotifications = notifications.where((notification) => notification["is_read"] == false).length;
              });
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la récupération des notifications non lues.");
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

  getAllMes() async {

    try {
      final messages = await messageService.getAll();
      setState(() {
        unreadNotifications = messages.where((message) => message["is_read"] == false).length;
      });
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
              final messages = await messageService.getAll();
              setState(() {
                unreadNotifications = messages.where((message) => message["is_read"] == false).length;
              });
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la récupération des notifications non lues.");
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

  // Correspondance entre index et routes
  final List<String> _routes = ['/home', '/add_post', '/notifications', '/user'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    context.push(_routes[index]);
    getAllNotif();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    getAllNotif();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,  // Affiche la page actuelle
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        iconSize: 28,
        selectedItemColor: Color(0xFF4CB669),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Ajouter'
          ),
          BottomNavigationBarItem(
            icon: (unreadNotifications > 0) ? Badge(
              child: const Icon(
                Icons.notifications,
              ),
              label: Text("$unreadNotifications"),
            ) : Icon(Icons.notifications),
            label: 'Notifications'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil'
          ),
        ],
      ),
    );
  }
}
