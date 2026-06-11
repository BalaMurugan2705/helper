import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/providers.dart';
import '../../services/firebase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();

  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;

  bool _isLogin = true, _loading = false, _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnim = CurvedAnimation(
        parent: _slideCtrl, curve: const Interval(0.1, 1, curve: Curves.easeOut));

    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isLogin) {
        final cred = await auth.signIn(_emailCtrl.text.trim(), _pwCtrl.text);
        if (cred.user != null) {
          await FirebaseService(cred.user!.uid)
              .saveUserProfile(cred.user!.email ?? '');
        }
      } else {
        await auth.signUp(_emailCtrl.text.trim(), _pwCtrl.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _msg(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _msg(String code) {
    switch (code) {
      case 'user-not-found':       return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':   return 'Incorrect email or password.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      case 'invalid-email':        return 'Please enter a valid email address.';
      case 'too-many-requests':    return 'Too many attempts. Please try again later.';
      default:                     return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: Stack(children: [
        // Aurora gradient background
        const Positioned.fill(child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F0D1A),
                Color(0xFF160E2E),
                Color(0xFF12091E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        )),
        // Ambient glow top-left
        Positioned(
          top: -80, left: -60,
          child: _GlowBlob(color: AppColors.accentDashboard, size: 300),
        ),
        // Ambient glow bottom-right
        Positioned(
          bottom: -80, right: -60,
          child: _GlowBlob(color: AppColors.accentHealth, size: 280),
        ),
        SafeArea(child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildCard(),
                ],
              ),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _buildLogo() {
    return Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentDashboard, AppColors.accentPcos],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: AppColors.accentDashboard.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 8),
          )],
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
      ),
      const SizedBox(height: 14),
      Text('HomeSync', style: AppTextStyles.headlineLarge),
      Text(
        'Smart Home Manager',
        style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
      ),
    ]);
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isLogin ? 'Welcome back' : 'Create account',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _isLogin ? 'Sign in to HomeSync' : 'Join HomeSync',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'EMAIL',
                prefixIcon: Icon(Icons.mail_outline_rounded,
                    color: AppColors.textSubtle, size: 18),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your email' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pwCtrl,
              obscureText: _obscure,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'PASSWORD',
                prefixIcon: Icon(Icons.lock_outline_rounded,
                    color: AppColors.textSubtle, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSubtle,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.statusOverdue),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentDashboard,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isLogin ? 'Sign In' : 'Sign Up',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: Colors.white),
                    ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () =>
                  setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? "Don't have an account? Sign Up"
                    : 'Already have an account? Sign In',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accentDashboard.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.12), Colors.transparent],
        ),
      ),
    );
  }
}
