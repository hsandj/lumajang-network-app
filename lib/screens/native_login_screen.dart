import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../config/app_config.dart';
import 'main_dashboard_screen.dart';

class NativeLoginScreen extends StatefulWidget {
  const NativeLoginScreen({super.key});

  @override
  State<NativeLoginScreen> createState() => _NativeLoginScreenState();
}

class _NativeLoginScreenState extends State<NativeLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isWebReady = false;
  String? _errorMessage;

  late final WebViewController _bridgeController;

  @override
  void initState() {
    super.initState();
    _initBridgeWebView();
  }

  void _initBridgeWebView() {
    final WebViewController controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent('${AppConfig.customUserAgentSuffix} Mobile')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            setState(() {
              _isWebReady = true;
            });

            // Jika setelah submit URL berubah bukan ke /login, berarti LOGIN BERHASIL!
            if (!url.endsWith('/login') && !url.contains('/login?')) {
              if (_isLoading) {
                setState(() {
                  _isLoading = false;
                });
                _onLoginSuccess();
              }
            } else if (_isLoading) {
              // Jika masih di /login setelah loading selesai, periksa pesan error dari web
              await Future.delayed(const Duration(milliseconds: 800));
              final errorText = await controller.runJavaScriptReturningResult('''
                (function() {
                  const errorEl = document.querySelector('.alert-danger, .text-red-500, .invalid-feedback');
                  return errorEl ? errorEl.innerText : '';
                })();
              ''');

              String cleanError = errorText.toString().replaceAll('"', '').trim();
              if (cleanError.isEmpty) {
                cleanError = 'Email atau kata sandi tidak cocok. Silakan coba lagi.';
              }

              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = cleanError;
                });
                _showErrorSnackBar(cleanError);
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (_isLoading && (error.isForMainFrame ?? true)) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Gagal terhubung ke server: ${error.description}';
              });
              _showErrorSnackBar(_errorMessage!);
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse('${AppConfig.webUrl}/login'));
    _bridgeController = controller;
  }

  void _onLoginSuccess() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainDashboardScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Injeksi kredensial ke form login web secara aman
    final jsCode = '''
      (function() {
        const emailInput = document.getElementById('email') || document.querySelector('input[name="email"]');
        const passInput = document.getElementById('password') || document.querySelector('input[name="password"]');
        const rememberInput = document.getElementById('remember') || document.querySelector('input[name="remember"]');
        const form = document.querySelector('form');

        if (emailInput && passInput && form) {
          emailInput.value = ${jsonString(email)};
          passInput.value = ${jsonString(password)};
          if (rememberInput) rememberInput.checked = $_rememberMe;

          // Picu submit form
          form.submit();
          return 'submitted';
        }
        return 'form_not_found';
      })();
    ''';

    try {
      await _bridgeController.runJavaScript(jsCode);

      // Timeout fallback setelah 15 detik jika tidak ada respon dari server
      Future.delayed(const Duration(seconds: 15), () {
        if (_isLoading && mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar('Waktu proses masuk habis. Silakan periksa jaringan Anda.');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kendala saat menghubungkan ke sistem.');
      }
    }
  }

  String jsonString(String val) {
    return '"${val.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse('https://wa.me/?text=Halo%20Admin%20Lumajang%20Network,%20saya%20butuh%20bantuan%20login');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Gagal membuka WhatsApp: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient Dekoratif Modern
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppConfig.primaryColor.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppConfig.accentColor.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Hidden Bridge WebView (Untuk memproses sesi login ke web backend)
          Offstage(
            offstage: true,
            child: SizedBox(
              width: 10,
              height: 10,
              child: WebViewWidget(controller: _bridgeController),
            ),
          ),

          // Konten Login Utama Mobile UI
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo Aplikasi
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppConfig.primaryColor.withOpacity(0.35),
                                blurRadius: 25,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.router_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Judul & Tagline
                      const Text(
                        'Lumajang Network',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.textLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ISP Billing & Operational Dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConfig.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Pesan Error Jika Ada
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Card Form Login Bergaya Native Mobile
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppConfig.surfaceDark.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email atau Username',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConfig.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Masukkan email atau nomor HP',
                                hintStyle: TextStyle(color: AppConfig.textMuted.withOpacity(0.6), fontSize: 14),
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppConfig.primaryColor, size: 22),
                                filled: true,
                                fillColor: AppConfig.backgroundDark,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppConfig.primaryColor, width: 1.5),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Harap masukkan email atau username Anda';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            const Text(
                              'Kata Sandi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConfig.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi',
                                hintStyle: TextStyle(color: AppConfig.textMuted.withOpacity(0.6), fontSize: 14),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppConfig.primaryColor, size: 22),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppConfig.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppConfig.backgroundDark,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppConfig.primaryColor, width: 1.5),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Harap masukkan kata sandi Anda';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Ingat Saya & Lupa Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppConfig.primaryColor,
                                        checkColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                        onChanged: (val) {
                                          setState(() {
                                            _rememberMe = val ?? true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ingat Saya',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppConfig.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final uri = Uri.parse('${AppConfig.webUrl}/forgot-password');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Lupa Sandi?',
                                    style: TextStyle(
                                      color: AppConfig.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Tombol Masuk Utama
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: (_isLoading || !_isWebReady) ? null : _submitLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.primaryColor,
                                  disabledBackgroundColor: AppConfig.primaryColor.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppConfig.primaryColor.withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SpinKitThreeBounce(color: Colors.white, size: 20),
                                          SizedBox(width: 14),
                                          Text(
                                            'Memverifikasi...',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Masuk ke Dashboard',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Bantuan CS WhatsApp
                      Center(
                        child: TextButton.icon(
                          onPressed: _openWhatsAppSupport,
                          icon: const Icon(Icons.support_agent_rounded, color: AppConfig.accentColor, size: 20),
                          label: const Text(
                            'Butuh Bantuan? Hubungi CS WhatsApp',
                            style: TextStyle(
                              color: AppConfig.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Footer Hak Cipta
                      Text(
                        '© 2026 PT. Reload Media Telematika',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConfig.textMuted.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
