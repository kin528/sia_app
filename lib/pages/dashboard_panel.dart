import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String adminUid = 'QVyiObd7HoXTyNQaoxBzRSW0HGK2';
const List<String> moduleIds = [
  'module1',
  'module2',
  'module3',
  'module4',
  'module5',
];

class DashboardPanel extends StatelessWidget {
  final VoidCallback? onBack;
  const DashboardPanel({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user != null && user.uid == adminUid;
    return Center(
      key: const ValueKey("dashboard"),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
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
          child: isAdmin
              ? _AdminDashboard(onBack: onBack)
              : _StudentDashboard(onBack: onBack),
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final VoidCallback? onBack;
  const _AdminDashboard({this.onBack});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('admin')
          .doc('students')
          .collection('users')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Firestore error in admin dashboard: \\${snapshot.error}');
          return Center(
            child: Text('Error: \\${snapshot.error}', style: TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data!.docs;
        print('Student docs: \\${students.length}');
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 32,
            vertical: isMobile ? 8 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                children: [
                  Icon(Icons.dashboard_rounded, size: isMobile ? 36 : 56, color: Colors.blue.shade700),
                  const SizedBox(width: 16),
                  Text(
                    "Admin Dashboard",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 22 : 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Total Students: ${students.length}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 20),
              ),
              const SizedBox(height: 24),
              ...List.generate(students.length, (i) {
                final student = students[i].data();
                final userId = students[i].id;
                final name = "${student['firstName'] ?? ''} ${student['lastName'] ?? ''}".trim();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12, top: 4),
                      child: Text(
                        'Student Name: ' + (name.isNotEmpty ? name : userId),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 20 : 28,
                          color: Colors.deepPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _StudentScores(userId: userId, isMobile: isMobile),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StudentScores extends StatelessWidget {
  final String userId;
  final bool isMobile;
  const _StudentScores({required this.userId, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: Future.wait(moduleIds.map((moduleId) async {
        final snap = await FirebaseFirestore.instance
            .collection('Quiz')
            .doc(moduleId)
            .collection('scores')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: false)
            .get();
        return snap.docs.map((d) => d.data()).toList();
      })),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allScores = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < moduleIds.length; i++)
              if (allScores[i].isNotEmpty)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 14 : 22)),
                  margin: EdgeInsets.only(bottom: isMobile ? 18 : 32, left: isMobile ? 0 : 8, right: isMobile ? 0 : 8),
                  color: Colors.white,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 28.0, vertical: isMobile ? 16 : 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${moduleIds[i].replaceAll('module', 'Module ')} Scores:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 20 : 30, letterSpacing: 0.5, color: Colors.black87),
                        ),
                        SizedBox(height: isMobile ? 12 : 24),
                        ...List.generate(allScores[i].length, (j) {
                          final score = allScores[i][j];
                          final take = j + 1;
                          final date = score['timestamp'] != null && score['timestamp'] is Timestamp
                              ? (score['timestamp'] as Timestamp).toDate()
                              : null;
                          String formattedDate = '';
                          if (date != null) {
                            final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
                            final minute = date.minute.toString().padLeft(2, '0');
                            final ampm = date.hour >= 12 ? 'PM' : 'AM';
                            formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $hour:$minute $ampm";
                          }
                          return Column(
                            children: [
                              if (j > 0)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: isMobile ? 4.0 : 8.0),
                                  child: Divider(height: 2, color: Colors.blueAccent, thickness: 2),
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.blueAccent, size: isMobile ? 24 : 36),
                                  SizedBox(width: isMobile ? 10 : 20),
                                  Text(
                                    "Take $take:",
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: isMobile ? 16 : 26, color: Colors.black87),
                                  ),
                                  SizedBox(width: isMobile ? 10 : 18),
                                  Text(
                                    "${score['score']} pts",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 28, color: Colors.blueAccent),
                                  ),
                                  const Spacer(),
                                  if (formattedDate.isNotEmpty)
                                    Text(
                                      formattedDate,
                                      style: TextStyle(fontSize: isMobile ? 14 : 20, color: Colors.grey.shade700, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                              if (j == allScores[i].length - 1)
                                SizedBox(height: isMobile ? 8 : 18), // Extra gap after last take
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _StudentDashboard extends StatelessWidget {
  final VoidCallback? onBack;
  const _StudentDashboard({this.onBack});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Row(
          children: [
            Icon(Icons.dashboard_rounded, size: 56, color: Colors.green.shade700),
            const SizedBox(width: 16),
            Text(
              "My Dashboard",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: [
              for (final moduleId in moduleIds)
                _MyModuleScores(moduleId: moduleId, userId: user.uid),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyModuleScores extends StatelessWidget {
  final String moduleId;
  final String userId;
  const _MyModuleScores({required this.moduleId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('Quiz')
          .doc(moduleId)
          .collection('scores')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: false)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade100.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Error: \\${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final scores = snapshot.data!.docs;
        if (scores.isEmpty) return const SizedBox.shrink();
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          margin: const EdgeInsets.only(bottom: 32, left: 8, right: 8),
          color: Colors.white,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${moduleId.replaceAll('module', 'Module ')} Scores:",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30, letterSpacing: 0.5, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                ...List.generate(scores.length, (i) {
                  final score = scores[i].data();
                  final take = i + 1;
                  final date = score['timestamp'] != null && score['timestamp'] is Timestamp
                      ? (score['timestamp'] as Timestamp).toDate()
                      : null;
                  String formattedDate = '';
                  if (date != null) {
                    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
                    final minute = date.minute.toString().padLeft(2, '0');
                    final ampm = date.hour >= 12 ? 'PM' : 'AM';
                    formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $hour:$minute $ampm";
                  }
                  return Column(
                    children: [
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 2, color: Colors.blueAccent, thickness: 2),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.blueAccent, size: 36),
                          const SizedBox(width: 20),
                          Text(
                            "Take $take:",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: Colors.black87),
                          ),
                          const SizedBox(width: 18),
                          Text(
                            "${score['score']} pts",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.blueAccent),
                          ),
                          const Spacer(),
                          if (formattedDate.isNotEmpty)
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 20, color: Colors.grey.shade700, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      if (i == scores.length - 1)
                        const SizedBox(height: 18), // Extra gap after last take
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
