import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../../data/models/prayer_schedule.dart';
import '../../domain/occasions/islamic_occasions_engine.dart';

/// Modal dialog for simulating display states and religious occasions.
/// Exclusively designed for testing and visual evaluation.
class SimulationControlDialog extends StatelessWidget {
  const SimulationControlDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SimulationControlDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.emeraldDeep,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.goldPrimary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldPrimary.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppTheme.goldPrimary, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'لوحة التحكم في المحاكاة والاختبار التجريبي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.goldPrimary,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'اختبار جميع حالات الصلاة والمناسبات الدينية فوراً دون انتظار الوقت الفعلي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: provider.isSimulationActive
                          ? Colors.amber.withValues(alpha: 0.2)
                          : AppTheme.emeraldMid,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: provider.isSimulationActive
                            ? AppTheme.goldPrimary
                            : AppTheme.emeraldLight,
                      ),
                    ),
                    child: Text(
                      provider.isSimulationActive
                          ? '⚡ وضع المحاكاة نَشِط'
                          : '🟢 وضع التشغيل العادي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: provider.isSimulationActive
                            ? AppTheme.goldPrimary
                            : Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.emeraldLight, height: 28),

              // SECTION 1: Prayer Cycle States
              _buildSectionTitle(
                icon: Icons.access_time_filled,
                title: '1. محاكاة حالات دورة الصلاة (Display States)',
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  // Standard mode
                  _SimButton(
                    label: 'الوضع القياسي (الشاشة الرئيسية)',
                    icon: Icons.dashboard,
                    isSelected:
                        provider.displayState == DisplayState.standard &&
                            !provider.isSimulationActive,
                    onTap: () {
                      provider.simulateDisplayState(DisplayState.standard);
                      Navigator.of(context).pop();
                    },
                  ),

                  // Adhan Alert
                  _SimButton(
                    label: 'دخول وقت الأذان (تنبيه ونبض)',
                    icon: Icons.notifications_active,
                    isSelected:
                        provider.displayState == DisplayState.adhanAlert,
                    onTap: () {
                      provider.simulateDisplayState(
                        DisplayState.adhanAlert,
                        prayer: Prayer.maghrib,
                      );
                      Navigator.of(context).pop();
                    },
                  ),

                  // Iqamah Countdown (Fast 30s)
                  _SimButton(
                    label: 'العد التنازلي للإقامة (تجربة 30 ثانية)',
                    icon: Icons.timelapse,
                    isSelected:
                        provider.displayState == DisplayState.iqamahCountdown,
                    onTap: () {
                      provider.simulateDisplayState(
                        DisplayState.iqamahCountdown,
                        prayer: Prayer.maghrib,
                        customDuration: const Duration(seconds: 30),
                      );
                      Navigator.of(context).pop();
                    },
                  ),

                  // Iqamah Countdown (5 min)
                  _SimButton(
                    label: 'العد التنازلي للإقامة (5 دقائق)',
                    icon: Icons.timer,
                    onTap: () {
                      provider.simulateDisplayState(
                        DisplayState.iqamahCountdown,
                        prayer: Prayer.isha,
                        customDuration: const Duration(minutes: 5),
                      );
                      Navigator.of(context).pop();
                    },
                  ),

                  // Salat Blackout (Fast 20s)
                  _SimButton(
                    label: 'صلاة الجماعة / السواد الخافت (20 ثانية)',
                    icon: Icons.brightness_2,
                    isSelected:
                        provider.displayState == DisplayState.salatBlackout,
                    onTap: () {
                      provider.simulateDisplayState(
                        DisplayState.salatBlackout,
                        prayer: Prayer.maghrib,
                        customDuration: const Duration(seconds: 20),
                      );
                      Navigator.of(context).pop();
                    },
                  ),

                  // Salat Blackout (Full duration)
                  _SimButton(
                    label: 'صلاة الجماعة (المدة الكاملة)',
                    icon: Icons.dark_mode,
                    onTap: () {
                      provider.simulateDisplayState(
                        DisplayState.salatBlackout,
                        prayer: Prayer.maghrib,
                      );
                      Navigator.of(context).pop();
                    },
                  ),

                  // Post-Salat Adhkar
                  _SimButton(
                    label: 'أذكار ما بعد الصلاة (كاروسيل 7 دقائق)',
                    icon: Icons.auto_stories,
                    isSelected:
                        provider.displayState == DisplayState.postSalatAdhkar,
                    onTap: () {
                      provider.simulateDisplayState(
                        DisplayState.postSalatAdhkar,
                        prayer: Prayer.fajr,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: AppTheme.emeraldLight, height: 28),

              // SECTION 2: Religious Occasions
              _buildSectionTitle(
                icon: Icons.celebration,
                title: '2. محاكاة المناسبات الدينية والأيام الخاصة (Occasions)',
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _SimButton(
                    label: '🕌 يوم الجمعة المباركة (سورة الكهف)',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.friday,
                    onTap: () async {
                      await provider.simulateOccasion(OccasionType.friday);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _SimButton(
                    label: '🌙 شهر رمضان المبارك (الإمساك والإفطار)',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.ramadan,
                    onTap: () async {
                      await provider.simulateOccasion(OccasionType.ramadan);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _SimButton(
                    label: '🍬 عيد الفطر المبارك (التكبيرات والتهنئة)',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.eidFitr,
                    onTap: () async {
                      await provider.simulateOccasion(OccasionType.eidFitr);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _SimButton(
                    label: '🐑 عيد الأضحى المبارك (التكبيرات والتهنئة)',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.eidAdha,
                    onTap: () async {
                      await provider.simulateOccasion(OccasionType.eidAdha);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _SimButton(
                    label: '⛰️ يوم عرفة (حديث فضل الصيام)',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.arafah,
                    onTap: () async {
                      await provider.simulateOccasion(OccasionType.arafah);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _SimButton(
                    label: '🌊 يوم عاشوراء (حديث صيام عاشوراء)',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.ashura,
                    onTap: () async {
                      await provider.simulateOccasion(OccasionType.ashura);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _SimButton(
                    label: '🌿 المولد النبوي الشريف',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.mawlid,
                    onTap: () async {
                      await provider.simulateOccasion(OccasionType.mawlid);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _SimButton(
                    label: '📅 رأس السنة الهجرية الجديدة',
                    isSelected: provider.activeSimulatedOccasion ==
                        OccasionType.islamicNewYear,
                    onTap: () async {
                      await provider
                          .simulateOccasion(OccasionType.islamicNewYear);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Bottom Reset Button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 24),
                  label: const Text(
                    'إلغاء المحاكاة والعودة للوقت الحقيقي الطبيعي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await provider.resetSimulation();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppTheme.goldPrimary, size: 22),
      ],
    );
  }
}

class _SimButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SimButton({
    required this.label,
    this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldPrimary.withValues(alpha: 0.25)
              : AppTheme.emeraldMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.goldPrimary : AppTheme.emeraldLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected ? AppTheme.goldPrimary : AppTheme.textPrimary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.goldPrimary : AppTheme.goldDim,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
