import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/custom_appbar.dart';

import '../auth_provider.dart';
import '../flutter_helpers/services/message_service.dart';
import '../flutter_helpers/services/user_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  List<dynamic> messages = [];
  bool isLoading = false;
  final messageService = MessageService();
  final userService = UserService();
  late AuthProvider authProvider;

  getAll() async {

    setState(() {
      isLoading = true;
    });

    try {
      messages = await messageService.getAll();
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
              messages = await messageService.getAll();
              setState(() {});
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la récupération des messages.");
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
      appBar: CustomAppBar(title: "Messages", leading: false),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: (messages.isNotEmpty) ? ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: (!messages[index]["is_read"]) ? Color(0x204CB669) : Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                        leading: CircleAvatar(
                          radius: 28, // Ajusté pour éviter un déséquilibre
                          backgroundImage: (messages[index]["sender"]["profile"] != null && messages[index]["sender"]["profile"].isNotEmpty)
                              ? NetworkImage(messages[index]["sender"]["profile"])
                              : null,
                          child: (messages[index]["sender"]["profile"] == null || messages[index]["sender"]["profile"].isEmpty)
                              ? Icon(Icons.person, size: 40, color: Colors.black54)
                              : null,
                        ),
                        title: Text(messages[index]["sender"]["username"]),
                        subtitle: Text(
                          messages[index]["content"],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          context.push("/chatMessage", extra: messages[index]["sender"]);
                        },
                      ),
                  ),
                ],
              ),
            );
          },
        ) : Center(child: Text("Aucun message pour le moment")),
      ),
    );
  }
}
