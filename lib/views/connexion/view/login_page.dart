// New file: lib/views/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/nav_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _modes = [
    {"name": "Classic Mode", "emoji": "⚽", "color": Colors.blue},
    {"name": "Light Mode", "emoji": "☀️", "color": Colors.amber},
    {"name": "Pro Analysis Mode", "emoji": "📊", "color": Colors.green},
    {"name": "VAR Vision Mode", "emoji": "📹", "color": Colors.purple},
    {"name": "Referee Mode", "emoji": "👨‍⚖️", "color": Colors.red},
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scanController;

  bool _isLogin = true; // Toggle between login and register
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _scanController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider, ModeProvider modeProvider, String currentLang) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.95),
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "🌐",
                style: TextStyle(
                  fontSize: 40,
                  color: AppColors.getPrimaryColor(
                    AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                    modeProvider.currentMode
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Translations.getChooseLanguage(currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...Translations.getLanguages(currentLang).asMap().entries.map((entry) {
                int idx = entry.key;
                String lang = entry.value;
                String code = idx == 0 ? 'en' : idx == 1 ? 'fr' : 'ar';
                String flag = code == 'en' ? '🇺🇸' : code == 'fr' ? '🇫🇷' : '🇹🇳';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.getTertiaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                      modeProvider.currentMode
                    ).withOpacity(0.1),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.getPrimaryColor(
                            AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                            modeProvider.currentMode
                          ).withOpacity(0.2),
                        ),
                        child: Text(
                          flag,
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.getPrimaryColor(
                              AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                              modeProvider.currentMode
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        lang,
                        style: TextStyle(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: langProvider.currentLanguage == code 
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.getPrimaryColor(
                                AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                                modeProvider.currentMode
                              ),
                            )
                          : null,
                      onTap: () {
                        langProvider.changeLanguage(code);
                        Navigator.pop(ctx);
                        _showSuccessSnackbar(context, 'Language changed to $lang', modeProvider.currentMode);
                      },
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeDialog(BuildContext context, ModeProvider modeProvider, String currentLang) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.95),
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "✨",
                style: TextStyle(
                  fontSize: 40,
                  color: AppColors.getPrimaryColor(
                    AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                    modeProvider.currentMode
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Translations.getChooseMode(currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ..._modes.asMap().entries.map((entry) {
                int index = entry.key;
                var mode = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.getTertiaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                      modeProvider.currentMode
                    ).withOpacity(0.1),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mode['color'].withOpacity(0.2),
                        ),
                        child: Text(
                          mode['emoji'],
                          style: TextStyle(
                            color: mode['color'],
                            fontSize: 24,
                          ),
                        ),
                      ),
                      title: Text(
                        mode['name'],
                        style: TextStyle(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: modeProvider.currentMode == index + 1
                          ? Icon(
                              Icons.check_circle,
                              color: mode['color'],
                            )
                          : null,
                      onTap: () {
                        modeProvider.changeMode(index + 1);
                        Navigator.pop(ctx);
                        _showSuccessSnackbar(context, '${mode['name']} activated', modeProvider.currentMode);
                      },
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message, int mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.getPrimaryColor(
          AppColors.seedColors[mode] ?? AppColors.seedColors[1]!, 
          mode
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Static simulation: just show success and navigate
      _showSuccessSnackbar(context, _isLogin ? 'Login successful!' : 'Registration successful!', Provider.of<ModeProvider>(context, listen: false).currentMode);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const NavPage(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeInOutBack,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('emailRequired', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return Translations.getLoginText('invalidEmail', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('passwordRequired', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Password is required';
    }
    if (value.length < 6) {
      return Translations.getLoginText('passwordMinLength', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('confirmPasswordRequired', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Confirm password is required';
    }
    if (value != _passwordController.text) {
      return Translations.getLoginText('passwordsDoNotMatch', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FootballGridPainter(modeProvider.currentMode),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.15),
                      AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.9),
                      AppColors.getSurfaceColor(modeProvider.currentMode),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                final t = _scanController.value;
                return CustomPaint(
                  painter: _ScanLinePainter(
                    progress: t,
                    mode: modeProvider.currentMode,
                    seedColor: seedColor,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Hero(
                                tag: 'logo',
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                          AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.7),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.4),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/logo.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VAR X PRO ',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextColor(modeProvider.currentMode),
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10,
                                            color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'AI Football Analysis',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _AnimatedEmojiButton(
                              emoji: "🌐",
                              color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                              onPressed: () => _showLanguageDialog(context, langProvider, modeProvider, currentLang),
                            ),
                            const SizedBox(width: 12),
                            _AnimatedEmojiButton(
                              emoji: "✨",
                              color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                              onPressed: () => _showModeDialog(context, modeProvider, currentLang),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Title
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _isLogin 
                                        ? (Translations.getLoginText('loginTitle', currentLang) ?? 'Login') 
                                        : (Translations.getLoginText('registerTitle', currentLang) ?? 'Register'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.9),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      Translations.getLoginText('welcomeMessage', currentLang) ?? 'Welcome to VAR X PRO',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Email Field
                              _CustomTextField(
                                controller: _emailController,
                                label: Translations.getLoginText('email', currentLang) ?? 'Email',
                                validator: _validateEmail,
                                prefixIcon: Icons.email_outlined,
                                seedColor: seedColor,
                                mode: modeProvider.currentMode,
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              _CustomTextField(
                                controller: _passwordController,
                                label: Translations.getLoginText('password', currentLang) ?? 'Password',
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                seedColor: seedColor,
                                mode: modeProvider.currentMode,
                              ),
                              const SizedBox(height: 20),

                              // Confirm Password Field (only for register)
                              if (!_isLogin)
                                _CustomTextField(
                                  controller: _confirmPasswordController,
                                  label: Translations.getLoginText('confirmPassword', currentLang) ?? 'Confirm Password',
                                  obscureText: _obscureConfirmPassword,
                                  validator: _validateConfirmPassword,
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  seedColor: seedColor,
                                  mode: modeProvider.currentMode,
                                ),

                              const SizedBox(height: 20),

                              // Forgot Password (only for login)
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // Static: show snackbar
                                      _showSuccessSnackbar(context, 'Forgot password feature coming soon!', modeProvider.currentMode);
                                    },
                                    child: Text(
                                      Translations.getLoginText('forgotPassword', currentLang) ?? 'Forgot Password?',
                                      style: TextStyle(
                                        color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 40),

                              // Toggle Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _toggleForm,
                                  icon: Icon(
                                    _isLogin ? Icons.person_add : Icons.login,
                                    color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                  ),
                                  label: Text(
                                    _isLogin 
                                      ? (Translations.getLoginText('noAccountRegister', currentLang) ?? 'No account? Register') 
                                      : (Translations.getLoginText('hasAccountLogin', currentLang) ?? 'Have account? Login'),
                                    style: TextStyle(
                                      color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.7),
                          AppColors.getSurfaceColor(modeProvider.currentMode),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: Icon(
                          _isLogin ? Icons.login : Icons.person_add,
                          size: 22,
                        ),
                        label: Text(
                          _isLogin 
                            ? (Translations.getLoginText('loginButton', currentLang) ?? 'LOGIN') 
                            : (Translations.getLoginText('registerButton', currentLang) ?? 'REGISTER'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final Color seedColor;
  final int mode;

  const _CustomTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    required this.seedColor,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.7)) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.5),
        labelStyle: TextStyle(
          color: AppColors.getTextColor(mode).withOpacity(0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.getPrimaryColor(seedColor, mode),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}

// Reuse the same _AnimatedEmojiButton, _FootballGridPainter, _ScanLinePainter from splash_screen.dart
// (Copy them here or import if in a shared file)

class _AnimatedEmojiButton extends StatefulWidget {
  final String emoji;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedEmojiButton({
    required this.emoji,
    required this.color,
    required this.onPressed,
  });

  @override
  __AnimatedEmojiButtonState createState() => __AnimatedEmojiButtonState();
}

class __AnimatedEmojiButtonState extends State<_AnimatedEmojiButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: widget.color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.emoji,
              style: TextStyle(
                color: widget.color,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.04)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final inset = 40.0;
    final rect = Rect.fromLTWH(
      inset,
      inset * 2,
      size.width - inset * 2,
      size.height - inset * 4,
    );
    canvas.drawRect(rect, fieldPaint);

    final midX = rect.center.dy;
    canvas.drawLine(
      Offset(rect.left + rect.width / 2 - 100, midX),
      Offset(rect.left + rect.width / 2 + 100, midX),
      fieldPaint,
    );
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midX), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final int mode;
  final Color seedColor;

  _ScanLinePainter({
    required this.progress,
    required this.mode,
    required this.seedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2),
          AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 80, size.width, 160));

    canvas.drawRect(Rect.fromLTWH(0, y - 80, size.width, 160), line);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, y),
          radius: size.width * 0.25,
        ),
      );

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.25, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mode != mode;
}