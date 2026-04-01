import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class IdeasScreen extends StatefulWidget {
  final String userId;
  IdeasScreen({required this.userId});

  @override
  _IdeasScreenState createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  final _controller = TextEditingController();

  void _addIdea() {
    if (_controller.text.isNotEmpty) {
      _firestore.addIdea(widget.userId, _controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Идеи'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: InputDecoration(labelText: 'Новая идея'))),
                IconButton(icon: Icon(Icons.send), onPressed: _addIdea),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.getIdeas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['text'] ?? ''),
                      subtitle: Text('Автор: ${data['userId']}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}