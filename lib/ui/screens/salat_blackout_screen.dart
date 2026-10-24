import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';

/// Salat Blackout Screen — pitch-black OLED with gold Arabic reminders.
/// Shown during congregational prayer duration.
class SalatBlackoutScreen extends StatefulWidget {
  const SalatBlackoutScreen({super.key});

  @override
  State<SalatBlackoutScreen> createState() => _SalatBlackoutScreenState();
}

class _SalatBlackoutScreenState extends State<SalatBlackoutScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final remaining = provider.blackoutRemaining;
    final prayerName = provider.activePrayer?.nameAr ?? '';

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (provider.isSimulationActive &&
              (event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.keyT ||
                  event.logicalKey == LogicalKeyboardKey.keyS)) {
            provider.resetSimulation();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Exit button during simulation
            if (provider.isSimulationActive)
              Positioned(
                top: 24,
                left: 24,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text(
                    'إنهاء المحاكاة (Esc / T)',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () => provider.resetSimulation(),
                ),
              ),
            // Very dim radial glow — barely visible
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    const Color(0xFF06231A).withValues(alpha: 0.3),
                    Colors.black,
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Builder(
                  builder: (context) {
                    final scale = ScreenScale.of(context);
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.scale(32, min: 16, max: 64),
                        vertical: scale.scale(24, min: 12, max: 48),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Prayer name
                          if (prayerName.isNotEmpty) ...[
                            Text(
                              'صلاة $prayerName',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: scale.scale(54, min: 36, max: 88),
                                color: const Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: const Color(0x66D4AF37),
                                    blurRadius: scale.scale(16, min: 10, max: 32),
                                  ),
                                ],
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            SizedBox(height: scale.scale(16, min: 8, max: 28)),
                            IslamicDivider(
                              color: const Color(0xFFB8962E),
                              maxWidth: scale.scale(380, min: 260, max: 720),
                            ),
                            SizedBox(height: scale.scale(24, min: 12, max: 40)),
                          ],

                          // Row alignment reminder
                          Text(
                            '«اسْتَوُوا وَاعْتَدِلُوا وَسَوُّوا صُفُوفَكُمْ»',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: scale.scale(38, min: 24, max: 64),
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(
                                  color: Color(0x44D4AF37),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: scale.scale(24, min: 12, max: 40)),

                          // Phone silence reminder
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: scale.scale(28, min: 16, max: 56),
                              vertical: scale.scale(12, min: 8, max: 24),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06231A).withValues(alpha: 0.5),
                              border: Border.all(
                                color: const Color(0xFFB8962E).withValues(alpha: 0.4),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(scale.scale(16, min: 12, max: 28)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  color: const Color(0xFFB8962E),
                                  size: scale.scale(24, min: 16, max: 40),
                                ),
                                SizedBox(width: scale.scale(12, min: 8, max: 20)),
                                Text(
                                  'يُرْجَى التَّأَكُّدُ مِنْ إِغْلَاقِ الْهَوَاتِفِ النَّقَّالَةِ',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: scale.scale(24, min: 15, max: 40),
                                    color: const Color(0xFFB8962E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: scale.scale(28, min: 14, max: 44)),

                          // Remaining time (subtle)
                          if (remaining.inMinutes > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: scale.scale(16, min: 10, max: 32),
                                vertical: scale.scale(6, min: 4, max: 12),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(scale.scale(20, min: 14, max: 32)),
                                border: Border.all(
                                  color: const Color(0xFF3A4030),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'المتبقي: ${remaining.inMinutes} دقيقة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: scale.scale(18, min: 13, max: 30),
                                  color: const Color(0xFF6A7058),
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
