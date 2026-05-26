import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

const Color _bg = Color(0xFF09090B);
const Color _cardBg = Color(0xFF18181B);
const Color _gold = Color(0xFFD4AF37);
const Color _textSecondary = Color(0xFFA1A1AA);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        setState(() { _error = 'Please enter both email and password'; _loading = false; });
        return;
      }
      final supabase = Supabase.instance.client;
      AuthResponse res;
      if (_isSignUp) {
        res = await supabase.auth.signUp(email: email, password: password);
      } else {
        res = await supabase.auth.signInWithPassword(email: email, password: password);
      }
      final session = res.session;
      if (session != null) {
        ApiService.setToken(session.accessToken);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() { _error = _isSignUp ? 'Sign up successful! Please check your email to confirm.' : 'Session not found. Please try again.'; });
      }
    } on AuthException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
      final session = supabase.auth.currentSession;
      if (session != null) {
        ApiService.setToken(session.accessToken);
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              _gold.withValues(alpha: 0.1),
              _bg,
            ],
            center: const Alignment(0, -0.6),
            radius: 0.8,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.3),
                          blurRadius: 50,
                          spreadRadius: -10,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: _gold.withValues(alpha: 0.6), width: 2.0),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.assured_workload, color: _gold, size: 64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Aarthrakshak',
                      style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: _gold)),
                  const SizedBox(height: 6),
                  Text('Premium Financial Security',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: _textSecondary)),
                  const SizedBox(height: 48),
                  _buildGlassField(
                    controller: _emailController,
                    icon: Icons.alternate_email,
                    label: 'Email',
                    isEmail: true,
                  ),
                  const SizedBox(height: 16),
                  _buildGlassField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    label: 'Password',
                    isObscure: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!,
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _bg,
                        elevation: 10,
                        shadowColor: _gold.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: _bg))
                          : Text(_isSignUp ? 'SIGN UP EXCLUSIVE' : 'SECURE SIGN IN'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR CONNECT WITH',
                            style: GoogleFonts.outfit(
                                fontSize: 11, fontWeight: FontWeight.bold, color: _textSecondary)),
                      ),
                      const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        height: 24,
                      ),
                      label: Text('Google',
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _cardBg.withValues(alpha: 0.5),
                        side: const BorderSide(color: Colors.white12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    style: TextButton.styleFrom(
                      foregroundColor: _gold,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: Text(
                      _isSignUp
                          ? 'MEMBER ALREADY? SIGN IN'
                          : "BECOME A MEMBER",
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.bold),
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

  Widget _buildGlassField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isObscure = false,
    bool isEmail = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
        obscureText: isObscure,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: _textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          prefixIcon: Icon(icon, color: _gold.withValues(alpha: 0.7), size: 22),
        ),
      ),
    );
  }
}
