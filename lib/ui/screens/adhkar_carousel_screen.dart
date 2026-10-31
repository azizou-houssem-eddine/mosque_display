import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../widgets/mandala_background.dart';

class _AdhkarItem {
  final String arabic;
  final String translation;
  final int count;
  final String reference;

  const _AdhkarItem({
    required this.arabic,
    required this.translation,
    required this.count,
    required this.reference,
  });
}

/// Post-Salat Adhkar Carousel — Concept 2 styled, 15s auto-progression,
/// D-pad dismissible. Also triggered on-demand via remote shortcut.
class AdhkarCarouselScreen extends StatefulWidget {
  const AdhkarCarouselScreen({super.key});

  @override
  State<AdhkarCarouselScreen> createState() => _AdhkarCarouselScreenState();
}

class _AdhkarCarouselScreenState extends State<AdhkarCarouselScreen> {
  List<_AdhkarItem> _items = [];
  int _currentIndex = 0;
  late final PageController _pageCtrl;
  final FocusNode _focusNode = FocusNode();
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _loadAdhkar();
    _startAutoAdvance();
  }

  Future<void> _loadAdhkar() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/adhkar_content.json');
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      setState(() {
        _items = list
            .map((e) => _AdhkarItem(
                  arabic: (e['arabic'] as String?) ?? '',
                  translation: (e['translation'] as String?) ?? '',
                  count: (e['count'] as num?)?.toInt() ?? 1,
                  reference: (e['reference'] as String?) ?? '',
                ))
            .toList();
      });
    } catch (_) {
      // Fallback content if asset loading fails
      setState(() {
        _items = const [
          _AdhkarItem(
            arabic: 'سُبْحَانَ اللهِ',
            translation: '٣٣ مرة',
            count: 33,
            reference: 'رواه مسلم',
          ),
          _AdhkarItem(
            arabic: 'الْحَمْدُ لِلَّهِ',
            translation: '٣٣ مرة',
            count: 33,
            reference: 'رواه مسلم',
          ),
          _AdhkarItem(
            arabic: 'اللهُ أَكْبَرُ',
            translation: '٣٣ مرة',
            count: 33,
            reference: 'رواه مسلم',
          ),
        ];
      });
    }
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_items.isEmpty) return;
      final next = (_currentIndex + 1) % _items.length;
      setState(() => _currentIndex = next);
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.goBack ||
              event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.browserBack) {
            provider.dismissAdhkar();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goTo((_currentIndex - 1).clamp(0, _items.length - 1));
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goTo((_currentIndex + 1) % _items.length);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.emeraldDeep,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
            const MandalaBackground(opacity: 0.08),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 14, 32, 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldMid,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.goldDim.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined,
                                    color: AppTheme.goldPrimary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  DisplayProvider.formatDuration(
                                      provider.adhkarRemaining),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          const Text(
                            'أذكار ما بعد الصلاة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 30,
                              color: AppTheme.goldPrimary,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: AppTheme.goldPrimary,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 24),
                          InkWell(
                            onTap: () => provider.dismissAdhkar(),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldMid,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.goldDim.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new,
                                    color: AppTheme.goldPrimary,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '◀ ▶ للتنقل  •  رجوع للخروج',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 15,
                                      color: AppTheme.goldPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Page view
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.goldPrimary))
                        : PageView.builder(
                            controller: _pageCtrl,
                            reverse: true, // RTL
                            itemCount: _items.length,
                            onPageChanged: (i) =>
                                setState(() => _currentIndex = i),
                            itemBuilder: (context, index) =>
                                _buildPage(_items[index]),
                          ),
                  ),
                  // Dot indicators
                  if (_items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentIndex ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentIndex
                                  ? AppTheme.goldPrimary
                                  : AppTheme.goldDim.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: i == _currentIndex
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.goldPrimary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
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
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildPage(_AdhkarItem item) {
    final scale = ScreenScale.of(context);
    final textLen = item.arabic.length;
    final baseArabicFontSize = textLen > 140
        ? 28.0
        : textLen > 70
            ? 38.0
            : 50.0;
    final arabicFontSize = scale.scale(baseArabicFontSize, min: 20.0, max: 80.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(48, min: 20, max: 80),
        vertical: scale.scale(12, min: 6, max: 24),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: scale.is4k ? 1800 : (scale.isCompact ? 820 : 1080),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: scale.scale(40, min: 20, max: 72),
            vertical: scale.scale(24, min: 14, max: 48),
          ),
          decoration: BoxDecoration(
            color: AppTheme.emeraldMid.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(scale.scale(24, min: 16, max: 40)),
            border: Border.all(
              color: AppTheme.goldPrimary.withValues(alpha: 0.55),
              width: scale.scale(1.5, min: 1.0, max: 3.0),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                blurRadius: scale.scale(24, min: 16, max: 44),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Arabic text
              Text(
                item.arabic,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: arabicFontSize,
                  color: AppTheme.textPrimary,
                  height: 1.6,
                  shadows: [
                    Shadow(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                      blurRadius: scale.scale(12, min: 8, max: 24),
                    ),
                  ],
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),

              // Subtle ornamental divider
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: scale.scale(14, min: 8, max: 24),
                ),
                height: 1.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.goldDim.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Count badge
              if (item.count > 1)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.scale(18, min: 12, max: 32),
                    vertical: scale.scale(6, min: 4, max: 12),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppTheme.goldAccent,
                      width: scale.scale(1.4, min: 1.0, max: 2.5),
                    ),
                    borderRadius: BorderRadius.circular(scale.scale(24, min: 16, max: 40)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat,
                        color: AppTheme.goldPrimary,
                        size: scale.scale(16, min: 12, max: 28),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.count} مرة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: scale.scale(20, min: 14, max: 36),
                          color: AppTheme.goldPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              if (item.translation.isNotEmpty) ...[
                SizedBox(height: scale.scale(12, min: 6, max: 20)),
                Text(
                  item.translation,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scale(20, min: 14, max: 36),
                    color: AppTheme.textSecondary,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ],
              if (item.reference.isNotEmpty) ...[
                SizedBox(height: scale.scale(8, min: 4, max: 16)),
                Text(
                  item.reference,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scale(16, min: 11, max: 28),
                    color: AppTheme.goldDim,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
