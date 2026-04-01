import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final User user;

  const ProfileEditScreen({
    super.key,
    required this.themeMode,
    required this.user,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? "";
  }

  // ---------------- SAVE NAME ONLY ----------------
  Future<void> _save() async {
  setState(() => _loading = true);

  try {
    final newName = _nameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await user.updateDisplayName(newName);
    await user.reload();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'name': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (mounted) {
      setState(() {}); 
      Navigator.pop(context, true);
    }
  } catch (e) {
    debugPrint("ERROR SAVE: $e");
  }

  if (mounted) {
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Редактирование профиля",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// NAME ONLY
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Никнейм",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// SAVE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: const Text("Сохранить"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_loading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}