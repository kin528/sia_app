import 'package:flutter/material.dart';
import 'module_sheet.dart';
import 'play_panel.dart';
import 'dashboard_panel.dart';
import 'user_profile_panel.dart';
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

  @override
  void reassemble() {
    super.reassemble();
    // Reset to "basic" (welcome) state on hot reload
    _centerContent = null;
  }

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

    // Redirect to login if not authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Use addPostFrameCallback to avoid calling Navigator during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const SizedBox.shrink();
    }

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
