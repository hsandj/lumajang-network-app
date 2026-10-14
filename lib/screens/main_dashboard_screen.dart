import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../config/app_config.dart';
import 'native_login_screen.dart';
import 'offline_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedTabIndex = 0;
  DateTime? _lastBackPressTime;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    _listenConnectivity();
  }

  void _listenConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Koneksi internet terputus.';
        });
      } else {
        if (_hasError) {
          setState(() {
            _hasError = false;
          });
          _controller.reload();
        }
      }
    });
  }

  void _initWebViewController() {
    final WebViewController controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppConfig.backgroundDark)
      ..setUserAgent('${AppConfig.customUserAgentSuffix} Mobile NativeShell')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });

            // Jika diarahkan kembali ke halaman login (misal sesi habis / logout di web)
            if (url.endsWith('/login') || url.contains('/login?')) {
              _redirectToNativeLogin();
            }
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });

            // Jika halaman selesai dimuat dan ternyata halaman login, alihkan ke tampilan native login
            if (url.endsWith('/login') || url.contains('/login?')) {
              _redirectToNativeLogin();
              return;
            }

            // Injeksi gaya CSS khusus agar tampilan web terasa menyatu seperti aplikasi native
            _injectMobileNativeStyling();
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);

            // Buka WhatsApp, Telepon, Email, dan Intent ke aplikasi eksternal
            if (request.url.startsWith('whatsapp://') ||
                request.url.startsWith('https://wa.me/') ||
                request.url.startsWith('https://api.whatsapp.com/') ||
                request.url.startsWith('tel:') ||
                request.url.startsWith('mailto:') ||
                request.url.startsWith('sms:') ||
                request.url.startsWith('intent://')) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationDecision.prevent;
                }
              } catch (e) {
                debugPrint('Gagal membuka URL eksternal: $e');
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(AppConfig.webUrl));
    _controller = controller;
  }

  // Menginjeksi CSS untuk merapikan layout web agar terlihat native di layar smartphone
  Future<void> _injectMobileNativeStyling() async {
    const css = '''
      (function() {
        // Matikan efek particle background di dashboard untuk hemat baterai & performa halus
        const particles = document.getElementById('particle-bg');
        if (particles) particles.style.display = 'none';

        // Styling mobile native
        const style = document.createElement('style');
        style.innerHTML = `
          /* Hilangkan margin/padding berlebih di mobile */
          body {
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            user-select: none;
            overflow-x: hidden !important;
          }
          /* Perhalus scrollbar */
          ::-webkit-scrollbar {
            display: none !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''';

    try {
      await _controller.runJavaScript(css);
    } catch (_) {}
  }

  void _redirectToNativeLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NativeLoginScreen()),
    );
  }

  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Konfirmasi Keluar', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Lumajang Network?',
          style: TextStyle(color: AppConfig.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppConfig.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Hapus session cookies & cache lalu kembali ke login screen
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
      await _controller.clearCache();
      _redirectToNativeLogin();
    }
  }

  Future<bool> _handleWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tekan sekali lagi untuk keluar dari aplikasi',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppConfig.surfaceDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    switch (index) {
      case 0:
        _controller.loadRequest(Uri.parse(AppConfig.webUrl));
        break;
      case 1:
        _controller.loadRequest(Uri.parse('${AppConfig.webUrl}/billing'));
        break;
      case 2:
        _controller.loadRequest(Uri.parse('${AppConfig.webUrl}/network'));
        break;
      case 3:
        _controller.loadRequest(Uri.parse('${AppConfig.webUrl}/profile'));
        break;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return OfflineScreen(
        onRetry: () {
          setState(() {
            _hasError = false;
            _isLoading = true;
          });
          _controller.reload();
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.backgroundDark,
        // Header Native Mobile App Bar
        appBar: AppBar(
          backgroundColor: AppConfig.backgroundDark,
          elevation: 0,
          titleSpacing: 16,
          leadingWidth: 42,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.router_rounded,
                size: 20,
                color: AppConfig.backgroundDark,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lumajang Network',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.textLight,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppConfig.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Sistem Operasional Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConfig.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Tombol Refresh Cepat
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppConfig.textLight, size: 22),
              tooltip: 'Muat Ulang',
              onPressed: () => _controller.reload(),
            ),
            // Tombol WhatsApp CS
            IconButton(
              icon: const Icon(Icons.headset_mic_outlined, color: AppConfig.primaryColor, size: 22),
              tooltip: 'Hubungi CS',
              onPressed: () async {
                final uri = Uri.parse('https://wa.me/?text=Halo%20Admin%20Lumajang%20Network');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            // Tombol Keluar (Logout)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 21),
              tooltip: 'Keluar',
              onPressed: _confirmLogout,
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2.0),
            child: _isLoading && _loadingProgress < 100
                ? LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    backgroundColor: AppConfig.backgroundDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
                    minHeight: 2.5,
                  )
                : const Divider(height: 1, color: Color(0x1AFFFFFF)),
          ),
        ),

        // Konten WebView dengan Pull to Refresh
        body: RefreshIndicator(
          color: AppConfig.primaryColor,
          backgroundColor: AppConfig.surfaceDark,
          onRefresh: () async {
            await _controller.reload();
          },
          child: WebViewWidget(controller: _controller),
        ),

        // Bottom Navigation Bar Bergaya Aplikasi Modern
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppConfig.surfaceDark,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppConfig.primaryColor.withOpacity(0.2),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.primaryColor,
                  );
                }
                return const TextStyle(
                  fontSize: 11,
                  color: AppConfig.textMuted,
                );
              }),
            ),
            child: NavigationBar(
              height: 64,
              backgroundColor: AppConfig.surfaceDark,
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: _onBottomNavTapped,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined, color: AppConfig.textMuted),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: AppConfig.primaryColor),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined, color: AppConfig.textMuted),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: AppConfig.primaryColor),
                  label: 'Billing',
                ),
                NavigationDestination(
                  icon: Icon(Icons.hub_outlined, color: AppConfig.textMuted),
                  selectedIcon: Icon(Icons.hub_rounded, color: AppConfig.primaryColor),
                  label: 'Jaringan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined, color: AppConfig.textMuted),
                  selectedIcon: Icon(Icons.account_circle_rounded, color: AppConfig.primaryColor),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
