import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../config/app_config.dart';
import 'offline_screen.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
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
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) {
        // Izinkan kamera dan media capture jika diminta web dashboard
        request.grant();
      },
    );

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppConfig.backgroundDark)
      ..setUserAgent('${AppConfig.customUserAgentSuffix} Mobile')
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
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Tangani error halaman utama
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

            // Buka tautan WhatsApp, Telepon, SMS, Mailto, dan Intent di aplikasi luar
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

            // Jika domain diarahkan ke luar dari lumajangnetwork.id (misal payment gateway external)
            if (!request.url.contains('lumajangnetwork.id') &&
                (request.url.startsWith('http://') || request.url.startsWith('https://'))) {
              // Izinkan untuk tetap dibuka atau bisa diarahkan ke browser eksternal
              return NavigationDecision.navigate;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Konfigurasi khusus Android (File upload, DOM storage, mixed content)
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(AppConfig.webUrl));
    _controller = controller;
  }

  // Menangani tombol Back pada Android (Navigasi history webview / Double tap exit)
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

    // Keluar aplikasi
    SystemNavigator.pop();
    return true;
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
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar Loading
              if (_isLoading && _loadingProgress < 100)
                LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: AppConfig.backgroundDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
                  minHeight: 3,
                ),

              // Tampilan WebView dengan Pull To Refresh
              Expanded(
                child: RefreshIndicator(
                  color: AppConfig.primaryColor,
                  backgroundColor: AppConfig.surfaceDark,
                  onRefresh: () async {
                    await _controller.reload();
                  },
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
