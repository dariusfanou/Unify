import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF4CB669),
        title: Text(
          widget.user["username"],
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: Colors.white
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.user["following"].length,
          itemBuilder: (context, index) {
            print("Affichage following: ${widget.user["following"][index]}");
            return Card(
              elevation: 0,
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: (widget.user["following"][index]["profile"] != null && widget.user["following"][index]["profile"].isNotEmpty)
                          ? NetworkImage(widget.user["following"][index]["profile"])
                          : null,
                      child: (widget.user["following"][index]["profile"] == null || widget.user["following"][index]["profile"].isEmpty)
                          ? Icon(Icons.person, size: 40, color: Colors.black54)
                          : null,
                    ),
                    title: Text("${widget.user["following"][index]["username"]}"),
                    onTap: () {
                      context.push("/user/${widget.user["following"][index]["id"]}");
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
