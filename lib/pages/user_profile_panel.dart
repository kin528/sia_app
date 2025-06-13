import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePanel extends StatefulWidget {
  final bool isDialog;
  const UserProfilePanel({super.key, this.isDialog = false});

  @override
  State<UserProfilePanel> createState() => _UserProfilePanelState();
}

class _UserProfilePanelState extends State<UserProfilePanel> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? debugMsg;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    print('Current User: $user');
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        print('Looking for Firestore doc with ID: ${user.uid}');
        print('Doc exists: ${doc.exists}');
        print('Doc data: ${doc.data()}');
        setState(() {
          userData = doc.exists ? doc.data() : null;
          isLoading = false;
          debugMsg =
              'UID: ${user.uid}\nExists: ${doc.exists}\nData: ${doc.data()}';
        });
      } catch (e) {
        setState(() {
          userData = null;
          isLoading = false;
          debugMsg = 'Error: $e';
        });
        print('Error getting profile data: $e');
      }
    } else {
      setState(() {
        userData = null;
        isLoading = false;
        debugMsg = 'No current user';
      });
      print('No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (userData == null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Failed to load profile data.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (debugMsg != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  debugMsg!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: () => _loadUserData(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    } else {
      content = SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 32, child: Icon(Icons.person)),
              const SizedBox(height: 32),
              _ProfileField(
                icon: Icons.person,
                label: 'Name',
                value:
                    "${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}",
              ),
              const SizedBox(height: 16),
              _ProfileField(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: userData!['age'] ?? 'N/A',
              ),
              const SizedBox(height: 16),
              _ProfileField(
                icon: Icons.wc_outlined,
                label: 'Sex',
                value: userData!['sex'] ?? 'N/A',
              ),
              const SizedBox(height: 16),
              _ProfileField(
                icon: Icons.alternate_email,
                label: 'Gmail',
                value: userData!['email'] ??
                    FirebaseAuth.instance.currentUser?.email ??
                    'N/A',
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (widget.isDialog) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isDialog) {
      return Material(
        color: Colors.white,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        child: SizedBox(width: 340, child: content),
      );
    } else {
      return content;
    }
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
