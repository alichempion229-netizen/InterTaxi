import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInScreen extends StatefulWidget {
  final Future<void> Function(BuildContext context) onSignedIn;

  const GoogleSignInScreen({super.key, required this.onSignedIn});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _isSigningIn = false;

  Future<void> _signIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      await widget.onSignedIn(context);
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Воридшавӣ бо Google муваффақ нашуд.');
    } catch (error) {
      _showError('Хатои воридшавӣ: $error');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF3F8FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F8FF),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final compact = size.height < 700;
            final logoSize = compact ? 122.0 : 144.0;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF3F8FF)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: SizedBox(
                        height: size.width * 1.15 * (369 / 852),
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.bottomCenter,
                            minWidth: size.width * 1.15,
                            maxWidth: size.width * 1.15,
                            minHeight: size.width * 1.15 * (369 / 852),
                            maxHeight: size.width * 1.15 * (369 / 852),
                            child: Image.asset(
                              'assets/images/skyline.png',
                              width: size.width * 1.15,
                              height: size.width * 1.15 * (369 / 852),
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (context, error, stackTrace) =>
                                  SizedBox(
                                    width: size.width * 1.15,
                                    height: size.width * 1.15 * (369 / 852),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _TopWavePainter()),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Spacer(flex: 27),
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A0B6BFF),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.asset(
                                'assets/icon.png',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.local_taxi_rounded,
                                      size: 72,
                                      color: Color(0xFF1769E0),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              children: const [
                                TextSpan(
                                  text: 'Хуш омадед ба\n',
                                  style: TextStyle(color: Color(0xFF0B1B3F)),
                                ),
                                TextSpan(
                                  text: 'InterTaxi',
                                  style: TextStyle(color: Color(0xFF0A6CFF)),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: compact ? 14 : 20),
                          Text(
                            'Бо Google ворид шавед,\nто идома дихед',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF5B6B8C),
                              fontSize: compact ? 15 : 16,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: compact ? 24 : 28),
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSigningIn ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B6BFF),
                                disabledBackgroundColor: const Color(
                                  0xFF0B6BFF,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 12,
                                shadowColor: const Color(0x400B6BFF),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              child: _isSigningIn
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/google_g.png',
                                              width: 34,
                                              height: 34,
                                              fit: BoxFit.contain,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => const Text(
                                                'G',
                                                style: TextStyle(
                                                  color: Color(0xFF4285F4),
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 28,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          color: Colors.white.withValues(
                                            alpha: .4,
                                          ),
                                        ),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Бо Google идома дихед',
                                              maxLines: 1,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const Spacer(flex: 53),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCE9FB).withValues(alpha: .55);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .43, 0)
      ..cubicTo(
        size.width * .34,
        size.height * .12,
        size.width * .12,
        size.height * .14,
        0,
        size.height * .265,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
