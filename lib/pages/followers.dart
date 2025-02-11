import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>{

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
          itemCount: widget.user["followers"].length,
          itemBuilder: (context, index) {
            print("Affichage follower: ${widget.user["followers"][index]}");
            return Card(
              elevation: 0,
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: (widget.user["followers"][index]["profile"] != null && widget.user["followers"][index]["profile"].isNotEmpty)
                          ? NetworkImage(widget.user["followers"][index]["profile"])
                          : null,
                      child: (widget.user["followers"][index]["profile"] == null || widget.user["followers"][index]["profile"].isEmpty)
                          ? Icon(Icons.person, size: 40, color: Colors.black54)
                          : null,
                    ),
                    title: Text("${widget.user["followers"][index]["username"]}"),
                    onTap: () {
                      context.push("/user/${widget.user["followers"][index]["id"]}");
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
