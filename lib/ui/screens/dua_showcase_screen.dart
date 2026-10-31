import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../../data/models/islamic_supplication.dart';
import '../../data/repositories/supplications_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../widgets/mandala_background.dart';

/// Interactive Islamic Font & Du'a Showcase Screen.
///
/// Allows real-time font comparison between authentic Arabic scripts:
/// - Amiri Quran (الخط القرآني الأصيل)
/// - Scheherazade New (خط المصحف التراثي)
/// - Amiri (خط النسخ الكلاسيكي)
/// - Aref Ruqaa (خط الرقعة العربي)
/// - Cairo (الخط الحديث عالي الوضوح)
///
/// Features interactive browsing of 60+ authentic Quranic, prophetic,
/// mosque, and prayer supplications with full tashkeel and sources.
class DuaShowcaseScreen extends StatefulWidget {
  const DuaShowcaseScreen({super.key});

  @override
  State<DuaShowcaseScreen> createState() => _DuaShowcaseScreenState();
}

class _DuaShowcaseScreenState extends State<DuaShowcaseScreen> {
  List<IslamicSupplication> _allSupplications = [];
  List<IslamicSupplication> _filteredSupplications = [];
  int _currentIndex = 0;
  String _selectedCategory = 'all';
  late String _currentFontKey;
  double _fontSize = 38.0;
  bool _autoPlay = false;
  Timer? _autoPlayTimer;
  final FocusNode _focusNode = FocusNode();

  final List<(String, String)> _categories = [
    ('all', '🌟 الكل'),
    ('friday_dua', '🕌 يوم الجمعة المباركة'),
    ('ramadan_dua', '🌙 رمضان وليلة القدر'),
    ('eid_dua', '🎉 تكبيرات وأدعية العيدين'),
    ('arafah_dua', '⛰️ يوم عرفة وعشر ذي الحجة'),
    ('ashura_dua', '🌊 عاشوراء ومحرم'),
    ('quranic_dua', '📖 أدعية قرآنية'),
    ('prophetic_dua', '🤲 جوامع الدعاء النبوي'),
    ('masjid_dua', '🕌 أدعية المسجد والأذان'),
    ('salat_adhkar', '🕋 أذكار الصلاة'),
    ('hadith_fadl', '📜 فضائل الصلاة والمساجد'),
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<DisplayProvider>();
    _currentFontKey = provider.settings.islamicFont;
    _loadData();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final list = await SupplicationsRepository.getAll();
    if (mounted) {
      setState(() {
        _allSupplications = list;
        _filterByCategory(_selectedCategory);
      });
    }
  }

  void _filterByCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      if (cat == 'all') {
        _filteredSupplications = List.from(_allSupplications);
      } else {
        _filteredSupplications =
            _allSupplications.where((s) => s.category == cat).toList();
      }
      _currentIndex = 0;
    });
  }

  void _nextDua() {
    if (_filteredSupplications.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _filteredSupplications.length;
    });
  }

  void _prevDua() {
    if (_filteredSupplications.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _filteredSupplications.length) %
          _filteredSupplications.length;
    });
  }

  void _toggleAutoPlay() {
    setState(() => _autoPlay = !_autoPlay);
    _autoPlayTimer?.cancel();
    if (_autoPlay) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _nextDua();
      });
    }
  }

  Future<void> _applyFontToApp(String fontKey) async {
    final provider = context.read<DisplayProvider>();
    final newSettings = provider.settings.copyWith(islamicFont: fontKey);
    await provider.updateSettings(newSettings);
    await SettingsRepository.save(newSettings);
    setState(() => _currentFontKey = fontKey);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم اعتماد هذا الخط للشريط الرئيسي وشاشات المسجد بنجاح',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppTheme.emeraldLight,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.mediaFastForward:
      case LogicalKeyboardKey.bracketLeft:
        _nextDua();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageUp:
      case LogicalKeyboardKey.mediaRewind:
      case LogicalKeyboardKey.bracketRight:
        _prevDua();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        _toggleAutoPlay();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.browserBack:
        Navigator.of(context).pop();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final currentDua = _filteredSupplications.isNotEmpty
        ? _filteredSupplications[_currentIndex]
        : null;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppTheme.emeraldDeep,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
            const MandalaBackground(opacity: 0.12),

            SafeArea(
              child: Column(
                children: [
                  // Top Control Header
                  _buildHeader(),

                  // Category Selector Chips
                  _buildCategoryBar(),

                  // Font Switcher Bar (Demo interactive switcher)
                  _buildFontSwitcherBar(),

                  // Central Illuminated Du'a Showcase Card
                  Expanded(
                    child: currentDua != null
                        ? _buildDuaCard(currentDua)
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                  ),

                  // Bottom Navigation Controls
                  _buildBottomControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.goldDim, width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppTheme.goldPrimary, size: 28),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'رجوع (Esc)',
          ),

          // Title
          const Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'معرض الخطوط الإسلامية والأدعية المأثورة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'مجموعة كبرى من الأدعية المشكّلة مع معاينة حية للخطوط القرآنية والتراثية',
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

          // Font size controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out, color: AppTheme.goldDim),
                onPressed: () => setState(() {
                  if (_fontSize > 26) _fontSize -= 2;
                }),
                tooltip: 'تصغير الخط',
              ),
              Text(
                '${_fontSize.toInt()}px',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.goldPrimary,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: AppTheme.goldDim),
                onPressed: () => setState(() {
                  if (_fontSize < 56) _fontSize += 2;
                }),
                tooltip: 'تكبير الخط',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final (key, label) = _categories[i];
          final isSelected = _selectedCategory == key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.emeraldDeep
                      : AppTheme.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.goldPrimary,
              backgroundColor: AppTheme.emeraldMid,
              onSelected: (_) => _filterByCategory(key),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.goldPrimary
                      : AppTheme.emeraldLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontSwitcherBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.emeraldDeep.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.emeraldLight, width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Apply button
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'اعتماد هذا الخط للشاشة والشريط',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: AppTheme.emeraldDeep,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _applyFontToApp(_currentFontKey),
            ),
            const SizedBox(width: 16),

            // Font Selector Chips
            Row(
              children: AppTheme.islamicFonts.map((font) {
                final isSelected = _currentFontKey == font.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _currentFontKey = font.key),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                            : AppTheme.emeraldMid,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.goldPrimary
                              : AppTheme.emeraldLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        font.nameAr,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.goldPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuaCard(IslamicSupplication dua) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.emeraldMid.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.goldPrimary, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top metadata pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Count indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldDeep,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldDim, width: 0.8),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_filteredSupplications.length}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    color: AppTheme.goldPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Category title
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldPrimary, width: 1),
                ),
                child: Text(
                  dua.categoryAr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Center Scrollable / Flexible content to prevent any zoom overflow
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The Arabic Du'a text rendered in the selected Islamic Font
                    Text(
                      dua.text,
                      style: AppTheme.getIslamicStyle(
                        fontKey: _currentFontKey,
                        fontSize: _fontSize,
                        color: AppTheme.textPrimary,
                        height: 1.8,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),
                    const IslamicDivider(
                      color: AppTheme.goldDim,
                      maxWidth: 320,
                    ),
                    const SizedBox(height: 14),

                    // Source and Citation
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldDeep.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.goldDim.withValues(alpha: 0.7),
                            width: 0.8),
                      ),
                      child: Text(
                        dua.source,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.goldPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),

                    if (dua.virtue != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '✦ ${dua.virtue!} ✦',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Next button (RTL forward)
            ElevatedButton.icon(
              autofocus: true,
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'التالي',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldMid,
                foregroundColor: AppTheme.goldPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.goldDim, width: 1),
                ),
              ),
              onPressed: _nextDua,
            ),
            const SizedBox(width: 16),

            // Auto-play button
            TextButton.icon(
              icon: Icon(
                _autoPlay ? Icons.pause_circle : Icons.play_circle,
                color: AppTheme.goldPrimary,
                size: 28,
              ),
              label: Text(
                _autoPlay ? 'إيقاف التبديل التلقائي' : 'تشغيل التبديل التلقائي (10 ثوانٍ)',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: AppTheme.goldPrimary,
                ),
              ),
              onPressed: _toggleAutoPlay,
            ),
            const SizedBox(width: 16),

            // Previous button
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'السابق',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldMid,
                foregroundColor: AppTheme.goldPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.goldDim, width: 1),
                ),
              ),
              onPressed: _prevDua,
            ),
          ],
        ),
      ),
    );
  }
}
