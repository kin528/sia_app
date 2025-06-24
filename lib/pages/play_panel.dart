import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'playmodule1_page.dart';
import 'playmodule2_page.dart';
import 'playmodule3_page.dart';
import 'playmodule4_page.dart';
import 'playmodule5_page.dart';

const String adminUid = 'QVyiObd7HoXTyNQaoxBzRSW0HGK2';

class PlayPanel extends StatelessWidget {
  final VoidCallback? onBack;
  const PlayPanel({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = FirebaseAuth.instance.currentUser?.uid == adminUid;
    return Center(
      key: const ValueKey("play"),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                    tooltip: "Back",
                  ),
                ),
              Icon(Icons.play_arrow_rounded,
                  size: 56, color: theme.primaryColor),
              const SizedBox(height: 16),
              Text(
                "Play Modules",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ...List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: i == 0
                        ? ElevatedButton.icon(
                            icon: Icon(Icons.sports_esports, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              textStyle: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const PlayModule1Page()),
                              );
                            },
                            label: const Text('Play Module 1'),
                          )
                        : i == 1
                            ? ElevatedButton.icon(
                                icon: Icon(Icons.sports_esports, color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  textStyle: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w600),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const PlayModule2Page()),
                                  );
                                },
                                label: const Text('Play Module 2'),
                              )
                            : i == 2
                                ? ElevatedButton.icon(
                                    icon: Icon(Icons.sports_esports, color: Colors.white),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      textStyle: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w600),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const PlayModule3Page()),
                                      );
                                    },
                                    label: const Text('Play Module 3'),
                                  )
                                : i == 3
                                    ? ElevatedButton.icon(
                                        icon: Icon(Icons.sports_esports, color: Colors.white),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade400,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 24),
                                          textStyle: const TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.w600),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => const PlayModule4Page()),
                                          );
                                        },
                                        label: const Text('Play Module 4'),
                                      )
                                    : ElevatedButton.icon(
                                        icon: Icon(Icons.sports_esports, color: Colors.white),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade400,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 24),
                                          textStyle: const TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.w600),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => const PlayModule5Page()),
                                          );
                                        },
                                        label: const Text('Play Module 5'),
                                      ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
