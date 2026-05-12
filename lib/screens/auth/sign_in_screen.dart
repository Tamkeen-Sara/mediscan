import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/translation_service.dart';
import '../../widgets/animated_cards.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Email / Password ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        // If the user is anonymous, link their account instead of creating a
        // new one — this preserves all scan history accumulated as a guest.
        final anon = FirebaseAuth.instance.currentUser;
        if (anon != null && anon.isAnonymous) {
          final credential = EmailAuthProvider.credential(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );
          try {
            await anon.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use' ||
                e.code == 'email-already-in-use') {
              // Account exists — sign in instead (history stays separate)
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: _emailCtrl.text.trim(),
                password: _passwordCtrl.text.trim(),
              );
            } else {
              rethrow;
            }
          }
        } else {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );
        }
      }
      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { setState(() => _loading = false); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final anon = FirebaseAuth.instance.currentUser;
      if (anon != null && anon.isAnonymous) {
        // Link Google credential to anonymous account to preserve history.
        try {
          await anon.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      setState(() => _errorMessage = 'Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Guest ─────────────────────────────────────────────────────────────

  Future<void> _continueAsGuest() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {
      // Proceed even if anonymous sign-in fails
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _goHome();
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────

  /// After any successful sign-in, clear the entire back-stack and land on
  /// home. Using pushNamedAndRemoveUntil prevents a stale sign-in screen
  /// remaining in the back-stack (pressing Back from home would otherwise
  /// navigate back to the sign-in screen).
  void _goHome() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  // ── Forgot password ───────────────────────────────────────────────────

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email address first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (_) {
      setState(() => _errorMessage = 'Could not send reset email.');
    }
  }

  // ── Error mapping ─────────────────────────────────────────────────────

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return 'Authentication error. Please try again.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeInCard(
                    delay: const Duration(milliseconds: 60),
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_outlined,
                              color: AppColors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'MediScan',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLogin
                              ? tr(AppStrings.signIn)
                              : tr(AppStrings.createAccount),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Google Sign-In
                  FadeInCard(
                    delay: const Duration(milliseconds: 120),
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight),
                        ),
                        icon: const Icon(Icons.g_mobiledata,
                            size: 28, color: AppColors.primaryBlue),
                        label: Text(tr(AppStrings.signInWithGoogle)),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child:
                            Text('or', style: TextStyle(fontSize: 13)),
                      ),
                      Expanded(child: Divider()),
                    ]),
                  ),

                  // Email
                  FadeInCard(
                    delay: const Duration(milliseconds: 180),
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: tr(AppStrings.email),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required.';
                        }
                        if (!v.contains('@')) return 'Enter a valid email.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  FadeInCard(
                    delay: const Duration(milliseconds: 230),
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: tr(AppStrings.password),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required.';
                        }
                        if (!_isLogin && v.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Forgot password
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text(tr(AppStrings.forgotPassword),
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ),

                  // Error banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    FadeInCard(
                      delay: const Duration(milliseconds: 280),
                      padding: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusRedTintDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.statusRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.statusRed, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit button
                  FadeInCard(
                    delay: const Duration(milliseconds: 330),
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.white),
                              )
                            : Text(
                                _isLogin
                                    ? tr(AppStrings.signIn)
                                    : tr(AppStrings.createAccount),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Toggle login / register
                  TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    }),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? ${tr(AppStrings.createAccount)}"
                          : "Already have an account? ${tr(AppStrings.signIn)}",
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Guest
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continue as Guest'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
