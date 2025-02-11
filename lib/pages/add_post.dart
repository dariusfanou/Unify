import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unify/custom_appbar.dart';
import 'package:unify/flutter_helpers/services/post_service.dart';
import 'package:unify/flutter_helpers/services/user_service.dart';

import '../auth_provider.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {

  final formKey = GlobalKey<FormState>();
  final contentController = TextEditingController();
  bool isLoading = false;
  final postService = PostService();
  final userService = UserService();
  late AuthProvider authProvider;

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

  create() async {
    setState(() {
      isLoading = true;
    });
    try {
      Map<String, dynamic> data = {
        "content": contentController.text
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
          data['image'] = await MultipartFile.fromFile(_filePath!, contentType: DioMediaType.parse(mimeType));
        }
      }

      final formData = FormData.fromMap(data);
      await postService.create(formData);
      contentController.text = "";
      context.push("/home");
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
              Map<String, dynamic> data = {
                "content": contentController.text
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
                  data['image'] = await MultipartFile.fromFile(_filePath!, contentType: DioMediaType.parse(mimeType));
                }
              }

              final formData = FormData.fromMap(data);
              await postService.create(formData);
              contentController.text = "";
              context.push('/home');
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
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "UNIFY", leading: false,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
                key: formKey,
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  minLines: 5,
                  maxLines: 10,
                  controller: contentController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Que voulez-vous dire ?"
                  ),
                  validator: (value) {
                    return (value == null || value.isEmpty) ? "Ce champ est obligatoire" : null;
                  },
                )
            ),
            TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await pickImage();
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.image),
                    SizedBox(width: 8,),
                    Text("Ajouter une image")
                  ],
                )
            ),
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
                  "Publier",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            (_filePath != null) ?
            Image.asset(
              _filePath!,
              width: double.infinity,
              height: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            )
          : SizedBox()
          ],
        ),
      ),
    );
  }
}
