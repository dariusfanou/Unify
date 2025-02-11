import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/auth_provider.dart';
import 'package:unify/custom_appbar.dart';
import 'package:unify/flutter_helpers/services/post_service.dart';
import 'package:unify/post.dart';

import '../flutter_helpers/services/user_service.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, this.post, this.postId});

  final Map<String, dynamic>? post;
  final int? postId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {

  bool isLoading = false;
  late AuthProvider authProvider;
  final userService = UserService();
  final postService = PostService();
  Map<String, dynamic>? post;

  getPost() async {

    setState(() {
      isLoading = true;
    });

    try {
      post = await postService.get(widget.postId!);
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
              post = await postService.get(widget.postId!);
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
    if(widget.postId != null) {
      getPost();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: (widget.postId != null && post?["author"]["username"] != null ) ? post!["author"]["username"] : widget.post?["author"]["username"] ?? "", leading: false),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: PostScreen(
          post: (widget.postId != null) ? post! : widget.post!,
          backgroundColor: Colors.transparent,
          withComments: true,
        ),
      ),
    );
  }
}
