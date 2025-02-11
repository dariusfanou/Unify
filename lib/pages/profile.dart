import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

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
                    "Renseignez une photo à afficher sur votre profil",
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16,),
                  CircleAvatar(
                    radius: 96,
                    backgroundImage: (_filePath != null)
                        ? AssetImage(_filePath!)
                        : null, // Si profile est null, aucune image de fond ne sera affichée
                    child: (_filePath == null)
                        ? Icon(Icons.person, size: 128, color: Colors.black54)
                        : null, // Si une image existe, on ne met pas d'icône
                  ),
                  SizedBox(height: 16,),
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
                      onPressed: () async {
                        await pickImage();
                      },
                      child: Text(
                        "Ajouter une photo",
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
                      onPressed: () {
                        context.push("/birthday");
                      },
                      child: Text(
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
              ),
              (_filePath != null) ?
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
                  onPressed: () async {
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setString("profile", _filePath!);
                    context.push("/birthday");
                  },
                  child: Text(
                    "Suivant",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ): SizedBox()
            ],
          ),
        ),
      ),
    );
  }
}
