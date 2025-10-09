// lib/views/connexion/view/login_page.dart
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/views/connexion/view/forgot_password_page.dart';
import 'package:VarXPro/views/connexion/view/register_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/nav_bar.dart';

import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider, ModeProvider modeProvider, String currentLang) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _getTextDirection(currentLang),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.getSurfaceColor(modeProvider.currentMode),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text("🌐", style: TextStyle(fontSize: 40, color: AppColors.getPrimaryColor(AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode))),
              const SizedBox(height: 16),
              Text(Translations.getChooseLanguage(currentLang), style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode), fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ...Translations.getLanguages(currentLang).asMap().entries.map((entry) {
                int idx = entry.key;
                String lang = entry.value;
                String code = idx == 0 ? 'en' : idx == 1 ? 'fr' : 'ar';
                String flag = code == 'en' ? '🇺🇸' : code == 'fr' ? '🇫🇷' : '🇹🇳';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: AppColors.getTertiaryColor(AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode).withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.getPrimaryColor(AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode).withOpacity(0.2)),
                      child: Text(flag, style: TextStyle(fontSize: 20, color: AppColors.getPrimaryColor(AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode))),
                    ),
                    title: Text(lang, style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode), fontSize: 16, fontWeight: FontWeight.w600)),
                    trailing: langProvider.currentLanguage == code ? Icon(Icons.check_circle, color: AppColors.getPrimaryColor(AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode)) : null,
                    onTap: () {
                      langProvider.changeLanguage(code);
                      Navigator.pop(ctx);
                      _showSuccessSnackbar(context, 'Language changed to $lang', modeProvider.currentMode);
                    },
                  ),
                );
              }).toList(),
            ]),
          ),
        ),
      ),
    );
  }

  void _showModeDialog(BuildContext context, ModeProvider modeProvider, String currentLang) {
    final List<Map<String, dynamic>> _modes = [
      {"name": "Classic Mode", "emoji": "⚽", "color": Colors.blue},
      {"name": "Light Mode", "emoji": "☀️", "color": Colors.amber},
      {"name": "Pro Analysis Mode", "emoji": "📊", "color": Colors.green},
      {"name": "VAR Vision Mode", "emoji": "📹", "color": Colors.purple},
      {"name": "Referee Mode", "emoji": "👨‍⚖️", "color": Colors.red},
    ];
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _getTextDirection(currentLang),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.getSurfaceColor(modeProvider.currentMode),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text("✨", style: TextStyle(fontSize: 40, color: AppColors.getPrimaryColor(AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode))),
              const SizedBox(height: 16),
              Text(Translations.getChooseMode(currentLang), style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode), fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ..._modes.asMap().entries.map((entry) {
                int index = entry.key;
                var mode = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: AppColors.getTertiaryColor(AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode).withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: mode['color'].withOpacity(0.2)),
                      child: Text(mode['emoji'], style: TextStyle(color: mode['color'], fontSize: 24)),
                    ),
                    title: Text(mode['name'], style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode), fontSize: 16, fontWeight: FontWeight.w600)),
                    trailing: modeProvider.currentMode == index + 1 ? Icon(Icons.check_circle, color: mode['color']) : null,
                    onTap: () {
                      modeProvider.changeMode(index + 1);
                      Navigator.pop(ctx);
                      _showSuccessSnackbar(context, '${mode['name']} activated', modeProvider.currentMode);
                    },
                  ),
                );
              }).toList(),
            ]),
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message, int mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.getPrimaryColor(AppColors.seedColors[mode] ?? AppColors.seedColors[1]!, mode),
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message, int mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);

    final response = await authProvider.login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (response.success) {
      _showSuccessSnackbar(context, Translations.getLoginText('loginSuccess', currentLang) ?? 'Login successful!', modeProvider.currentMode);
      _navigateToNavPage(useReplacement: true);
    } else {
      _showErrorSnackbar(context, response.error ?? 'Login failed', modeProvider.currentMode);
    }
  }

  void _continueAsVisitor() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    Provider.of<AuthProvider>(context, listen: false).setAsVisitor();
    _showSuccessSnackbar(context, Translations.getLoginText('visitorMode', currentLang) ?? 'Continuing as Visitor', modeProvider.currentMode);
    _navigateToNavPage(useReplacement: true);
  }

  void _navigateToNavPage({required bool useReplacement}) {
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, __, ___) => const NavPage(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );
    if (useReplacement) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  String? _validateEmail(String? value) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('emailRequired', currentLang) ?? 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return Translations.getLoginText('invalidEmail', currentLang) ?? 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('passwordRequired', currentLang) ?? 'Password is required';
    }
    if (value.length < 6) {
      return Translations.getLoginText('passwordMinLength', currentLang) ?? 'Password must be at least 6 characters';
    }
    return null;
  }

  TextDirection _getTextDirection(String lang) => lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return Directionality(
      textDirection: _getTextDirection(currentLang),
      child: Scaffold(
        backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: seedColor),
              child: ClipOval(child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 10),
            const Text('VAR X PRO', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: seedColor,
          actions: [
            IconButton(icon: const Icon(Icons.language), onPressed: () => _showLanguageDialog(context, langProvider, modeProvider, currentLang)),
            IconButton(icon: const Icon(Icons.brightness_6), onPressed: () => _showModeDialog(context, modeProvider, currentLang)),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // Lottie animation at the top
                SizedBox(
                  height: 250,
                  child: Lottie.asset(
                    'assets/lotties/welcom.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text(Translations.getLoginText('loginTitle', currentLang) ?? 'Welcome Back',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.getTextColor(modeProvider.currentMode))),
                const SizedBox(height: 8),
                Text(Translations.getLoginText('welcomeMessage', currentLang) ?? 'Sign in to your account',
                    style: TextStyle(fontSize: 14, color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7))),
                const SizedBox(height: 24),

                // Carte semi-transparente pour lisibilité
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: seedColor.withOpacity(0.18)),
                  ),
                  child: Column(children: [
                    _CustomTextField(
                      controller: _emailController,
                      label: Translations.getLoginText('email', currentLang) ?? 'Email',
                      validator: _validateEmail,
                      prefixEmoji: '📧',
                      seedColor: seedColor,
                      mode: modeProvider.currentMode,
                    ),
                    const SizedBox(height: 16),
                    _CustomTextField(
                      controller: _passwordController,
                      label: Translations.getLoginText('password', currentLang) ?? 'Password',
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      prefixEmoji: '🔒',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      seedColor: seedColor,
                      mode: modeProvider.currentMode,
                    ),
                  ]),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                    child: Text(Translations.getLoginText('forgotPassword', currentLang) ?? 'Forgot Password?',
                        style: TextStyle(color: seedColor, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                    icon: const Text('👤', style: TextStyle(fontSize: 20)),
                    label: Text(Translations.getLoginText('noAccountRegister', currentLang) ?? 'No account? Register here',
                        style: TextStyle(color: seedColor, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: seedColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _login,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('🔑', style: TextStyle(fontSize: 22)),
                label: Text(
                  _isLoading
                      ? (Translations.getLoginText('loading', currentLang) ?? 'Loading...')
                      : (Translations.getLoginText('loginButton', currentLang) ?? 'SIGN IN'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: seedColor,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _continueAsVisitor,
                icon: const Icon(Icons.visibility),
                label: Text(Translations.getLoginText('continueAsVisitor', currentLang) ?? 'Continue as Visitor',
                    style: TextStyle(color: seedColor, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: seedColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? prefixEmoji;
  final Widget? suffixIcon;
  final bool obscureText;
  final Color seedColor;
  final int mode;

  const _CustomTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.prefixEmoji,
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
        prefixIcon: prefixEmoji != null ? Padding(padding: const EdgeInsets.all(12), child: Text(prefixEmoji!, style: const TextStyle(fontSize: 20))) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.55),
        labelStyle: TextStyle(color: AppColors.getTextColor(mode).withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor.withOpacity(0.2))),
      ),
    );
  }
}