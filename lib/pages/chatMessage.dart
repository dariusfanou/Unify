import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/flutter_helpers/services/message_service.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';

import '../auth_provider.dart';

class ChatMessageScreen extends StatefulWidget {
  const ChatMessageScreen({super.key, required this.sender});

  final Map<String, dynamic> sender;

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  TextEditingController _controller = TextEditingController();
  final messageService = MessageService();
  final userService = UserService();
  late AuthProvider authProvider;
  bool isLoading = false;
  List<dynamic> allMessages = [];
  List<dynamic> messages = [];
  Map<String, dynamic>? authUser;

  getAuthUser() async {
    setState(() {
      isLoading = true;
    });
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
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  getAll() async {

    setState(() {
      isLoading = true;
    });

    try {
      await getAuthUser();
      allMessages = await messageService.getAll();
      for (Map<String, dynamic> message in allMessages) {
        if (message["sender"]["id"] == widget.sender["id"] || message["recipient"]["id"] == authUser!["id"]) {
          messages.add(message);
        }
      }
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
              await getAuthUser();
              allMessages = await messageService.getAll();
              for (Map<String, dynamic> message in allMessages) {
                if (message["sender"]["id"] == widget.sender["id"] || message["recipient"]["id"] == authUser!["id"]) {
                  messages.add(message);
                }
              }
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

  updateMessageVisibility(int id) async {

    try {

      Map<String, dynamic> data = {
        "is_read": true
      };

      await messageService.update(data, id);

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

              await messageService.update(data, id);
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la modification du message.");
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
  void dispose() {
    getAll();
    for (Map<String, dynamic> message in messages) {
      updateMessageVisibility(message["id"]);
    }
    super.dispose();
  }

  create() async {
    try {
      Map<String, dynamic> data = {
        "content": _controller.text,
        "sender_id": authUser!["id"],
        "recepient_id": widget.sender["id"]
      };
      await messageService.create(data);
      _controller.text = "";
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
                "content": _controller.text,
                "sender_id": authUser!["id"],
                "recepient_id": widget.sender["id"]
              };
              await messageService.create(data);
              _controller.text = "";
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la création de la publication.");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.sender["username"], style: TextStyle(color: Colors.white),),
          backgroundColor: Color(0xFF4CB669),
          iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(height: 16,),
          isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: (widget.sender["profile"] != null)
                        ? NetworkImage(widget.sender["profile"])
                        : null, // Si profile est null, aucune image de fond ne sera affichée
                    child: (widget.sender["profile"] == null)
                        ? Icon(Icons.person, size: 72, color: Colors.black54)
                        : null, // Si une image existe, on ne met pas d'icône
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message["sender"]["id"] == authUser!["id"];
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xFF4CB669) : Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['content'],
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                )
              ],
            )
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: 'Tapez un message...',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send, color: Color(0xFF4CB669),),
                          onPressed: () async {
                            if (_controller.text.isNotEmpty) {
                              Map<String, dynamic> data = {
                                "content": _controller.text,
                                "sender_id": authUser!["id"],
                                "recepient_id": widget.sender["id"]
                              };
                              setState(() {
                                messages.insert(0, data);
                              });
                              await create();
                              _controller.clear();
                            }
                          },
                        ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
