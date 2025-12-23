// lib/features/auth/screens/register_screen.dart
// شاشة التسجيل - تصميم حديث ونظيف

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar('يجب الموافقة على الشروط والأحكام', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    final success = await authProvider.signUpWithEmail(
      email,
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: email),
        ),
      );
    } else {
      _showSnackBar(authProvider.error ?? 'حدث خطأ', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.grey.shade700,
            size: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildSteps(),
                  const SizedBox(height: 36),
                  _buildForm(),
                  const SizedBox(height: 32),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'إنشاء حساب جديد',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'أدخل بياناتك للبدء',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildSteps() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(1, true),
        _stepLine(false),
        _stepDot(2, false),
        _stepLine(false),
        _stepDot(3, false),
      ],
    );
  }

  Widget _stepDot(int num, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1A1A2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$num',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: active ? const Color(0xFF10B981) : Colors.grey.shade200,
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          _label('الاسم الكامل'),
          const SizedBox(height: 8),
          _textField(
            controller: _nameController,
            hint: 'أدخل اسمك',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (v.trim().length < 3) return '3 أحرف على الأقل';
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Email
          _label('البريد الإلكتروني'),
          const SizedBox(height: 8),
          _textField(
            controller: _emailController,
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'بريد غير صالح';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Password
          _label('كلمة المرور'),
          const SizedBox(height: 8),
          _textField(
            controller: _passwordController,
            hint: '6 أحرف على الأقل',
            obscureText: _obscurePassword,
            suffix: _visibilityToggle(_obscurePassword, () {
              setState(() => _obscurePassword = !_obscurePassword);
            }),
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (v.length < 6) return '6 أحرف على الأقل';
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Confirm Password
          _label('تأكيد كلمة المرور'),
          const SizedBox(height: 8),
          _textField(
            controller: _confirmPasswordController,
            hint: 'أعد إدخال كلمة المرور',
            obscureText: _obscureConfirm,
            suffix: _visibilityToggle(_obscureConfirm, () {
              setState(() => _obscureConfirm = !_obscureConfirm);
            }),
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (v != _passwordController.text) return 'غير متطابقة';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Terms
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  activeColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Text.rich(
                    TextSpan(
                      text: 'أوافق على ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      children: const [
                        TextSpan(
                          text: 'الشروط والأحكام',
                          style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(
                  0xFF1A1A2E,
                ).withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'إنشاء الحساب',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B5563),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textDirection: textDirection,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
      validator: validator,
    );
  }

  Widget _visibilityToggle(bool obscure, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لديك حساب؟',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'تسجيل الدخول',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }
}
