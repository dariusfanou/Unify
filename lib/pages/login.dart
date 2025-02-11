import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';

import '../auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;
  bool isLoading = false;
  final userService = UserService();
  late AuthProvider authProvider;
  Map<String, dynamic>? authUser;

  login() async {

    setState(() {
      isLoading = true;
    });

    try {

      // Prépare les données à envoyer
      Map<String, dynamic> data = {
        'email': emailController.text,
        'password': passwordController.text
      };

      // Lancer la requête
      Map<String, dynamic> authUser = await userService.login(data);

      // Sauvegerder le access et le refresh en mémoire
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", authUser['access']!);
      await prefs.setString("refresh", authUser['refresh']!);

      authProvider.login();

      emailController.text = "";
      passwordController.text = "";

      // Rediriger vers la page d'accueil
      context.go("/home");

    } on DioException catch (e) {
      // Gérer les erreurs de la requête
      print(e.response);
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
          Fluttertoast.showToast(msg: "Une erreur est survenue.");
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(  // Utiliser un Column
          children: [
            Expanded(  // Utiliser Expanded pour que le contenu prenne toute la hauteur disponible
              child: Center(  // Centrer le contenu
                child: Column(  // Column pour organiser les widgets verticalement
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/unify.png",
                      width: 100,
                    ),
                    SizedBox(height: 32),
                    Text(
                      "CONNEXION",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 32),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
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
                              return (value == null || value.isEmpty)
                                  ? "Ce champ est obligatoire"
                                  : null;
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
                            await login();
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
                          "Se connecter",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Vous n'avez pas de compte ?"),
                        TextButton(
                          onPressed: () {
                            context.push("/register");
                          },
                          child: Text(
                            "Inscrivez-vous",
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
            ),
          ],
        ),
      ),
    );
  }
}
