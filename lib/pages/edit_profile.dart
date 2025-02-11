import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/auth_provider.dart';
import 'package:unify/custom_appbar.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final userService = UserService();
  late AuthProvider authProvider;
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  final dateController = TextEditingController();
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    usernameController.text = widget.user["username"];
    emailController.text = widget.user["email"];
    bioController.text = (widget.user["bio"] != null) ? widget.user["bio"] : "";
    dateController.text = (widget.user["birthday"] != null) ? widget.user["birthday"] : "";
  }

  String? _filePath;

  Future<void> pickImage() async {
    // Ouvrir la fenêtre de sélection de fichiers pour les images
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // Limite à l'image
    );

    if (result != null) {
      // Obtenir le chemin de l'image sélectionnée
      _filePath = result.files.single.path;
      setState(() {});
    }
  }

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

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

  update() async {
    setState(() {
      isLoading = true;
    });
    try {
      Map<String, dynamic> data = {
        "username": usernameController.text,
        "email": emailController.text,
        "bio": bioController.text,
        "birthday": dateController.text,
      };

      if (_filePath != null && _filePath!.isNotEmpty) {
        final File file = File(_filePath!);

        if (await file.exists()) {
          String mimeType = 'image/jpeg'; // Valeur par défaut (JPEG)
          String extension = _filePath!.split('.').last.toLowerCase(); // Récupère l'extension du fichier

          if (extension == 'png') {
            mimeType = 'image/png';
          }
          if (extension == 'jpg') {
            mimeType = 'image/jpg';
          }

          // Ajouter la photo dans les données
          data['profile'] = await MultipartFile.fromFile(_filePath!, contentType: DioMediaType.parse(mimeType));
        }
      }

      final formData = FormData.fromMap(data);
      await userService.update(formData, widget.user["id"]);
      Fluttertoast.showToast(msg: "Profil modifié avec succès");
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
                "username": usernameController.text,
                "email": emailController.text,
                "bio": bioController.text,
                "birthday": dateController.text,
              };

              if (_filePath != null && _filePath!.isNotEmpty) {
                final File file = File(_filePath!);

                if (await file.exists()) {
                  String mimeType = 'image/jpeg'; // Valeur par défaut (JPEG)
                  String extension = _filePath!.split('.').last.toLowerCase(); // Récupère l'extension du fichier

                  if (extension == 'png') {
                    mimeType = 'image/png';
                  }
                  if (extension == 'jpg') {
                    mimeType = 'image/jpg';
                  }

                  // Ajouter la photo dans les données
                  data['profile'] = await MultipartFile.fromFile(_filePath!, contentType: DioMediaType.parse(mimeType));
                }
              }

              final formData = FormData.fromMap(data);
              await userService.update(formData, widget.user["id"]);
              Fluttertoast.showToast(msg: "Profil modifié avec succès");
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    bioController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "${widget.user["username"]}", leading: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: (widget.user["profile"] != null && _filePath == null)
                        ? NetworkImage(widget.user["profile"])
                        : (_filePath != null)
                        ? AssetImage(_filePath!)
                        : null,
                    child: (widget.user["profile"] == null && _filePath == null)
                        ? Icon(Icons.person, size: 96, color: Colors.black54)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CB669),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white, size: 24),
                        onPressed: pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32,),
            Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: usernameController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        hintText: "Entrez votre nom d'utilisateur",
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
                      controller: bioController,
                      minLines: 5,
                      maxLines: 10,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: "Entrez votre bio",
                        border: OutlineInputBorder(),
                        prefixIcon: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.info),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      onTap: selectDate,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: "Entrez votre date de naissance",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                    ),
                  ],
                )
            ),
            SizedBox(height: 16,),
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
                  if(formKey.currentState!.validate()) {
                    await update();
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
                  "Enregistrer",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
