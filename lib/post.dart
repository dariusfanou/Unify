import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/flutter_helpers/services/comment_service.dart';
import 'package:unify/flutter_helpers/services/notification_service.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';
import 'package:unify/follow.dart';

import 'auth_provider.dart';
import 'flutter_helpers/services/post_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key, required this.post, required this.backgroundColor, this.is_user_page, this.withComments});

  final Map<String, dynamic> post;
  final Color backgroundColor;
  final bool? is_user_page;
  final bool? withComments;

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {

  final postService = PostService();
  final userService = UserService();
  late AuthProvider authProvider;
  Map<String, dynamic>? post;
  bool? has_liked;
  int? total_likes;
  bool is_following = true;
  Map<String, dynamic>? response;
  bool isLoading = false;
  bool loading = false;
  final formKey = GlobalKey<FormState>();
  final commentController = TextEditingController();
  final commentService = CommentService();
  Map<String, dynamic>? newComment;
  List<dynamic> comments = [];
  int? total_comments;
  final notificationService = NotificationService();
  Map<String, dynamic>? authUser;
  Map<String, dynamic>? newLike;

  isFollowing() async {
    try {
      response = await userService.isFollowing(widget.post["author"]["id"]);
      setState(() {
        is_following = response!["is_following"];
      });
      if (widget.post["author"]["is_current_user"]) {
        setState(() {
          is_following = true;
        });
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
              response = await userService.isFollowing(widget.post["author"]["id"]);
              setState(() {
                is_following = response!["is_following"];
              });
              if (widget.post["author"]["is_current_user"]) {
                setState(() {
                  is_following = true;
                });
              }
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
      print(e);
      if (e is SocketException) {
        Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
      } else {
        Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
      }
    }
  }

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
    }
  }

  get() async {

    try {
      post = await postService.get(widget.post["id"]);
      setState(() {
        has_liked = post!["has_liked"];
        total_likes = post!["likes_count"];
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
              post = await postService.get(widget.post["id"]);
              setState(() {
                has_liked = post!["has_liked"];
                total_likes = post!["likes_count"];
              });
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
    }

  }

  createNotification(String type) async {
    try {

      await getAuthUser();

      Map<String, dynamic> data = {};
      if (type == "like") {
        data = {
          "content": (newLike!["has_liked"]) ? "${authUser!["username"]} a aimé votre publication" : "${authUser!["username"]} n'aime plus votre publication",
          'receiver': widget.post["author"]["id"],
          "link_id": widget.post["id"],
          "type": "post"
        };
      } else {
        data = {
          "content": "${authUser!["username"]} a commenté votre publication",
          'receiver': widget.post["author"]["id"],
          "link_id": widget.post["id"],
          "type": "post"
        };
      }

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
              await getAuthUser();

              Map<String, dynamic> data = {};
              if (type == "like") {
                data = {
                  "content": (newLike!["has_liked"]) ? "${authUser!["username"]} a aimé votre publication" : "${authUser!["username"]} n'aime plus votre publication",
                  'receiver': widget.post["author"]["id"],
                  "link_id": widget.post["id"],
                  "type": "post"
                };
              } else {
                data = {
                  "content": "${authUser!["username"]} a commenté votre publication",
                  'receiver': widget.post["author"]["id"],
                  "link_id": widget.post["id"],
                  "type": "post"
                };
              }

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

  comment() async {

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> data = {
        "content": commentController.text
      };
      newComment = await commentService.create(data, widget.post["id"].toString());
      await createNotification("comment");
      commentController.text = "";
      setState(() {
        total_comments = total_comments! + 1;
        comments.insert(0, newComment);
      });
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
              Map<String, dynamic> data = {
                "content": commentController.text
              };
              newComment = await commentService.create(data, widget.post["id"].toString());
              await createNotification("comment");
              commentController.text = "";
              setState(() {
                total_comments = total_comments ?? 0 + 1;
                comments.insert(0, newComment);
              });
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de l'ajout du commentaire.");
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
      loading = true;
    });
    try {
      comments = await commentService.getAll(widget.post["id"].toString());
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
              comments = await commentService.getAll(widget.post["id"].toString());
              setState(() {});
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors de l'affichage des commentaires.");
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
        loading = false;
      });
    }
  }

  like(int id) async {
    try {
      newLike = await postService.like(id);
      await createNotification("like");
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
              newLike = await postService.like(id);
              await createNotification("like");
              setState(() {});
            }
          } else {
            Fluttertoast.showToast(msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Erreur lors du like.");
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
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    has_liked = widget.post["has_liked"];
    total_likes = widget.post["likes_count"];
    total_comments = widget.post["comments_count"];
    getAll();
    isFollowing();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: widget.backgroundColor,
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Assure un alignement à gauche
            children: [
              ListTile(
                isThreeLine: true, // Assure que le texte reste bien aligné
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Ajuste l'espacement
                leading: CircleAvatar(
                  radius: 28, // Ajusté pour éviter un déséquilibre
                  backgroundImage: (widget.post["author"]["profile"] != null && widget.post["author"]["profile"].isNotEmpty)
                      ? NetworkImage(widget.post["author"]["profile"])
                      : null,
                  child: (widget.post["author"]["profile"] == null || widget.post["author"]["profile"].isEmpty)
                      ? Icon(Icons.person, size: 40, color: Colors.black54)
                      : null,
                ),
                title: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            context.push("/user/${widget.post["author"]["id"].toString()}");
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, // Supprime le padding
                            minimumSize: Size.zero, // Supprime la taille minimale
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Réduit la zone cliquable
                          ),
                          child: Text(
                            "${widget.post["author"]["username"]}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black
                            ),
                          ),
                        ),
                        SizedBox(width: 16,),
                        (widget.is_user_page != null && widget.is_user_page!) ?
                        SizedBox() :
                        TextButton(
                          onPressed: () async {
                            await follow(widget.post["author"]["id"]);
                            await isFollowing();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, // Supprime le padding
                            minimumSize: Size.zero, // Supprime la taille minimale
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Réduit la zone cliquable
                          ),
                          child: !is_following ? Text(
                            "Suivre",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CB669)
                            ),
                          ) : SizedBox(),
                        ),
                      ],
                    )
                ),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("${widget.post["time_ago"]}"),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0,),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${widget.post["content"]}",
                        ),
                      ),
                      (widget.post["image"] != null) ?
                      SizedBox(height: 16,) : SizedBox(),
                      (widget.post["image"] != null) ?
                      Image.network(
                        widget.post["image"],
                        width: double.infinity,
                        height: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                      ) : SizedBox(),
                      Divider(
                        color: Colors.black54, // Couleur du trait
                        thickness: 1, // Épaisseur du trait
                        height: 16, // Espace vertical autour du trait
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await like(widget.post["id"]);
                                  await get();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero, // Supprime le padding
                                  minimumSize: Size.zero, // Supprime la taille minimale
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Réduit la zone cliquable
                                ),
                                child: Icon(
                                  has_liked! ?
                                  Icons.thumb_up :
                                  Icons.thumb_up_alt_outlined,
                                  color: has_liked! ? Color(0xFF4CB669) : Colors.black54,
                                ),
                              ),
                              SizedBox(width: 8,),
                              TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero, // Supprime le padding
                                    minimumSize: Size.zero, // Supprime la taille minimale
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Réduit la zone cliquable
                                  ),
                                  onPressed: (total_likes! > 0) ? () {
                                    context.push("/${widget.post["id"]}/like");
                                  } : null,
                                  child: Text("${total_likes!} ${(total_likes == 1) ? "like" : "likes"}", style: TextStyle(color: Colors.black54),)
                              )
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              context.push("/comments", extra: widget.post);
                            },
                            child: Row(
                              children: [
                                Icon(FontAwesomeIcons.comment, color: Colors.black54,),
                                SizedBox(width: 8,),
                                Text("${total_comments} ${(total_comments == 1) ? "commentaire" : "commentaires"}", style: TextStyle(color: Colors.black54),)
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  )
              ),
            ],
          ),
        ),
        (widget.withComments != null && widget.withComments!) ?
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0,),
          child: Column(
            children: [
              Form(
                  key: formKey,
                  child: TextFormField(
                    controller: commentController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Ajouter un commentaire",
                      suffixIcon: isLoading
                          ? Transform.scale(
                        scale: 0.5, // Réduit la taille à 50%
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CB669),
                          strokeWidth: 5, // Ajuste l'épaisseur
                        ),
                      )
                          : IconButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            await comment();
                          }
                        },
                        icon: Icon(Icons.send, color: Color(0xFF4CB669)),
                      ),
                    ),
                    validator: (value) {
                      return (value == null || value.isEmpty) ? "Ce champ est obligatoire" : null;
                    },
                  )
              ),
              SizedBox(height: 16,),
              (loading) ?
              const Center(
                child: CircularProgressIndicator(),
              ) : (comments.isNotEmpty) ?
              ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return Card(
                        color: Colors.white,
                        margin: EdgeInsets.all(0),
                        elevation: 0,
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                radius: 28, // Ajusté pour éviter un déséquilibre
                                backgroundImage: (comments[index]["author"]["profile"] != null && comments[index]["author"]["profile"].isNotEmpty)
                                    ? NetworkImage(comments[index]["author"]["profile"])
                                    : null,
                                child: (comments[index]["author"]["profile"] == null || comments[index]["author"]["profile"].isEmpty)
                                    ? Icon(Icons.person, size: 40, color: Colors.black54)
                                    : null,
                              ),
                              title: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text("${comments[index]["author"]["username"]}"),
                                  ],
                                ),
                              ),
                              subtitle: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${comments[index]["content"]}"),
                                    Text(
                                      "${comments[index]["time_ago"]}",
                                      style: TextStyle(
                                          color: Colors.grey
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                    );
                  }
              )
                  : Text("Aucun commentaire sous ce post")
            ],
          ),
        ) : SizedBox()
      ],
    );
  }
}
