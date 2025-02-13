import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/custom_appbar.dart';
import 'package:unify/flutter_helpers/services/post_service.dart';
import 'package:unify/post.dart';

import '../auth_provider.dart';
import '../flutter_helpers/services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool isLoading = false;
  final postService = PostService();
  final userService = UserService();
  List<dynamic> posts = [];
  late AuthProvider authProvider;

  getAll() async {

    setState(() {
      isLoading = true;
    });

    try {
      posts = await postService.getAll();
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
              posts = await postService.getAll();
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
    getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "UNIFY", leading: false,),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: ListView.builder(
            shrinkWrap: true,  // Ajoute cette ligne
            physics: NeverScrollableScrollPhysics(),  // Désactive le défilement du ListView
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostScreen(
                  post: posts[index],
                  backgroundColor: Color(0x204CB669),
              );
            }
        ),
      ),
    );
  }
}
