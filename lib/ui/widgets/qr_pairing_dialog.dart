import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';

/// Modal dialog displaying QR Code for wireless smartphone pairing.
/// Enables Imams and administrators to scan the QR code and control
/// the mosque display from any mobile browser on the local Wi-Fi.
class QrPairingDialog extends StatefulWidget {
  const QrPairingDialog({super.key});

  static Future<void> show(BuildContext context) {
    final provider = context.read<DisplayProvider>();
    if (provider.remoteAdminIp == '127.0.0.1' && provider.isRemoteAdminRunning) {
      provider.refreshRemoteAdminIp();
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ChangeNotifierProvider<DisplayProvider>.value(
        value: provider,
        child: const QrPairingDialog(),
      ),
    );
  }

  @override
  State<QrPairingDialog> createState() => _QrPairingDialogState();
}

class _QrPairingDialogState extends State<QrPairingDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DisplayProvider>();
      if (provider.remoteAdminIp == '127.0.0.1' && provider.isRemoteAdminRunning) {
        provider.refreshRemoteAdminIp();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
    final themePalette = AppTheme.getThemePalette(provider.settings.colorTheme);

    final url = provider.remoteAdminUrl ?? provider.remoteAdminDirectUrl ?? '';
    final ip = provider.remoteAdminIp ?? '127.0.0.1';
    final port = provider.remoteAdminPort ?? provider.settings.remoteAdminPort;
    final isRunning = provider.isRemoteAdminRunning;
    const pin = '****'; // Masked on TV screen for security

    final qrSize = scale.scale(220, min: 160, max: 320);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.escape ||
             event.logicalKey == LogicalKeyboardKey.goBack ||
             event.logicalKey == LogicalKeyboardKey.browserBack ||
             event.logicalKey == LogicalKeyboardKey.keyQ)) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: scale.scale(40, min: 20, max: 80),
          vertical: scale.scale(24, min: 14, max: 48),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: scale.is4k ? 1100 : (scale.isCompact ? 750 : 920),
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: EdgeInsets.all(scale.scale(24, min: 16, max: 40)),
          decoration: BoxDecoration(
            color: themePalette.bgDeep,
            borderRadius: BorderRadius.circular(scale.scale(24, min: 16, max: 36)),
            border: Border.all(color: themePalette.goldPrimary, width: 2),
            boxShadow: [
              BoxShadow(
                color: themePalette.goldPrimary.withValues(alpha: 0.25),
                blurRadius: scale.scale(32, min: 16, max: 54),
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: themePalette.goldPrimary,
                        size: scale.scale(26, min: 20, max: 36),
                      ),
                      tooltip: 'إغلاق (Esc / Q)',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '📱 الاقتران والتحكم اللاسلكي عن بعد',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: scale.scale(24, min: 17, max: 36),
                                  fontWeight: FontWeight.bold,
                                  color: themePalette.goldPrimary,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: scale.scale(2, min: 1, max: 4)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'امسح الرمز بكاميرا الهاتف للتحكم في شاشة المسجد عبر شبكة Wi-Fi',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: scale.scale(14, min: 11, max: 20),
                                  color: themePalette.textSecondary,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Server Active Indicator
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: scale.scale(12, min: 8, max: 18),
                            vertical: scale.scale(6, min: 4, max: 10),
                          ),
                          decoration: BoxDecoration(
                            color: isRunning
                                ? const Color(0xFF27AE60).withValues(alpha: 0.2)
                                : Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRunning ? const Color(0xFF2ECC71) : Colors.redAccent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRunning ? Icons.wifi : Icons.wifi_off,
                                color: isRunning ? const Color(0xFF2ECC71) : Colors.redAccent,
                                size: scale.scale(16, min: 12, max: 22),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isRunning ? 'الخادم نشط' : 'الخادم متوقف',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: scale.scale(13, min: 10, max: 18),
                                  fontWeight: FontWeight.bold,
                                  color: isRunning ? const Color(0xFF2ECC71) : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: scale.scale(20, min: 12, max: 32)),

                // Central Pairing Body
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: QR Code Widget
                    Flexible(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: EdgeInsets.all(scale.scale(14, min: 10, max: 22)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(scale.scale(20, min: 14, max: 30)),
                            border: Border.all(
                              color: themePalette.goldPrimary,
                              width: scale.scale(2.5, min: 1.5, max: 4.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: themePalette.goldPrimary.withValues(alpha: 0.35),
                                blurRadius: scale.scale(22, min: 12, max: 36),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: isRunning && url.isNotEmpty
                              ? QrImageView(
                                  data: url,
                                  version: QrVersions.auto,
                                  size: qrSize,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF06231A),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF06231A),
                                  ),
                                )
                              : SizedBox(
                                  width: qrSize,
                                  height: qrSize,
                                  child: const Center(
                                    child: Text(
                                      'الخادم غير مشغل',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(width: scale.scale(24, min: 14, max: 40)),

                    // Right Column: Connection Details & Instructions
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Step-by-Step Instructions
                          _buildInstructionStep(
                            stepNumber: '1',
                            title: 'اتصل بشبكة المسجد',
                            subtitle: 'تأكد من اتصال هاتفك بنفس شبكة Wi-Fi المتصل بها التلفاز.',
                            themePalette: themePalette,
                            scale: scale,
                          ),
                          SizedBox(height: scale.scale(10, min: 6, max: 16)),
                          _buildInstructionStep(
                            stepNumber: '2',
                            title: 'امسح رمز الاستجابة السريعة',
                            subtitle: 'افتح كاميرا الهاتف أو قارئ QR وامسح الرمز لفتح صفحة الإدارة فوراً دون كلمة سر.',
                            themePalette: themePalette,
                            scale: scale,
                          ),
                          SizedBox(height: scale.scale(10, min: 6, max: 16)),
                          _buildInstructionStep(
                            stepNumber: '3',
                            title: 'أو افتح الرابط يدوياً في المتصفح',
                            subtitle: 'http://$ip:$port',
                            themePalette: themePalette,
                            scale: scale,
                            isCode: true,
                          ),

                          SizedBox(height: scale.scale(16, min: 10, max: 24)),

                          // Info Badges Row
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: scale.scale(14, min: 10, max: 20),
                              vertical: scale.scale(10, min: 6, max: 14),
                            ),
                            decoration: BoxDecoration(
                              color: themePalette.bgMid,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themePalette.goldDim.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(child: _buildDetailItem('عنوان IP للجهاز', ip, scale, themePalette)),
                                Container(width: 1, height: 32, color: themePalette.goldDim.withValues(alpha: 0.3)),
                                Expanded(child: _buildDetailItem('المنفذ (Port)', port.toString(), scale, themePalette)),
                                Container(width: 1, height: 32, color: themePalette.goldDim.withValues(alpha: 0.3)),
                                Expanded(child: _buildDetailItem('رمز PIN الأمان', pin, scale, themePalette)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: scale.scale(20, min: 12, max: 32)),

                // Action Buttons Footer
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!isRunning)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('تشغيل الخادم الآن'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => provider.startRemoteAdminServer(),
                      )
                    else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('تحديث الرمز السري (Token)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themePalette.goldLight,
                          side: BorderSide(color: themePalette.goldDim),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          provider.regenerateRemoteAdminToken();
                        },
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themePalette.goldPrimary,
                        foregroundColor: themePalette.bgDeep,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(
                          horizontal: scale.scale(24, min: 16, max: 36),
                          vertical: scale.scale(12, min: 8, max: 18),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'إغلاق والعودة للشاشة (Esc / Q)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: scale.scale(15, min: 11, max: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required ThemePalette themePalette,
    required ScreenScale scale,
    bool isCode = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: scale.scale(26, min: 20, max: 36),
          height: scale.scale(26, min: 20, max: 36),
          decoration: BoxDecoration(
            color: themePalette.goldPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: TextStyle(
                color: themePalette.bgDeep,
                fontWeight: FontWeight.bold,
                fontSize: scale.scale(14, min: 10, max: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: scale.scale(15, min: 12, max: 22),
                  fontWeight: FontWeight.bold,
                  color: themePalette.goldLight,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: isCode ? 'Courier' : 'Cairo',
                  fontSize: scale.scale(13, min: 10, max: 18),
                  color: isCode ? themePalette.goldPrimary : themePalette.textSecondary,
                  fontWeight: isCode ? FontWeight.bold : FontWeight.normal,
                ),
                textDirection: isCode ? TextDirection.ltr : TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    ScreenScale scale,
    ThemePalette themePalette,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(11, min: 9, max: 15),
              color: themePalette.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(14, min: 11, max: 20),
              fontWeight: FontWeight.bold,
              color: themePalette.goldLight,
            ),
          ),
        ),
      ],
    );
  }
}
