import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/custom_appbar.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';

import '../auth_provider.dart';
import '../flutter_helpers/services/post_service.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key, required this.post_id});

  final String? post_id;

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {

  bool isLoading = false;
  final postService = PostService();
  final userService = UserService();
  Map<String, dynamic>? likes;
  late AuthProvider authProvider;

  getLikes() async {
    setState(() {
      isLoading = true;
    });
    try {
      likes = await postService.getLikes(widget.post_id!);
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
              likes = await postService.getLikes(widget.post_id!);
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    getLikes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Likes", leading: true,),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
          itemCount: likes!["likes"].length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 28, // Ajusté pour éviter un déséquilibre
                      backgroundImage: (likes!["likes"][index]["profile"] != null && likes!["likes"][index]["profile"].isNotEmpty)
                          ? NetworkImage(likes!["likes"][index]["profile"])
                          : null,
                      child: (likes!["likes"][index]["profile"] == null || likes!["likes"][index]["profile"].isEmpty)
                          ? Icon(Icons.person, size: 40, color: Colors.black54)
                          : null,
                    ),
                    title: Text("${likes!["likes"][index]["username"]}"),
                    onTap: () {
                      context.go("/user/${likes!["likes"][index]["id"]}");
                    },
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
