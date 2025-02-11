import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/post.dart';

import '../auth_provider.dart';
import '../flutter_helpers/services/user_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.query});

  final String query;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool isLoading = false;
  final userService = UserService();
  Map<String, dynamic> searchContent = {};
  late AuthProvider authProvider;
  final formKey = GlobalKey<FormState>();
  final searchController = TextEditingController();
  String baseUrl = "https://darius12.pythonanywhere.com";

  search() async {
    setState(() {
      isLoading = true;
    });

    try {
      searchContent = await userService.search(searchController.text);
      setState(() {});
    } on DioException catch (error) {
      print(error.response?.data);
      if (error.response?.statusCode == 401) {
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? refresh = prefs.getString("refresh");
          if (refresh != null) {
            final refreshToken = await userService.refreshToken(refresh);
            if (refreshToken.containsKey("access") &&
                refreshToken.containsKey("refresh")) {
              await prefs.setString("token", refreshToken["access"]);
              await prefs.setString("refresh", refreshToken["refresh"]);
              searchContent = await userService.search(searchController.text);
              setState(() {});
            }
          } else {
            Fluttertoast.showToast(
                msg: "Session expirée. Veuillez vous reconnecter.");
            authProvider.logout();
            context.go("/login");
          }
        } catch (e) {
          Fluttertoast.showToast(
              msg: "Erreur lors de la recherche.");
        }
      }
    } catch (e) {
      print(e);
      if (e is SocketException) {
        Fluttertoast.showToast(
            msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
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
    searchController.text = widget.query;
    search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF4CB669),
        title: Form(
            key: formKey,
            child: TextFormField(
              keyboardType: TextInputType.text,
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
              onFieldSubmitted: (value) async {
                final query = Uri.encodeComponent(searchController.text.trim());
                if (query.isNotEmpty) {
                  search();
                }
              },
            )
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                searchController.clear();
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : (searchContent.containsKey("users") && searchContent.containsKey("posts")) ?
      (searchContent["users"].length == 0 && searchContent["posts"].length == 0) ?
          Text("Aucun résultat trouvé")
          : SingleChildScrollView(
        child: Column(
          children: [
            (searchContent["users"].length == 0) ?
                SizedBox():
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: searchContent["users"].length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    color: Colors.white,
                    elevation: 0,
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 28, // Ajusté pour éviter un déséquilibre
                            backgroundImage: (searchContent["users"][index]["profile"] != null && searchContent["users"][index]["profile"].isNotEmpty)
                                ? NetworkImage(baseUrl + searchContent["users"][index]["profile"])
                                : null,
                            child: (searchContent["users"][index]["profile"] == null || searchContent["users"][index]["profile"].isEmpty)
                                ? Icon(Icons.person, size: 40, color: Colors.black54)
                                : null,
                          ),
                          title: Text("${searchContent["users"][index]["username"]}"),
                          onTap: () {
                            context.push("/user/${searchContent["users"][index]["id"]}");
                          },
                        )
                      ],
                    ),
                  );
                }
            ),
            (searchContent["posts"].length == 0) ?
            SizedBox():
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: searchContent["posts"].length,
                itemBuilder: (context, index) {
                  return PostScreen(
                    post: searchContent["posts"][index],
                    backgroundColor: Color(0x204CB669),
                  );
                }
            )
          ],
        ),
      ) : SizedBox(),
    );
  }
}
