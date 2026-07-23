import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Password strength ──────────────────────────────────────────────────────
  double get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    double score = 0;
    if (p.length >= 6) score += 0.25;
    if (p.length >= 10) score += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) score += 0.25;
    if (p.contains(RegExp(r'[0-9!@#\$%^&*]'))) score += 0.25;
    return score;
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 0.25) return Colors.redAccent;
    if (s <= 0.5) return Colors.orange;
    if (s <= 0.75) return Colors.amber;
    return AppColors.primary;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s <= 0.25) return 'Weak';
    if (s <= 0.5) return 'Fair';
    if (s <= 0.75) return 'Good';
    return 'Strong';
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created! Welcome, ${result.user?.username}.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────────────────────────
          Positioned(
            top: -60,
            left: -80,
            child: _blob(220, AppColors.primary, 0.06),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _blob(260, AppColors.primary, 0.05),
          ),
          // ── Back button ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          // ── Scrollable content ───────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 64, 28, 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: size.height - 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Headline
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            children: [
                              TextSpan(text: 'Create your\n'),
                              TextSpan(
                                text: 'FootyAI ',
                                style: TextStyle(color: AppColors.primary),
                              ),
                              TextSpan(text: 'account'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join millions of football fans powered by AI.',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _usernameCtrl,
                                label: 'Username',
                                hint: 'e.g. football_fan99',
                                icon: Icons.person_outline_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Username is required';
                                  if (v.trim().length < 3)
                                    return 'At least 3 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailCtrl,
                                label: 'Email address',
                                hint: 'you@example.com',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Email is required';
                                  final emailRegex = RegExp(
                                      r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                                  if (!emailRegex.hasMatch(v.trim()))
                                    return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Password with strength meter
                              StatefulBuilder(
                                builder: (ctx, setLocalState) =>
                                    _buildTextField(
                                  controller: _passwordCtrl,
                                  label: 'Password',
                                  hint: 'Min. 6 characters',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  onChanged: (_) =>
                                      setLocalState(() {}), // redraw meter
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Password is required';
                                    if (v.length < 6)
                                      return 'At least 6 characters';
                                    return null;
                                  },
                                ),
                              ),
                              // Strength bar
                              if (_passwordCtrl.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildStrengthBar(),
                              ],
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _confirmCtrl,
                                label: 'Confirm Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscureConfirm,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() =>
                                      _obscureConfirm = !_obscureConfirm),
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Please confirm your password';
                                  if (v != _passwordCtrl.text)
                                    return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              _buildPrimaryButton(
                                label: 'Create Account',
                                onPressed:
                                    _isLoading ? null : _handleSignUp,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Log in prompt
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Log In',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(opacity * 1.5), blurRadius: 80),
          ],
        ),
      );

  Widget _buildStrengthBar() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_strengthColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _strengthLabel,
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _strengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Lexend',
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          fontFamily: 'Lexend',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 13,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
