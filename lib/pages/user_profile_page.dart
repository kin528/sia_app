import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder user info
    const userInfo = {
      'First Name': 'John',
      'Last Name': 'Doe',
      'Age': '25',
      'Sex': 'Male',
      'Email': 'john.doe@example.com',
    };

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('User Profile'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: theme.primaryColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${userInfo['First Name']} ${userInfo['Last Name']}',
                    style: theme.textTheme.headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userInfo['Email']!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: "First Name",
                    value: userInfo['First Name']!,
                    icon: Icons.badge_outlined,
                  ),
                  _ProfileField(
                    label: "Last Name",
                    value: userInfo['Last Name']!,
                    icon: Icons.badge,
                  ),
                  _ProfileField(
                    label: "Sex",
                    value: userInfo['Sex']!,
                    icon: Icons.wc_outlined,
                  ),
                  _ProfileField(
                    label: "Age",
                    value: userInfo['Age']!,
                    icon: Icons.cake_outlined,
                  ),
                  _ProfileField(
                    label: "Email",
                    value: userInfo['Email']!,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        // Implement navigation to edit profile if needed
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit Profile tapped!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyLarge!
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
