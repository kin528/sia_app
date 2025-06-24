import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final bool showSplash;
  const LoginPage({super.key, this.showSplash = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late bool _showSplash;

  // Login state
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _showSplash = widget.showSplash;
    if (_showSplash) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Password required. Enter your password to continue.";
      });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/user');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'missing-password') {
        setState(() {
          _errorMessage = "Password required. Enter your password to continue.";
        });
      } else if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        setState(() {
          _errorMessage = "Invalid username or password";
        });
      } else {
        setState(() {
          _errorMessage = e.message;
        });
      }
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _showSplash ? _buildSplash(context) : _buildLogin(context),
      ),
    );
  }

  Widget _buildSplash(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_showSplash) {
          setState(() {
            _showSplash = false;
          });
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                elevation: 8,
                shape: const CircleBorder(),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Icon(Icons.school_rounded,
                      size: 64, color: Color(0xFF1565C0)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Smart Interactive Academy',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  letterSpacing: 1.2,
                  shadows: [
                    const Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 8,
                      color: Colors.black26,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Let's have fun and learn",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  shadows: [
                    const Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Tap anywhere to continue',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogin(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final contentMaxWidth = isWide ? 400.0 : double.infinity;
    final contentPadding = EdgeInsets.all(isWide ? 32.0 : 12.0);

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: contentPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Container(
                padding: EdgeInsets.all(isWide ? 32 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isWide ? 24 : 16),
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
                  children: [
                    Icon(Icons.login_rounded,
                        size: isWide ? 60 : 44, color: theme.primaryColor),
                    SizedBox(height: isWide ? 20 : 12),
                    Text(
                      "Welcome Back!",
                      style: theme.textTheme.headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: isWide ? 28 : 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Log in to continue to your account.",
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: isWide ? 18 : 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocus);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      keyboardType: TextInputType.text,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          tooltip: _obscurePassword
                              ? "Show password"
                              : "Hide password",
                        ),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    EdgeInsets.symmetric(vertical: isWide ? 18 : 14),
                                textStyle: TextStyle(fontSize: isWide ? 20 : 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isWide ? 16 : 12),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: _handleLogin,
                              label: const Text('Log In'),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(fontSize: isWide ? 16 : 13)),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupPage()),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
