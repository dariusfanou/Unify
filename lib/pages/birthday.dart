import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth_provider.dart';
import '../flutter_helpers/services/user_service.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {

  final formKey = GlobalKey<FormState>();
  TextEditingController dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final userService = UserService();
  bool isLoading = false;
  bool loading = false;
  late AuthProvider authProvider;
  String? email;
  String? password;
  SharedPreferences? prefs;

  Future<void> selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        locale: const Locale("fr")
    );

    if (picked != null) {
      dateController.text = _dateFormat.format(picked);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  update(String goal) async {

    if(goal == "birthday") {
      setState(() {
        isLoading = true;
      });
    } else {
      setState(() {
        loading = true;
      });
    }

    try {

      Map<String, dynamic> data = {
        "birthday": dateController.text,
      };

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Vérification si la photo est présente et valide
      if (prefs.containsKey('profile')) {
        final String? profile = await prefs?.getString('profile');

        // Si le chemin est non null et le fichier existe
        if (profile != null && profile.isNotEmpty) {
          final File file = File(profile);

          if (await file.exists()) {
            String mimeType = 'image/jpeg'; // Valeur par défaut (JPEG)
            String extension = profile.split('.').last.toLowerCase(); // Récupère l'extension du fichier

            if (extension == 'png') {
              mimeType = 'image/png';
            }
            if (extension == 'jpg') {
              mimeType = 'image/jpg';
            }

            // Ajouter la photo dans les données
            data['profile'] = await MultipartFile.fromFile(profile, contentType: DioMediaType.parse(mimeType));
          }
        }
      }

      // Construire le FormData pour l'envoi multipart
      final formData = FormData.fromMap(data);

      await userService.partialUpdate(formData, prefs.getInt("id") ?? 0);

      dateController.text = "";

      await prefs.remove("id");
      await prefs.remove("profile");

      authProvider.login();

      context.go("/home");

    } on DioException catch (e) {
      // Gérer les erreurs de la requête
      print(e.response?.data);
      if (e.response != null) {
        if (e.response?.statusCode == 400) {
          if (e.response?.data["email"] != null) {
            Fluttertoast.showToast(msg: "Un compte existe déjà avec cet email.");
          }
          else if(e.response?.data["password"] != null) {
            Fluttertoast.showToast(msg: e.response?.data["password"]);
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
      if(goal == "birthday") {
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        "Ajoutez une date de naissance à votre profil pour nous permettre d'en savoir plus sur vous.",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 32,),
                      Form(
                          key: formKey,
                          child: TextFormField(
                            controller: dateController,
                            decoration: InputDecoration(
                              label: Text("Date de naissance"),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF707070)),
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF707070)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            readOnly: true,
                            onTap: () {
                              selectDate();
                            },
                            validator: (value) {
                              return (value == null || value.isEmpty) ? "Veuillez renseigner votre date de naissance" : null;
                            },
                          ),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
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
                            if(formKey.currentState!.validate()) {
                              await update("birthday");
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
                            "Terminer",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 16,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.white),
                            elevation: WidgetStateProperty.all(0),
                            foregroundColor: WidgetStateProperty.all(Colors.white),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(color: Color(0xFF4CB669), width: 1),
                              ),
                            ),
                          ),
                          onPressed: isLoading ? null : () async {
                            await update("plustard");
                          },
                          child: loading
                              ? SizedBox(
                            height: 19,
                            width: 19,
                            child: CircularProgressIndicator(
                              color: Color(0xFF4CB669),
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            "Plus tard",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                color: Color(0xFF4CB669),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
        ),
      ),
    );
  }
}
