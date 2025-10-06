// lib/views/connexion/view/otp_verifier_page.dart
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/views/connexion/view/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/nav_bar.dart';

class OtpVerifierPage extends StatefulWidget {
  final String email;
  final bool isForRegister;
  final bool isForPasswordReset;
  final String? password;
  final String? role;

  const OtpVerifierPage({
    super.key,
    required this.email,
    this.isForRegister = false,
    this.isForPasswordReset = false,
    this.password,
    this.role,
  });

  @override
  State<OtpVerifierPage> createState() => _OtpVerifierPageState();
}

class _OtpVerifierPageState extends State<OtpVerifierPage> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);

    if (widget.isForPasswordReset) {
      final newPass = _newPasswordController.text;
      final confirmPass = _confirmPasswordController.text;
      if (newPass != confirmPass) {
        _showErrorSnackbar(context, Translations.getLoginText('passwordsDoNotMatch', currentLang) ?? 'Passwords do not match', modeProvider.currentMode);
        setState(() => _isLoading = false);
        return;
      }
      final result = await authProvider.resetPassword(email: widget.email, code: _otpController.text, password: newPass, passwordConfirmation: confirmPass);
      setState(() => _isLoading = false);
      if (result['success']) {
        _showSuccessSnackbar(context, Translations.getLoginText('passwordResetSuccess', currentLang) ?? 'Password reset successful!', modeProvider.currentMode);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      } else {
        _showErrorSnackbar(context, result['error'] ?? 'Reset failed', modeProvider.currentMode);
      }
    } else {
      final result = await authProvider.verifyEmailOtp(widget.email, _otpController.text);
      setState(() => _isLoading = false);
      if (result['success']) {
        if (widget.isForRegister) {
          if (widget.role == 'supervisor') {
            _showSuccessSnackbar(context, 'Account created! Awaiting admin approval. You can now login once approved.', modeProvider.currentMode);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          } else {
            final loginResponse = await authProvider.login(widget.email, widget.password!);
            if (loginResponse.success) {
              _showSuccessSnackbar(context, Translations.getLoginText('registerSuccess', currentLang) ?? 'Registration successful!', modeProvider.currentMode);
              _navigateToNavPage();
            } else {
              _showErrorSnackbar(context, loginResponse.error ?? 'Auto-login failed', modeProvider.currentMode);
            }
          }
        } else {
          _showSuccessSnackbar(context, Translations.getLoginText('emailVerified', currentLang) ?? 'Email verified!', modeProvider.currentMode);
          Navigator.pop(context);
        }
      } else {
        _showErrorSnackbar(context, result['error'] ?? 'Verification failed', modeProvider.currentMode);
      }
    }
  }

  void _navigateToNavPage() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(transitionDuration: const Duration(milliseconds: 800), pageBuilder: (_, __, ___) => const NavPage(), transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child)));
  }

  String? _validateOtp(String? value) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('otpRequired', currentLang) ?? 'OTP is required';
    }
    if (value.length != 6) {
      return Translations.getLoginText('otpInvalid', currentLang) ?? 'OTP must be 6 digits';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('passwordRequired', currentLang) ?? 'New password is required';
    }
    if (value.length < 6) {
      return Translations.getLoginText('passwordMinLength', currentLang) ?? 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage ?? 'en';
    if (value == null || value.isEmpty) {
      return Translations.getLoginText('confirmPasswordRequired', currentLang) ?? 'Confirm new password is required';
    }
    if (value != _newPasswordController.text) {
      return Translations.getLoginText('passwordsDoNotMatch', currentLang) ?? 'Passwords do not match';
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
    final title = widget.isForRegister ? Translations.getLoginText('verifyEmailRegister', currentLang) ?? 'Verify Email for Registration' : widget.isForPasswordReset ? Translations.getLoginText('verifyOtpReset', currentLang) ?? 'Reset Password' : Translations.getLoginText('verifyEmail', currentLang) ?? 'Verify Email';
    final subtitle = widget.isForPasswordReset ? 'Enter OTP and new password' : 'We sent a 6-digit code to ${widget.email}';

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
                  Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.getTextColor(modeProvider.currentMode))),
                  const SizedBox(height: 8),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7))),
                  const SizedBox(height: 40),
                  _CustomTextField(
                    controller: _otpController,
                    label: Translations.getLoginText('otpCode', currentLang) ?? 'OTP Code',
                    validator: _validateOtp,
                    prefixEmoji: '🔢',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                  ),
                  if (widget.isForPasswordReset) ...[
                    const SizedBox(height: 20),
                    _CustomTextField(
                      controller: _newPasswordController,
                      label: Translations.getLoginText('newPassword', currentLang) ?? 'New Password',
                      obscureText: _obscureNewPassword,
                      validator: _validateNewPassword,
                      prefixEmoji: '🔒',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                      seedColor: seedColor,
                      mode: modeProvider.currentMode,
                    ),
                    const SizedBox(height: 20),
                    _CustomTextField(
                      controller: _confirmPasswordController,
                      label: Translations.getLoginText('confirmPassword', currentLang) ?? 'Confirm New Password',
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      prefixEmoji: '🔑',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      seedColor: seedColor,
                      mode: modeProvider.currentMode,
                    ),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(Translations.getLoginText('back', currentLang) ?? 'Back', style: TextStyle(color: seedColor))),
                      TextButton(
                        onPressed: () {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          if (widget.isForPasswordReset) {
                            authProvider.sendForgotPasswordOtp(widget.email);
                          } else {
                            authProvider.sendEmailOtp(widget.email);
                          }
                          _showSuccessSnackbar(context, Translations.getLoginText('otpResent', currentLang) ?? 'OTP resent', modeProvider.currentMode);
                        },
                        child: Text(Translations.getLoginText('resendOtp', currentLang) ?? 'Resend OTP', style: TextStyle(color: seedColor)),
                      ),
                    ],
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
              onPressed: _isLoading ? null : _verifyOtp,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('✅', style: TextStyle(fontSize: 22)),
              label: Text(
                _isLoading ? (Translations.getLoginText('loading', currentLang) ?? 'Loading...') : (Translations.getLoginText('verify', currentLang) ?? 'VERIFY'),
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
        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.5),
        labelStyle: TextStyle(color: AppColors.getTextColor(mode).withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: seedColor.withOpacity(0.2))),
      ),
    );
  }
}