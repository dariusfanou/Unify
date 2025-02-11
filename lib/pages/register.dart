import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/flutter_helpers/services/notification_service.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';
import 'package:unify/pages/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;
  final userService = UserService();
  Map<String, dynamic> authUser = {};
  final notificationService = NotificationService();

  login() async {

    try {

      // Prépare les données à envoyer
      Map<String, dynamic> data = {
        'email': emailController.text,
        'password': passwordController.text
      };

      authUser = await userService.login(data);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("token", authUser['access']!);
      prefs.setString("refresh", authUser['refresh']!);

      usernameController.text = "";
      emailController.text = "";
      passwordController.text = "";
      confirmPasswordController.text = "";

    } on DioException catch (e) {
      // Gérer les erreurs de la requête
      print(e.response?.statusCode);
      if (e.response != null) {
        if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
          Fluttertoast.showToast(msg: "Identifiants invalides.");
        } else {
          Fluttertoast.showToast(msg: "Erreur du serveur : ${e.response?.statusCode}");
        }
      } else {
        // Gérer les erreurs réseau
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          Fluttertoast.showToast(msg: "Temps de connexion écoulé. Vérifiez votre connexion Internet.");
        } else if (e.type == DioExceptionType.unknown) {
          Fluttertoast.showToast(msg: "Impossible de se connecter au serveur. Vérifiez votre réseau.");
        } else {
          Fluttertoast.showToast(msg: "Une erreur est survenue $e");
          print(e);
        }
      }
    } catch (e) {
      // Gérer d'autres types d'erreurs
      if (e is SocketException) {
        Fluttertoast.showToast(msg: "Pas d'accès Internet. Veuillez vérifier votre connexion.");
      } else {
        Fluttertoast.showToast(msg: "Une erreur inattendue est survenue.");
      }
      Fluttertoast.showToast(msg: "Une erreur inattendue s'est produite $e");
      print(e);
    }

  }

  create() async {

    setState(() {
      isLoading = true;
    });

    try {

      Map<String, dynamic> data = {
        "username": usernameController.text,
        'email': emailController.text,
        "password": passwordController.text,
        "confirm_password": confirmPasswordController.text
      };

      authUser = await userService.create(data);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt("id", authUser['id']!);

      await login();

      await createNotification();

      context.go("/profile");

    } on DioException catch (e) {
      // Gérer les erreurs de la requête
      print(e.response?.data);
      if (e.response != null) {
        if (e.response?.statusCode == 400) {
          if (e.response?.data["email"] != null) {
            Fluttertoast.showToast(msg: e.response?.data["email"][0]);
          }
          else if(e.response?.data["username"] != null) {
            Fluttertoast.showToast(msg: e.response?.data["username"][0]);
          }
          else if(e.response?.data["password"] != null) {
            Fluttertoast.showToast(msg: e.response?.data["password"][0]);
          }
        }
        else if(e.response?.statusCode == 401) {
          Fluttertoast.showToast(msg: "Données invalides.");
        }
        else {
          Fluttertoast.showToast(msg: "Erreur du serveur : ${e.response?.statusCode}");
        }
      } else {
        // Gérer les erreurs réseau
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          Fluttertoast.showToast(msg: "Temps de connexion écoulé. Vérifiez votre connexion Internet.");
        } else if (e.type == DioExceptionType.unknown) {
          Fluttertoast.showToast(msg: "Impossible de se connecter au serveur. Vérifiez votre réseau.");
        } else {
          Fluttertoast.showToast(msg: "Une erreur est survenue.");
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }

  }

  createNotification() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int id = await prefs.getInt("id") ?? 0;

      Map<String, dynamic> data = {
        "content": "Bienvenue sur Unify ${usernameController.text}",
        'receiver': id,
        "link_id": id,
        "type": "user"
      };

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
              int id = await prefs.getInt("id") ?? 0;

              Map<String, dynamic> data = {
                "content": "Bienvenue sur Unify ${usernameController.text}",
                'receiver': id,
                "link_id": id,
                "type": "user"
              };

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(  // Utiliser un Column
            children: [
              Center(  // Centrer le contenu
                child: Column(  // Column pour organiser les widgets verticalement
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 32),
                    Image.asset(
                      "assets/images/unify.png",
                      width: 100,
                    ),
                    SizedBox(height: 32),
                    Text(
                      "INSCRIPTION",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 32),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: usernameController,
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              label: Text("Nom d'utilisateur"),
                              hintText: "Entrez votre pseudo",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Ce champ est obligatoire";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              label: Text("Adresse email"),
                              hintText: "Entrez votre adresse email",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.mail),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Ce champ est obligatoire";
                              }
                              final emailRegex = RegExp(
                                  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                              if (!emailRegex.hasMatch(value)) {
                                return "Veuillez entrer une adresse email valide";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32),
                          TextFormField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              label: Text("Mot de passe"),
                              hintText: "Entrez votre mot de passe",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Ce champ est obligatoire";
                              }
                              if (value.length < 8) {
                                return "Le mot de passe doit contenir au moins 8 caractères";
                              }
                              if (RegExp(r'^\d+$').hasMatch(value)) {
                                return "Le mot de passe ne peut pas être uniquement composé de chiffres";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: hideConfirmPassword,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              label: Text("Confirmer le mot de passe"),
                              hintText: "Entrez votre mot de passe à nouveau",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    hideConfirmPassword = !hideConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  hideConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Ce champ est obligatoire";
                              }
                              if (value != passwordController.text) {
                                return "Les mots de passe ne correspondent pas";
                              }
                              return null;
                            },

                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Color(0xFF4CB669)),
                          elevation: WidgetStateProperty.all(0),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate()) {
                            await create();
                          }
                        },
                        child: isLoading
                            ? SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Continuer",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Vous avez déjà un compte ?"),
                        TextButton(
                          onPressed: () {
                            context.push("/login");
                          },
                          child: Text(
                            "Connectez-vous",
                            style: TextStyle(
                              color: Color(0xFF4CB669),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
