import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../../data/models/mosque_settings.dart';
import '../../data/models/iqamah_delays.dart';
import '../../data/models/prayer_schedule.dart';
import '../../data/models/wilaya.dart';
import '../../domain/calculation/hijri_calculator.dart';
import '../../data/repositories/settings_repository.dart';
import 'dua_showcase_screen.dart';
import '../widgets/simulation_control_dialog.dart';

/// D-Pad navigable settings menu.
/// Accessible via long-press OK on main dashboard.
/// Gold focus highlight, full SharedPreferences persistence.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedPage = 0;

  static const _pages = [
    'الولاية',
    'الخطوط والأدعية',
    'تأخير الإقامة',
    'صلاة الجماعة',
    'التاريخ الهجري',
    'إعدادات المسجد',
    'PIN الأمان',
    'محاكاة واختبار',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.emeraldDeep,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          Row(
            children: [
              // Sidebar nav
              _buildSidebar(),
              // Page content
              Expanded(child: _buildPage()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: AppTheme.emeraldDeep.withValues(alpha: 0.8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'الإعدادات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 32,
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.w700,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pages.length,
              itemBuilder: (ctx, i) {
                final focused = _selectedPage == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPage = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: focused
                        ? AppTheme.focusedDecoration()
                        : AppTheme.unfocusedDecoration(),
                    child: Text(
                      _pages[i],
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        color: focused
                            ? AppTheme.goldPrimary
                            : AppTheme.textSecondary,
                        fontWeight: focused ? FontWeight.w700 : FontWeight.w400,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              },
            ),
          ),
          // Back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SettingsButton(
              label: 'رجوع',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    final provider = context.watch<DisplayProvider>();
    final settings = provider.settings;

    switch (_selectedPage) {
      case 0:
        return _WilayaPage(settings: settings);
      case 1:
        return _FontsAndDuaPage(settings: settings);
      case 2:
        return _IqamahPage(settings: settings);
      case 3:
        return _BlackoutPage(settings: settings);
      case 4:
        return _HijriPage(settings: settings);
      case 5:
        return _MosqueInfoPage(settings: settings);
      case 6:
        return _PinPage(settings: settings);
      case 7:
        return const _SimulationPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Wilaya Selection ──────────────────────────────────────────────────────────

class _WilayaPage extends StatefulWidget {
  final MosqueSettings settings;
  const _WilayaPage({required this.settings});

  @override
  State<_WilayaPage> createState() => _WilayaPageState();
}

class _WilayaPageState extends State<_WilayaPage> {
  String _query = '';
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = algerianWilayas.where((w) {
      if (_query.isEmpty) return true;
      return w.nameAr.contains(_query) ||
          w.nameFr.toLowerCase().contains(_query.toLowerCase()) ||
          w.code.toString().contains(_query);
    }).toList();

    return _PageWrapper(
      title: 'اختيار الولاية (58 ولاية)',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الرقم (مثال: وهران، سطيف، 16)...',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.goldDim),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.emeraldMid,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: AppTheme.emeraldLight, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: AppTheme.goldPrimary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد نتائج مطابقة للبحث',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final w = filtered[i];
                      final isSelected =
                          widget.settings.selectedWilayaCode == w.code;
                      return GestureDetector(
                        onTap: () async {
                          final newSettings =
                              widget.settings.copyWith(selectedWilayaCode: w.code);
                          await context
                              .read<DisplayProvider>()
                              .updateSettings(newSettings);
                          await SettingsRepository.save(newSettings);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: isSelected
                              ? AppTheme.focusedDecoration()
                              : BoxDecoration(
                                  color: AppTheme.emeraldMid,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.emeraldLight,
                                    width: 1,
                                  ),
                                ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isSelected)
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppTheme.goldPrimary,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'المحددة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 16,
                                        color: AppTheme.goldPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Flexible(
                                  child: Text(
                                    w.nameFr,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 18,
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        w.nameAr,
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 26,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppTheme.goldPrimary
                                              : AppTheme.textPrimary,
                                        ),
                                        textDirection: TextDirection.rtl,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.goldPrimary
                                            : AppTheme.emeraldLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        w.code.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppTheme.emeraldDeep
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Islamic Fonts & Du'as ───────────────────────────────────────────────────

class _FontsAndDuaPage extends StatelessWidget {
  final MosqueSettings settings;
  const _FontsAndDuaPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'الخطوط الإسلامية والأدعية المأثورة',
      child: ListView(
        children: [
          // Banner for Interactive Demo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  AppTheme.emeraldLight.withValues(alpha: 0.6),
                  AppTheme.emeraldMid,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldPrimary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill, size: 24),
                  label: const Text(
                    'فتح المعرض الحي للتجربة (Live Demo)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: AppTheme.emeraldDeep,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DuaShowcaseScreen(),
                      ),
                    );
                  },
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'معرض الأدعية التفاعلي المباشر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'استعراض أكثر من 60 دعاءً وحديثاً مأثوراً ومقارنة الخطوط بالكامل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'اختر نوع الخط الإسلامي المعتمد لشاشات المسجد والشريط المتحرك:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),

          // Font Options
          ...AppTheme.islamicFonts.map((font) {
            final isSelected = settings.islamicFont == font.key;
            return GestureDetector(
              onTap: () async {
                final newSettings =
                    settings.copyWith(islamicFont: font.key);
                await context
                    .read<DisplayProvider>()
                    .updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: isSelected
                    ? AppTheme.focusedDecoration()
                    : BoxDecoration(
                        color: AppTheme.emeraldMid,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.emeraldLight,
                          width: 1,
                        ),
                      ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? AppTheme.goldPrimary
                          : AppTheme.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                font.nameAr,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppTheme.goldPrimary
                                      : AppTheme.textPrimary,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            font.descriptionAr,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldDeep,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.goldDim
                                    : AppTheme.emeraldLight,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              font.sample,
                              style: AppTheme.getIslamicStyle(
                                fontKey: font.key,
                                fontSize: 24,
                                color: isSelected
                                    ? AppTheme.goldPrimary
                                    : AppTheme.textPrimary,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Iqamah Delays ─────────────────────────────────────────────────────────────

class _IqamahPage extends StatelessWidget {
  final MosqueSettings settings;
  const _IqamahPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    final delays = settings.iqamahDelays;
    final prayers = [
      (Prayer.fajr, delays.fajr, 5, 60),
      (Prayer.dhuhr, delays.dhuhr, 5, 45),
      (Prayer.asr, delays.asr, 5, 45),
      (Prayer.maghrib, delays.maghrib, 3, 30),
      (Prayer.isha, delays.isha, 5, 45),
    ];
    return _PageWrapper(
      title: 'تأخير الإقامة (دقائق)',
      child: Column(
        children: prayers.map((entry) {
          final (prayer, value, minVal, maxVal) = entry;
          return _NumberStepper(
            label: prayer.nameAr,
            value: value,
            min: minVal,
            max: maxVal,
            onChanged: (v) async {
              final newDelays = _updateDelay(delays, prayer, v);
              final newSettings = settings.copyWith(iqamahDelays: newDelays);
              await context.read<DisplayProvider>().updateSettings(newSettings);
              await SettingsRepository.save(newSettings);
            },
          );
        }).toList(),
      ),
    );
  }

  IqamahDelays _updateDelay(IqamahDelays d, Prayer p, int v) {
    switch (p) {
      case Prayer.fajr:
        return d.copyWith(fajr: v);
      case Prayer.dhuhr:
        return d.copyWith(dhuhr: v);
      case Prayer.asr:
        return d.copyWith(asr: v);
      case Prayer.maghrib:
        return d.copyWith(maghrib: v);
      case Prayer.isha:
        return d.copyWith(isha: v);
      default:
        return d;
    }
  }
}

// ── Blackout Settings ─────────────────────────────────────────────────────────

class _BlackoutPage extends StatelessWidget {
  final MosqueSettings settings;
  const _BlackoutPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'وضع صلاة الجماعة',
      child: Column(
        children: [
          _NumberStepper(
            label: 'مدة الصلاة (دقيقة)',
            value: settings.blackoutDurationMinutes,
            min: 5,
            max: 45,
            onChanged: (v) async {
              final newSettings =
                  settings.copyWith(blackoutDurationMinutes: v);
              await context.read<DisplayProvider>().updateSettings(newSettings);
              await SettingsRepository.save(newSettings);
            },
          ),
          const SizedBox(height: 24),
          _ToggleRow(
            label: 'وضع خافت (بدلاً من الإسود الكامل)',
            value: settings.blackoutDimMode,
            onChanged: (v) async {
              final newSettings = settings.copyWith(blackoutDimMode: v);
              await context.read<DisplayProvider>().updateSettings(newSettings);
              await SettingsRepository.save(newSettings);
            },
          ),
        ],
      ),
    );
  }
}

// ── Hijri Date Offset ─────────────────────────────────────────────────────────

class _HijriPage extends StatelessWidget {
  final MosqueSettings settings;
  const _HijriPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentOffset = settings.hijriOffsetDays;
    final hijriPreview = HijriCalculator.calculate(
      gregorianDate: now,
      offsetDays: currentOffset,
    );

    final offsetOptions = [
      (
        -2,
        'تأخير يومين (-2)',
        'تأخير التاريخ بمقدار يومين كاملين',
      ),
      (
        -1,
        'تأخير يوم واحد (-1)',
        'في حال عدم ثبوت رؤية الهلال وتأخر بداية الشهر',
      ),
      (
        0,
        'الحساب الفلكي القياسي (0)',
        'تقويم أم القرى الرسمي المعتمد بدون تعديل',
      ),
      (
        1,
        'تقديم يوم واحد (+1)',
        'في حال ثبوت رؤية الهلال مبكراً بقرار لجنة الأهلة',
      ),
      (
        2,
        'تقديم يومين (+2)',
        'تقديم التاريخ بمقدار يومين كاملين',
      ),
    ];

    return _PageWrapper(
      title: 'معايرة التاريخ الهجري (رؤية الهلال)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Preview Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  AppTheme.emeraldLight.withValues(alpha: 0.5),
                  AppTheme.emeraldMid,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldPrimary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'المعاينة المباشرة للتاريخ المعروض على الشاشة:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    color: AppTheme.goldDim,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(
                  hijriPreview.fullFormattedAr,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldPrimary,
                    shadows: [
                      Shadow(
                        color: AppTheme.goldPrimary,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'الموافق ميلادياً: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    color: AppTheme.textSecondary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'اختر التعديل المناسب حسب إعلان لجنة الأهلة الرسمية:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          // Options List
          Expanded(
            child: ListView.builder(
              itemCount: offsetOptions.length,
              itemBuilder: (ctx, i) {
                final (offsetVal, title, desc) = offsetOptions[i];
                final isSelected = currentOffset == offsetVal;
                final optionPreview = HijriCalculator.calculate(
                  gregorianDate: now,
                  offsetDays: offsetVal,
                );

                return GestureDetector(
                  onTap: () async {
                    final newSettings =
                        settings.copyWith(hijriOffsetDays: offsetVal);
                    await context
                        .read<DisplayProvider>()
                        .updateSettings(newSettings);
                    await SettingsRepository.save(newSettings);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: isSelected
                        ? AppTheme.focusedDecoration()
                        : BoxDecoration(
                            color: AppTheme.emeraldMid,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.emeraldLight,
                              width: 1,
                            ),
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppTheme.goldPrimary
                              : AppTheme.textSecondary,
                          size: 26,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                                : AppTheme.emeraldDeep,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.goldPrimary
                                  : AppTheme.emeraldLight,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${optionPreview.day} ${optionPreview.monthNameAr}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppTheme.goldPrimary
                                  : AppTheme.textSecondary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 21,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.goldPrimary
                                      : AppTheme.textPrimary,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mosque Info ───────────────────────────────────────────────────────────────

class _MosqueInfoPage extends StatelessWidget {
  final MosqueSettings settings;
  const _MosqueInfoPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'معلومات المسجد',
      child: Column(
        children: [
          _EditableField(
            label: 'اسم المسجد',
            value: settings.mosqueName,
            onSaved: (v) async {
              if (v.isNotEmpty) {
                final newSettings = settings.copyWith(mosqueName: v);
                await context
                    .read<DisplayProvider>()
                    .updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
              }
            },
          ),
          const SizedBox(height: 24),
          _EditableField(
            label: 'نصوص الإعلانات والتذكيرات (أدخل كل إعلان في سطر منفصل)',
            value: settings.marqueeText,
            maxLines: 5,
            onSaved: (v) async {
              if (v.isNotEmpty) {
                final newSettings = settings.copyWith(marqueeText: v);
                await context
                    .read<DisplayProvider>()
                    .updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── PIN Security ──────────────────────────────────────────────────────────────

class _PinPage extends StatefulWidget {
  final MosqueSettings settings;
  const _PinPage({required this.settings});

  @override
  State<_PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<_PinPage> {
  final _ctrl = TextEditingController();
  String? _msg;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'رمز الأمان (PIN)',
      child: Column(
        children: [
          Text(
            'رمز PIN الحالي: ${widget.settings.pinCode}',
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 24, color: AppTheme.textPrimary),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                color: AppTheme.textPrimary,
                letterSpacing: 12),
            decoration: InputDecoration(
              hintText: '0000',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: AppTheme.emeraldLight, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: AppTheme.goldPrimary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              labelText: 'رمز PIN الجديد (4 أرقام)',
              labelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.textSecondary,
                  fontSize: 18),
            ),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _msg!,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    color: AppTheme.goldPrimary),
              ),
            ),
          const SizedBox(height: 20),
          _SettingsButton(
            label: 'حفظ رمز PIN',
            onTap: () async {
              final pin = _ctrl.text.trim();
              if (pin.length == 4 &&
                  pin.split('').every((c) => '0123456789'.contains(c))) {
                final newSettings = widget.settings.copyWith(pinCode: pin);
                await context
                    .read<DisplayProvider>()
                    .updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
                setState(() => _msg = 'تم حفظ رمز PIN بنجاح ✓');
              } else {
                setState(() => _msg = 'يجب إدخال 4 أرقام فقط');
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Shared UI Components ──────────────────────────────────────────────────────

class _PageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const _PageWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 32,
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.w700,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 8),
          const IslamicDivider(color: AppTheme.goldDim, height: 20),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = '$value';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              color: AppTheme.textPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const Spacer(),
          // Decrement
          _IconBtn(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              display,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          // Increment
          _IconBtn(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 22, color: AppTheme.textPrimary),
          textDirection: TextDirection.rtl,
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.goldPrimary,
          activeTrackColor: AppTheme.emeraldLight,
        ),
      ],
    );
  }
}

class _EditableField extends StatefulWidget {
  final String label;
  final String value;
  final int maxLines;
  final ValueChanged<String> onSaved;
  const _EditableField({
    required this.label,
    required this.value,
    this.maxLines = 1,
    required this.onSaved,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                color: AppTheme.textSecondary),
            textDirection: TextDirection.rtl),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          maxLines: widget.maxLines,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 22, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.emeraldMid,
            enabledBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: AppTheme.emeraldLight, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: AppTheme.goldPrimary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SettingsButton(
            label: 'حفظ',
            onTap: () => widget.onSaved(_ctrl.text.trim())),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SettingsButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          gradient: onTap != null ? AppTheme.goldGradient : null,
          color: onTap == null ? AppTheme.emeraldLight : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: onTap != null ? AppTheme.emeraldDeep : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.emeraldLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? AppTheme.goldDim : AppTheme.emeraldLight,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppTheme.goldPrimary : AppTheme.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}

// ── Simulation & Testing Page ────────────────────────────────────────────────

class _SimulationPage extends StatelessWidget {
  const _SimulationPage();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();

    return _PageWrapper(
      title: 'وضع المحاكاة والاختبار التجريبي',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  AppTheme.emeraldLight.withValues(alpha: 0.6),
                  AppTheme.emeraldMid,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldPrimary, width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'أداة الاختبار السريع لحالات الشاشة والمناسبات الدينية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'تتيح لك هذه الأداة تجربة مظهر الشاشة أثناء دخول الأذان، وأثناء العد التنازلي للإقامة، وشاشة السواد التام أثناء صلاة الجماعة، وكاروسيل أذكار ما بعد الصلاة، بالإضافة إلى محاكاة يوم الجمعة وشهر رمضان المبارك وعيدي الفطر والأضحى ويوم عرفة فوراً دون انتظار موعدها الحقيقي.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.7,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.tune, size: 28),
                  label: const Text(
                    'فتح لوحة التحكم في المحاكاة (Live Controller)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: AppTheme.emeraldDeep,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    SimulationControlDialog.show(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (provider.isSimulationActive)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.goldPrimary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => provider.resetSimulation(),
                    child: const Text('إلغاء المحاكاة والعودة للوقت الحقيقي',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  const Text(
                    'تنبيه: وضع المحاكاة نشط حالياً على الشاشة الرئيسية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: AppTheme.goldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
