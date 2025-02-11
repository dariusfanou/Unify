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
import '../post.dart';
import 'package:unify/follow.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key, this.userId});

  final String? userId;

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {

  final userService = UserService();
  Map<String, dynamic>? authUser;
  bool isLoading = false;
  late AuthProvider authProvider;
  final postService = PostService();
  List<dynamic> posts = [];
  bool isConnectedUser = false;
  bool is_following = true;
  Map<String, dynamic>? response;
  bool loading1 = false;
  bool loading2 = false;

  isFollowing() async {
    try {
      response = await userService.isFollowing(int.parse(widget.userId!));
      setState(() {
        is_following = response!["is_following"];
      });
      await getUser();
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
              response = await userService.isFollowing(int.parse(widget.userId!));
              setState(() {
                is_following = response!["is_following"];
              });
              await getUser();
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la vérification de l'abonnement.");
        }
      }
    } catch (e) {
      print(e.toString());
      if (e is SocketException) {
        Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
      }
    }
  }

  getAll() async {
    try {
      final users = await userService.getAll();
      for (Map<String, dynamic> user in users) {
        if (user["is_current_user"]) {
          authUser = user;
        }
      }
    } on DioException catch (error) {
      print(error.response?.data);
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
          Fluttertoast.showToast(msg: "Erreur lors de la récupération des infos utilisateur.");
        }
      }
    } catch (e) {
      print(e);
      if (e is SocketException) {
        Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
      }
    }
  }

  Future getUser({bool firstime = false}) async {

    if(firstime) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      if(widget.userId == null) {
        await getAll();
      } else {
        authUser = await userService.get(widget.userId!);
        (authUser!["is_current_user"]) ? isConnectedUser = true : false;
      }
      posts = await postService.getAll(author: authUser!["id"]);
      setState(() {});
    } on DioException catch (error) {
      print(error.response?.data);
      if (error.response?.statusCode == 401) {
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? refresh = prefs.getString("refresh");

          if (refresh != null) {
            final refreshToken = await userService.refreshToken(refresh);
            if (refreshToken.containsKey("access") && refreshToken.containsKey("refresh")) {
              await prefs.setString("token", refreshToken["access"]);
              await prefs.setString("refresh", refreshToken["refresh"]);
              if(widget.userId == null) {
                await getAll();
              } else {
                authUser = await userService.get(widget.userId!);
                (authUser!["is_current_user"]) ? isConnectedUser = true : false;
              }
              posts = await postService.getAll(author: authUser!["id"]);
              setState(() {});
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de la récupération des infos utilisateur.");
        }
      }
    } catch (e) {
      print(e);
      if (e is SocketException) {
        Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
      }
    } finally {
      if(firstime) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    (widget.userId == null) ? isConnectedUser = true : false;
    if (widget.userId == null) {
      isFollowing();
    }
    getUser(firstime: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: authUser?["username"] ?? "", leading: (widget.userId == null) ? false : true,),
      body: isLoading
        ? const Center(
        child: CircularProgressIndicator(),
      )
      : SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: (authUser!["profile"] != null)
                    ? NetworkImage(authUser!["profile"])
                    : null, // Si profile est null, aucune image de fond ne sera affichée
                child: (authUser!["profile"] == null)
                    ? Icon(Icons.person, size: 72, color: Colors.black54)
                    : null, // Si une image existe, on ne met pas d'icône
              ),
            ),
            SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: (authUser!["followers_count"] > 0) ? () {
                    context.push("/followers", extra: authUser);
                  } : () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("${authUser!["followers_count"]}"),
                      Text("Followers")
                    ],
                  ),
                ),
                TextButton(
                  onPressed: (authUser!["following_count"] > 0) ? () {
                    context.push("/following", extra: authUser);
                  } : () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("${authUser!["following_count"]}"),
                      Text("Suivis")
                    ],
                  ),
                ),
              ],
            ),
            (authUser!["bio"] != null && authUser!["bio"] != "") ? Text("${authUser!["bio"]}") : SizedBox(),
            SizedBox(height: (authUser!["bio"] != null && authUser!["bio"] != "") ? 8 : 0,),
            (isConnectedUser) ?
            IntrinsicWidth(
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFF4CB669)),
                  ),
                  onPressed: () {
                    context.push("/editProfile", extra: authUser);
                  },
                  child: Row(
                    children: [
                      Text("Modifier le profil", style: TextStyle(color: Colors.white),),
                      SizedBox(width: 8,),
                      Icon(Icons.edit, color: Colors.white,)
                    ],
                  )
              ),
            ) : ElevatedButton(
              style: ButtonStyle(
                backgroundColor: is_following ? WidgetStatePropertyAll(Colors.black54)
                    : WidgetStatePropertyAll(Color(0xFF4CB669)),
              ),
              onPressed: is_following ? !loading1 ? () async {
                setState(() {
                  loading1 = true;
                });
                await unfollow(int.parse(widget.userId!));
                await isFollowing();
                setState(() {
                  loading1 = false;
                });
              } : null
                  : !loading2 ? () async {
                setState(() {
                  loading2 = true;
                });
                await follow(int.parse(widget.userId!));
                await isFollowing();
                setState(() {
                  loading2 = false;
                });
              } : null,
              child: is_following ?
              loading1
                  ? SizedBox(
                height: 19,
                width: 19,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text("Ne plus suivre", style: TextStyle(color: Colors.white),)
                  : loading2
                  ? SizedBox(
                height: 19,
                width: 19,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text("Suivre", style: TextStyle(color: Colors.white),),
            ),
            SizedBox(height: 16,),
            ListView.builder(
              shrinkWrap: true,  // Ajoute cette ligne
              physics: NeverScrollableScrollPhysics(),  // Désactive le défilement du ListView
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostScreen(
                  post: posts[index],
                  backgroundColor: Color(0x204CB669),
                  is_user_page: true,
                );
              }
            )
          ],
        ),
      )
    );
  }
}
