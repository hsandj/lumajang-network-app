import 'package:flutter/material.dart';
import '../config/app_config.dart';

class OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflineScreen({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Offline Icon Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 46,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 24),

                // Heading
                const Text(
                  'Koneksi Terputus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.textLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Explanation
                Text(
                  'Aplikasi membutuhkan koneksi internet untuk mengakses dashboard billing dan operasional Lumajang Network. Silakan periksa jaringan Wi-Fi atau paket data Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppConfig.textMuted,
                  ),
                ),
                const SizedBox(height: 36),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text(
                      'Coba Hubungkan Lagi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
