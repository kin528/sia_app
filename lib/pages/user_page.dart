import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Add a reusable right/left border decoration for content area
final BoxDecoration contentBorderDecoration = BoxDecoration(
  color: Colors.white,
  border: Border(
    right: BorderSide(
      color: Colors.grey.shade300,
      width: 2,
    ),
    left: BorderSide(
      color: Colors.grey.shade300,
      width: 2,
    ),
  ),
);

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String? _centerContent; // "modules", "play", "dashboard" or null

  void _showModules() {
    setState(() {
      _centerContent = "modules";
    });
    if (_menuOpen) _closeMobileMenu();
  }

  void _showPlay() {
    setState(() {
      _centerContent = "play";
    });
    if (_menuOpen) _closeMobileMenu();
  }

  void _showDashboard() {
    setState(() {
      _centerContent = "dashboard";
    });
    if (_menuOpen) _closeMobileMenu();
  }

  void _showWelcome() {
    setState(() {
      _centerContent = null;
    });
    if (_menuOpen) _closeMobileMenu();
  }

  void _openProfile(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    if (isWide) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.4,
            heightFactor: 1,
            child: Material(
              elevation: 8,
              color: Colors.transparent,
              child: UserProfilePanel(isDialog: true),
            ),
          ),
        ),
      );
    } else {
      Scaffold.of(context).openEndDrawer();
    }
  }

  // ---- For mobile menu ----
  bool _menuOpen = false;
  void _toggleMobileMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
    });
  }

  void _closeMobileMenu() {
    setState(() {
      _menuOpen = false;
    });
  }
  // ------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.primaryColor,
        elevation: 1,
        title: isMobile
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _toggleMobileMenu, // Toggle menu on tap
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Interactive Academy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ],
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Builder(
              builder: (context) => IconButton(
                onPressed: () => _openProfile(context),
                icon: const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.person),
                ),
                tooltip: 'Profile',
              ),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: UserProfilePanel(),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isWide) {
                  // ALL NAVIGATION BUTTONS ON THE LEFT PANEL
                  return Row(
                    children: [
                      // Left-side buttons (includes Dashboard)
                      Container(
                        width: 220,
                        padding: const EdgeInsets.symmetric(
                            vertical: 48, horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _SideSquareButton(
                              icon: Icons.menu_book_rounded,
                              label: "Module",
                              color: Colors.orange.shade400,
                              onTap: _showModules,
                              selected: _centerContent == "modules",
                            ),
                            const SizedBox(height: 24),
                            _SideSquareButton(
                              icon: Icons.play_arrow_rounded,
                              label: "Play",
                              color: Colors.green.shade400,
                              onTap: _showPlay,
                              selected: _centerContent == "play",
                            ),
                            const SizedBox(height: 24),
                            _SideSquareButton(
                              icon: Icons.dashboard_rounded,
                              label: "Dashboard",
                              color: Colors.blue.shade400,
                              onTap: _showDashboard,
                              selected: _centerContent == "dashboard",
                            ),
                          ],
                        ),
                      ),
                      // Center content with left and right border
                      Expanded(
                        child: Container(
                          decoration: contentBorderDecoration,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildCenterContent(theme),
                          ),
                        ),
                      ),
                      // No right-side panel
                    ],
                  );
                } else {
                  // MOBILE: All buttons in burger/slide menu
                  return Stack(
                    children: [
                      // Main content with left and right border
                      Container(
                        decoration: contentBorderDecoration,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildCenterContent(theme),
                        ),
                      ),
                      // Burger slide menu overlay
                      if (_menuOpen)
                        GestureDetector(
                          onTap: _closeMobileMenu,
                          child: Container(
                            color: Colors.black.withOpacity(0.25),
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      if (_menuOpen)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _closeMobileMenu,
                            behavior: HitTestBehavior.opaque,
                            child: Material(
                              elevation: 12,
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                              child: SizedBox(
                                width: 240,
                                height: double.infinity,
                                child: SafeArea(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 32),
                                      _SideSquareButton(
                                        icon: Icons.menu_book_rounded,
                                        label: "Module",
                                        color: Colors.orange.shade400,
                                        onTap: _showModules,
                                        selected: _centerContent == "modules",
                                      ),
                                      const SizedBox(height: 24),
                                      _SideSquareButton(
                                        icon: Icons.play_arrow_rounded,
                                        label: "Play",
                                        color: Colors.green.shade400,
                                        onTap: _showPlay,
                                        selected: _centerContent == "play",
                                      ),
                                      const SizedBox(height: 24),
                                      _SideSquareButton(
                                        icon: Icons.dashboard_rounded,
                                        label: "Dashboard",
                                        color: Colors.blue.shade400,
                                        onTap: _showDashboard,
                                        selected: _centerContent == "dashboard",
                                      ),
                                      const Spacer(),
                                      const SizedBox(height: 8)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(ThemeData theme) {
    switch (_centerContent) {
      case "modules":
        return ModuleSheet(
          isDialog: false,
          isStandalone: true,
          onBack: _showWelcome,
        );
      case "play":
        return PlayPanel(
          onBack: _showWelcome,
        );
      case "dashboard":
        return DashboardPanel(
          onBack: _showWelcome,
        );
      default:
        // Welcome/empty state
        return Center(
          key: const ValueKey("welcome"),
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded, size: 64, color: theme.primaryColor),
                const SizedBox(height: 28),
                Text(
                  "Welcome to Smart Interactive Academy!",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  "Select a module to learn, or play interactive challenges.",
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }
}

// Big square button for side menu
class _SideSquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  const _SideSquareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.25) : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: color.withOpacity(0.3),
        child: Container(
          width: 160,
          height: 160,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: 40,
                child: Icon(icon, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.darken(0.1),
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class ModuleSheet extends StatelessWidget {
  final bool isDialog;
  final bool isStandalone;
  final VoidCallback? onBack;
  const ModuleSheet(
      {super.key,
      this.isDialog = false,
      this.isStandalone = false,
      this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDialog
            ? const BorderRadius.horizontal(left: Radius.circular(24))
            : BorderRadius.circular(24),
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
          if (isStandalone && onBack != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: "Back",
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            "Select a Module",
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          for (int i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.book, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Module $i tapped!')),
                    );
                  },
                  label: Text('Module $i'),
                ),
              ),
            ),
        ],
      ),
    );

    if (isDialog) {
      return Material(
        color: Colors.white,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        child: SizedBox(
          width: 360,
          child: child,
        ),
      );
    }
    return Center(
      key: const ValueKey("modules"),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child,
      ),
    );
  }
}

class PlayPanel extends StatelessWidget {
  final VoidCallback? onBack;
  const PlayPanel({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    child: ElevatedButton.icon(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Play Module ${i + 1} tapped!')),
                        );
                      },
                      label: Text('Play Module ${i + 1}'),
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

class DashboardPanel extends StatelessWidget {
  final VoidCallback? onBack;
  const DashboardPanel({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey("dashboard"),
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
              Icon(Icons.dashboard_rounded,
                  size: 56, color: theme.primaryColor),
              const SizedBox(height: 16),
              Text(
                "Dashboard",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // You can put your dashboard widgets here
              Text(
                "This is the dashboard area.",
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfilePanel extends StatefulWidget {
  final bool isDialog;
  const UserProfilePanel({super.key, this.isDialog = false});

  @override
  State<UserProfilePanel> createState() => _UserProfilePanelState();
}

class _UserProfilePanelState extends State<UserProfilePanel> {
  List<DateTime> loginHistory = [];

  @override
  void initState() {
    super.initState();
    _loadLoginHistory();
  }

  Future<void> _loadLoginHistory() async {
    if (loginHistory.isEmpty) {
      setState(() {
        loginHistory.add(DateTime.now());
      });
    }
  }

  void _showLoginHistory(BuildContext context) {
    if (loginHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No login history found.")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login History'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: loginHistory.length,
            itemBuilder: (context, index) {
              final dt = loginHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}",
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? 'N/A';
    String name = displayName;
    String age = 'N/A';
    String sex = 'N/A';
    String gmail = user?.email ?? 'N/A';

    if (displayName.contains('|')) {
      final parts = displayName.split('|');
      if (parts.length >= 3) {
        name = parts[0];
        age = parts[1];
        sex = parts[2];
      }
    }

    Widget panel = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar only
            Row(
              children: const [
                CircleAvatar(
                  radius: 32,
                  child: Icon(Icons.person),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _ProfileField(
              icon: Icons.person,
              label: 'Name',
              value: name,
            ),
            const SizedBox(height: 16),
            _ProfileField(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: age,
            ),
            const SizedBox(height: 16),
            _ProfileField(
              icon: Icons.wc_outlined,
              label: 'Sex',
              value: sex,
            ),
            const SizedBox(height: 16),
            _ProfileField(
              icon: Icons.alternate_email,
              label: 'Gmail',
              value: gmail,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Login History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _showLoginHistory(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
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
                        Navigator.of(context).pop(); // Close dialog
                      } else {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.isDialog) {
      return Material(
        color: Colors.white,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        child: SizedBox(width: 340, child: panel),
      );
    } else {
      return panel;
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
