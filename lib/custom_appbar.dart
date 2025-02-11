import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, required this.leading});

  final String title;
  final bool leading;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isSearchActive = false;
  final formKey = GlobalKey<FormState>();
  final searchController = TextEditingController();
  late AuthProvider authProvider;

  logout() {
    authProvider.logout();
    context.go("/login");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: widget.leading,
      iconTheme: IconThemeData(color: Colors.white),
      backgroundColor: const Color(0xFF4CB669),
      title: _isSearchActive
          ? Form(
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
                context.push("/search?query=$query");
              }
            },
          )
      )
          : Text(
        widget.title,
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
          color: Colors.white
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearchActive ? Icons.close : Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) {
                searchController.clear();
              }
            });
          },
        ),
        IconButton(
            onPressed: () async {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Déconnexion"),
                      content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              context.pop("Non");
                            },
                            child: const Text("Non", style: TextStyle(color: Colors.black54),)
                        ),
                        TextButton(
                            onPressed: () async {
                              await logout();
                            },
                            child: const Text("Oui", style: TextStyle(color: Colors.red),)
                        ),
                      ],
                    );
                  }
              );
            },
            icon: Icon(Icons.logout,)
        ),
      ],
    );
  }
}
