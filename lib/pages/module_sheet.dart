import 'package:flutter/material.dart';
import 'module1_page.dart';
import 'module2_page.dart';
import 'module3_page.dart';
import 'module4_page.dart';
import 'module5_page.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final maxWidth = isWide ? 480.0 : double.infinity;

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
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 12, vertical: isWide ? 32 : 16),
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
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: isWide ? 28 : 20),
          ),
          const SizedBox(height: 24),
          for (int i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.book, color: Colors.white, size: isWide ? 32 : 24),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isWide ? 28 : 18),
                    textStyle: TextStyle(
                        fontSize: isWide ? 22 : 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                    ),
                  ),
                  onPressed: () {
                    if (i == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const Module1Page()),
                      );
                    } else if (i == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const Module2Page()),
                      );
                    } else if (i == 3) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const Module3Page()),
                      );
                    } else if (i == 4) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const Module4Page()),
                      );
                    } else if (i == 5) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const Module5Page()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Module $i tapped!')),
                      );
                    }
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
          width: isWide ? 360 : 280,
          child: child,
        ),
      );
    }
    return Center(
      key: const ValueKey("modules"),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
