// lib/views/connexion/view/forgot_password_page.dart
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/views/connexion/view/login_page.dart';
import 'package:VarXPro/views/connexion/view/otp_verifier_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);

    final result = await authProvider.sendForgotPasswordOtp(_emailController.text);
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccessSnackbar(context, Translations.getLoginText('otpSent', currentLang) ?? 'OTP sent to your email', modeProvider.currentMode);
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpVerifierPage(email: _emailController.text, isForPasswordReset: true)));
    } else {
      _showErrorSnackbar(context, result['error'] ?? 'Failed to send OTP', modeProvider.currentMode);
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

  TextDirection _getTextDirection(String lang) {
    return lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }

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
          automaticallyImplyLeading: false, // This removes the default back button
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: seedColor),
                child: ClipOval(child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
              ),
              const SizedBox(width: 10),
              const Text('VAR X PRO', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: seedColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => _showLanguageDialog(context, langProvider, modeProvider, currentLang),
            ),
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: () => _showModeDialog(context, modeProvider, currentLang),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(Translations.getLoginText('forgotPassword', currentLang) ?? 'Forgot Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.getTextColor(modeProvider.currentMode))),
                  const SizedBox(height: 8),
                  Text(Translations.getLoginText('forgotMessage', currentLang) ?? 'Enter your email to reset password', style: TextStyle(fontSize: 14, color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7))),
                  const SizedBox(height: 40),
                  _CustomTextField(
                    controller: _emailController,
                    label: Translations.getLoginText('email', currentLang) ?? 'Email',
                    validator: _validateEmail,
                    prefixEmoji: '📧',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      icon: Icon(Icons.arrow_back, color: seedColor),
                      label: Text(Translations.getLoginText('backToLogin', currentLang) ?? 'Back to Login', style: TextStyle(color: seedColor, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: seedColor), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendOtp,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('📨', style: TextStyle(fontSize: 22)),
              label: Text(
                _isLoading ? (Translations.getLoginText('loading', currentLang) ?? 'Loading...') : (Translations.getLoginText('sendOtp', currentLang) ?? 'Send OTP'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: seedColor, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
            ),
          ),
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
  final Color seedColor;
  final int mode;

  const _CustomTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.prefixEmoji,
    required this.seedColor,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixEmoji != null ? Padding(padding: const EdgeInsets.all(12), child: Text(prefixEmoji!, style: const TextStyle(fontSize: 20))) : null,
        filled: true,
        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.5),
        labelStyle: TextStyle(color: AppColors.getTextColor(mode).withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor.withOpacity(0.2))),
      ),
    );
  }
}