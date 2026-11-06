import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../../data/models/mosque_settings.dart';
import '../../data/models/commune.dart';
import '../../data/models/iqamah_delays.dart';
import '../../data/models/prayer_offsets.dart';
import '../../data/models/prayer_schedule.dart';
import '../../data/models/wilaya.dart';
import '../../domain/calculation/hijri_calculator.dart';
import '../../data/repositories/settings_repository.dart';
import 'dua_showcase_screen.dart';
import '../widgets/simulation_control_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/qr_pairing_dialog.dart';

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
  final GlobalKey<_WilayaPageState> _wilayaPageKey = GlobalKey<_WilayaPageState>();

  static const _pages = [
    'الولاية',
    'معايرة المواقيت',
    'المظهر والواجهة',
    'الخطوط والأدعية',
    'تأخير الإقامة',
    'صلاة الجماعة',
    'التاريخ الهجري',
    'إعدادات المسجد',
    'PIN الأمان',
    'محاكاة واختبار',
    'التحكم عن بعد (QR)',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final themePalette = AppTheme.getThemePalette(provider.settings.colorTheme);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null &&
            (currentFocus.context?.widget is EditableText ||
             currentFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null)) {
          currentFocus.unfocus();
          return;
        }
        if (_selectedPage == 0 && _wilayaPageKey.currentState?.canHandleBack == true) {
          _wilayaPageKey.currentState?.handleBack();
          return;
        }
        Navigator.of(context).pop();
      },
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.escape ||
               event.logicalKey == LogicalKeyboardKey.goBack ||
               event.logicalKey == LogicalKeyboardKey.browserBack)) {
            final currentFocus = FocusManager.instance.primaryFocus;
            if (currentFocus != null &&
                (currentFocus.context?.widget is EditableText ||
                 currentFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null)) {
              currentFocus.unfocus();
              return KeyEventResult.handled;
            }
            if (_selectedPage == 0 && _wilayaPageKey.currentState?.canHandleBack == true) {
              _wilayaPageKey.currentState?.handleBack();
              return KeyEventResult.handled;
            }
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: themePalette.backgroundTop,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: themePalette.backgroundGradient,
                ),
              ),
              Row(
                children: [
                  // Sidebar nav
                  _buildSidebar(themePalette),
                  // Page content
                  Expanded(child: _buildPage()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemePalette themePalette) {
    final provider = context.watch<DisplayProvider>();
    final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
    final sidebarWidth = scale.scale(230, min: 175, max: 280);

    return Container(
      width: sidebarWidth,
      color: themePalette.backgroundTop.withValues(alpha: 0.95),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.scale(12, min: 8, max: 16),
              scale.scale(14, min: 8, max: 20),
              scale.scale(12, min: 8, max: 16),
              scale.scale(8, min: 4, max: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      color: AppTheme.goldPrimary, size: scale.scale(18, min: 15, max: 22)),
                  tooltip: 'رجوع للشاشة الرئيسية (Esc)',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: scale.scale(22, min: 17, max: 28),
                        color: AppTheme.goldPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: _pages.length,
              itemBuilder: (ctx, i) {
                return _SidebarItem(
                  label: _pages[i],
                  isSelected: _selectedPage == i,
                  autofocus: i == 0,
                  onSelect: () => setState(() => _selectedPage = i),
                );
              },
            ),
          ),
          // Back button
          Padding(
            padding: EdgeInsets.all(scale.scale(12, min: 8, max: 16)),
            child: _SettingsButton(
              label: 'رجوع للشاشة الرئيسية',
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

    return IndexedStack(
      index: _selectedPage,
      children: [
        _WilayaPage(key: _wilayaPageKey, settings: settings),
        _PrayerOffsetsPage(settings: settings),
        _WatchFaceDesignPage(settings: settings),
        _FontsAndDuaPage(settings: settings),
        _IqamahPage(settings: settings),
        _BlackoutPage(settings: settings),
        _HijriPage(settings: settings),
        _MosqueInfoPage(settings: settings),
        _PinPage(settings: settings),
        const _SimulationPage(),
        _RemoteAdminPage(settings: settings),
      ],
    );
  }
}

// ── Wilaya & Commune Selection ──────────────────────────────────────────────────

class _WilayaPage extends StatefulWidget {
  final MosqueSettings settings;
  const _WilayaPage({super.key, required this.settings});

  @override
  State<_WilayaPage> createState() => _WilayaPageState();
}

class _WilayaPageState extends State<_WilayaPage> {
  // 0 = Wilayas list, 1 = Communes list for chosen Wilaya
  int _viewMode = 0;
  int? _activeWilayaCode;
  List<Commune> _communes = [];
  bool _loadingCommunes = false;

  bool get canHandleBack => _viewMode == 1;

  void handleBack() {
    if (_viewMode == 1) {
      setState(() {
        _viewMode = 0;
      });
    }
  }

  String _wilayaQuery = '';
  String _communeQuery = '';
  late final TextEditingController _wilayaCtrl;
  late final TextEditingController _communeCtrl;
  late final FocusNode _wilayaFocusNode;
  late final FocusNode _communeFocusNode;

  @override
  void initState() {
    super.initState();
    _wilayaCtrl = TextEditingController();
    _communeCtrl = TextEditingController();
    _wilayaFocusNode = FocusNode();
    _communeFocusNode = FocusNode();

    _wilayaFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          node.nextFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.goBack) {
          node.unfocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _communeFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          node.nextFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.goBack) {
          node.unfocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _activeWilayaCode = widget.settings.selectedWilayaCode;
    _fetchCommunes(widget.settings.selectedWilayaCode);
  }

  @override
  void dispose() {
    _wilayaCtrl.dispose();
    _communeCtrl.dispose();
    _wilayaFocusNode.dispose();
    _communeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCommunes(int wilayaCode) async {
    setState(() {
      _loadingCommunes = true;
      _activeWilayaCode = wilayaCode;
    });
    try {
      final list = await context
          .read<DisplayProvider>()
          .getCommunesForWilaya(wilayaCode);
      if (mounted) {
        setState(() {
          _communes = list;
          _loadingCommunes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCommunes = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWilaya = algerianWilayas.firstWhere(
      (w) => w.code == (_activeWilayaCode ?? widget.settings.selectedWilayaCode),
      orElse: () => algerianWilayas.first,
    );

    return _PageWrapper(
      title: 'الموقع الجغرافي وحساب المواقيت (الولايات والبلديات)',
      child: Column(
        children: [
          // Current Selection Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.emeraldDeep.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldDim, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: '1. الولايات (58)',
                        isActive: _viewMode == 0,
                        onTap: () => setState(() => _viewMode = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TabButton(
                        label: '2. بلديات ${currentWilaya.nameAr} (${_communes.length})',
                        isActive: _viewMode == 1,
                        onTap: () {
                          if (_communes.isEmpty) {
                            _fetchCommunes(currentWilaya.code);
                          }
                          setState(() => _viewMode = 1);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'الموقع المعتمد: ولاية ${currentWilaya.nameAr} (${currentWilaya.code.toString().padLeft(2, '0')})'
                  '${widget.settings.selectedCommuneName != null ? ' - بلدية ${widget.settings.selectedCommuneName}' : ' - مركز الولاية'}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                const Text(
                  'توقيت رسمي معتمد من وزارة الشؤون الدينية ومركز CRAAG',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: _viewMode == 0
                ? _buildWilayasList()
                : _buildCommunesList(currentWilaya),
          ),
        ],
      ),
    );
  }

  Widget _buildWilayasList() {
    final filtered = algerianWilayas.where((w) {
      if (_wilayaQuery.isEmpty) return true;
      return w.nameAr.contains(_wilayaQuery) ||
          w.nameFr.toLowerCase().contains(_wilayaQuery.toLowerCase()) ||
          w.code.toString().contains(_wilayaQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _wilayaCtrl,
            focusNode: _wilayaFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _wilayaFocusNode.unfocus(),
            onTapOutside: (_) => _wilayaFocusNode.unfocus(),
            enableInteractiveSelection: true,
            onChanged: (v) => setState(() => _wilayaQuery = v.trim()),
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'بحث في الولايات بالاسم أو الرقم (مثال: وهران، سطيف، 16)...',
              hintStyle: const TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.textSecondary,
                fontSize: 18,
              ),
              prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
              suffixIcon: _wilayaQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.goldDim),
                      onPressed: () {
                        _wilayaCtrl.clear();
                        setState(() => _wilayaQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.emeraldMid,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.emeraldLight, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد ولاية مطابقة للبحث',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final w = filtered[i];
                    final isSelected = widget.settings.selectedWilayaCode == w.code;
                    return _FocusableListTile(
                      isSelected: isSelected,
                      onTap: () async {
                        final newSettings = widget.settings.copyWith(
                          selectedWilayaCode: w.code,
                          selectedCommuneCode: null,
                          selectedCommuneName: null,
                        );
                        await context.read<DisplayProvider>().updateSettings(newSettings);
                        await SettingsRepository.save(newSettings);
                        await _fetchCommunes(w.code);
                        setState(() => _viewMode = 1);
                      },
                      leading: isSelected
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.goldPrimary, size: 24),
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
                          : Text(
                              w.nameFr,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                      title: Text(
                        w.nameAr,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 26,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.goldPrimary : AppTheme.textPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.goldPrimary : AppTheme.emeraldLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          w.code.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.emeraldDeep : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommunesList(Wilaya currentWilaya) {
    if (_loadingCommunes) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      );
    }

    final filtered = _communes.where((c) {
      if (_communeQuery.isEmpty) return true;
      return c.nameAr.contains(_communeQuery) ||
          c.nameFr.toLowerCase().contains(_communeQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _SettingsButton(
                label: '← العودة لقائمة الولايات',
                onTap: () => setState(() => _viewMode = 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _communeCtrl,
                  focusNode: _communeFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _communeFocusNode.unfocus(),
                  onTapOutside: (_) => _communeFocusNode.unfocus(),
                  enableInteractiveSelection: true,
                  onChanged: (v) => setState(() => _communeQuery = v.trim()),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'بحث في بلديات ودوائر ${currentWilaya.nameAr}...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppTheme.textSecondary,
                      fontSize: 18,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
                    suffixIcon: _communeQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.goldDim),
                            onPressed: () {
                              _communeCtrl.clear();
                              setState(() => _communeQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.emeraldMid,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.emeraldLight, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              // Default: Chef-lieu (Centre de Wilaya)
              _FocusableListTile(
                isSelected: widget.settings.selectedCommuneCode == null &&
                    widget.settings.selectedWilayaCode == currentWilaya.code,
                onTap: () async {
                  final newSettings = widget.settings.copyWith(
                    selectedWilayaCode: currentWilaya.code,
                    selectedCommuneCode: null,
                    selectedCommuneName: null,
                  );
                  await context.read<DisplayProvider>().updateSettings(newSettings);
                  await SettingsRepository.save(newSettings);
                },
                leading: widget.settings.selectedCommuneCode == null &&
                        widget.settings.selectedWilayaCode == currentWilaya.code
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.goldPrimary, size: 24),
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
                    : const Text(
                        'Chef-lieu',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                title: Text(
                  'مركز ولاية ${currentWilaya.nameAr} (الافتراضي)',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 26,
                    fontWeight: widget.settings.selectedCommuneCode == null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: widget.settings.selectedCommuneCode == null
                        ? AppTheme.goldPrimary
                        : AppTheme.textPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '0 دقيقة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),

              // Communes list
              ...filtered.map((c) {
                final isSelected = widget.settings.selectedCommuneCode == c.code &&
                    widget.settings.selectedWilayaCode == currentWilaya.code;
                final offsetText = c.minuteOffset == 0
                    ? '0 دقيقة'
                    : (c.minuteOffset > 0 ? '+${c.minuteOffset} دقيقة' : '${c.minuteOffset} دقيقة');
                return _FocusableListTile(
                  isSelected: isSelected,
                  onTap: () async {
                    final newSettings = widget.settings.copyWith(
                      selectedWilayaCode: currentWilaya.code,
                      selectedCommuneCode: c.code,
                      selectedCommuneName: c.nameAr,
                    );
                    await context.read<DisplayProvider>().updateSettings(newSettings);
                    await SettingsRepository.save(newSettings);
                  },
                  leading: isSelected
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.goldPrimary, size: 24),
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
                      : Text(
                          c.nameFr,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                  title: Text(
                    c.nameAr,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 26,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.goldPrimary : AppTheme.textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.goldPrimary
                          : (c.minuteOffset != 0
                              ? Colors.amber.withValues(alpha: 0.25)
                              : AppTheme.emeraldLight),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.goldPrimary
                            : (c.minuteOffset != 0 ? AppTheme.goldDim : AppTheme.emeraldLight),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      offsetText,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppTheme.emeraldDeep
                            : (c.minuteOffset != 0 ? AppTheme.goldPrimary : AppTheme.textPrimary),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
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
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
            return _FocusableFontCard(
              font: font,
              isSelected: isSelected,
              onTap: () async {
                final newSettings =
                    settings.copyWith(islamicFont: font.key);
                await context
                    .read<DisplayProvider>()
                    .updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
              },
            );
          }),
        ],
      ),
    );
  }
}

// ── Per-Prayer Calibration Offsets (±15 min) ──────────────────────────────────

class _PrayerOffsetsPage extends StatelessWidget {
  final MosqueSettings settings;
  const _PrayerOffsetsPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    final scale = ScreenScale.of(context);
    final provider = context.watch<DisplayProvider>();
    final offsets = settings.offsets;
    final schedule = provider.todaySchedule;
    final activeCommune = provider.activeCommune;
    final currentWilaya = algerianWilayas.firstWhere(
      (w) => w.code == settings.selectedWilayaCode,
      orElse: () => algerianWilayas.first,
    );

    final prayers = [
      (Prayer.fajr, offsets.fajr),
      (Prayer.sunrise, offsets.sunrise),
      (Prayer.dhuhr, offsets.dhuhr),
      (Prayer.asr, offsets.asr),
      (Prayer.maghrib, offsets.maghrib),
      (Prayer.isha, offsets.isha),
    ];

    String fmtTime(Prayer p) {
      if (schedule == null) return '--:--';
      final t = schedule.getTime(p);
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    final maghribOffset = offsets.maghrib;
    final maghribOffsetStr = maghribOffset == 0
        ? '0 دقيقة'
        : (maghribOffset > 0 ? '+$maghribOffset د' : '$maghribOffset د');

    return _PageWrapper(
      title: 'معايرة المواقيت يدوياً (تعديل الدقائق ±15)',
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Location & Baseline Info Card
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.scale(16, min: 10, max: 24),
                vertical: scale.scale(10, min: 6, max: 16),
              ),
              margin: EdgeInsets.only(bottom: scale.scale(10, min: 6, max: 14)),
              decoration: BoxDecoration(
                color: AppTheme.emeraldDeep.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(scale.scale(12, min: 8, max: 16)),
                border: Border.all(color: AppTheme.goldDim, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'الموقع المعتمد: ولاية ${currentWilaya.nameAr} (${currentWilaya.code.toString().padLeft(2, '0')})'
                    '${settings.selectedCommuneName != null ? ' - بلدية ${settings.selectedCommuneName}' : ' - مركز الولاية'}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: scale.scale(15, min: 12, max: 20),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activeCommune != null && activeCommune.minuteOffset != 0
                        ? 'فارق التوقيت الرسمي للوزارة: ${activeCommune.minuteOffset >= 0 ? '+' : ''}${activeCommune.minuteOffset} دقيقة (مطبق تلقائياً على الرزنامة الرسمية)'
                        : 'توقيت رسمي معتمد من وزارة الشؤون الدينية ومركز CRAAG (فارق 0 دقيقة)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: scale.scale(12, min: 10, max: 16),
                      color: AppTheme.textSecondary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

            // Highlighted Maghrib Quick Calibration Card
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.scale(16, min: 10, max: 24),
                vertical: scale.scale(10, min: 8, max: 16),
              ),
              margin: EdgeInsets.only(bottom: scale.scale(10, min: 6, max: 14)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldPrimary.withValues(alpha: 0.18),
                    AppTheme.emeraldMid.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(scale.scale(12, min: 8, max: 16)),
                border: Border.all(color: AppTheme.goldPrimary, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                spacing: 12,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'معايرة صلاة المغرب: $maghribOffsetStr',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.emeraldDeep,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_twilight, color: AppTheme.goldPrimary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'موعد المغرب والإفطار: ${fmtTime(Prayer.maghrib)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: scale.scale(15, min: 13, max: 20),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Help Banner with Reset Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.scale(14, min: 10, max: 20),
                vertical: scale.scale(8, min: 6, max: 14),
              ),
              margin: EdgeInsets.only(bottom: scale.scale(10, min: 6, max: 14)),
              decoration: BoxDecoration(
                color: AppTheme.emeraldMid,
                borderRadius: BorderRadius.circular(scale.scale(12, min: 8, max: 16)),
                border: Border.all(color: AppTheme.emeraldLight, width: 1.2),
              ),
              child: Row(
                children: [
                  _SettingsButton(
                    label: 'إعادة ضبط الكل (0)',
                    onTap: () async {
                      final newSettings = settings.copyWith(
                        offsets: const PrayerOffsets.zero(),
                      );
                      await context
                          .read<DisplayProvider>()
                          .updateSettings(newSettings);
                      await SettingsRepository.save(newSettings);
                    },
                  ),
                  SizedBox(width: scale.scale(12, min: 8, max: 16)),
                  Expanded(
                    child: Text(
                      'استخدم الأسهم ◀ ▶ لتعديل دقائق كل صلاة بشكل منفصل لمطابقة رزنامة المسجد المحلية بدقة تامة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: scale.scale(13, min: 11, max: 17),
                        color: AppTheme.textSecondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),

            // Per-Prayer Calibration Steppers (All 6 prayers with auto-scroll)
            ...prayers.map((entry) {
              final (prayer, val) = entry;
              final valStr = val == 0
                  ? '0 د'
                  : (val > 0 ? '+$val د' : '$val د');
              final isMaghrib = prayer == Prayer.maghrib;
              return _NumberStepper(
                label: '${prayer.nameAr}  [الموعد الحالي: ${fmtTime(prayer)}] ($valStr)',
                value: val,
                min: PrayerOffsets.minOffsetMinutes,
                max: PrayerOffsets.maxOffsetMinutes,
                isHighlighted: isMaghrib,
                helperText: isMaghrib
                    ? 'لحظة الإفطار في رمضان وأذان صلاة المغرب — مضبوط بدقة'
                    : null,
                onChanged: (v) async {
                  final newOffsets = _updateOffset(offsets, prayer, v);
                  final newSettings = settings.copyWith(offsets: newOffsets);
                  await context
                      .read<DisplayProvider>()
                      .updateSettings(newSettings);
                  await SettingsRepository.save(newSettings);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  PrayerOffsets _updateOffset(PrayerOffsets o, Prayer p, int v) {
    switch (p) {
      case Prayer.fajr:
        return o.copyWith(fajr: v);
      case Prayer.sunrise:
        return o.copyWith(sunrise: v);
      case Prayer.dhuhr:
        return o.copyWith(dhuhr: v);
      case Prayer.asr:
        return o.copyWith(asr: v);
      case Prayer.maghrib:
        return o.copyWith(maghrib: v);
      case Prayer.isha:
        return o.copyWith(isha: v);
    }
  }
}

// ── Watch Face Design & Appearance Page ──────────────────────────────────────

class _WatchFaceDesignPage extends StatefulWidget {
  final MosqueSettings settings;
  const _WatchFaceDesignPage({required this.settings});

  @override
  State<_WatchFaceDesignPage> createState() => _WatchFaceDesignPageState();
}

class _WatchFaceDesignPageState extends State<_WatchFaceDesignPage> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final scale = ScreenScale.of(context);
    final provider = context.watch<DisplayProvider>();
    final settings = provider.settings;

    return _PageWrapper(
      title: 'تخصيص الواجهة ومظهر الشاشة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TabButton(
                  label: 'خيارات العرض',
                  isActive: _activeTab == 3,
                  onTap: () => setState(() => _activeTab = 3),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'مقياس الشاشة',
                  isActive: _activeTab == 2,
                  onTap: () => setState(() => _activeTab = 2),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'الطابع اللوني',
                  isActive: _activeTab == 1,
                  onTap: () => setState(() => _activeTab = 1),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'قوالب الساعة',
                  isActive: _activeTab == 0,
                  onTap: () => setState(() => _activeTab = 0),
                ),
              ],
            ),
          ),
          SizedBox(height: scale.scale(10, min: 6, max: 14)),
          Expanded(
            child: SingleChildScrollView(
              child: _buildTabContent(settings, provider, scale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    MosqueSettings settings,
    DisplayProvider provider,
    ScreenScale scale,
  ) {
    switch (_activeTab) {
      case 0:
        return _buildTemplatesTab(settings, provider, scale);
      case 1:
        return _buildThemesTab(settings, provider, scale);
      case 2:
        return _buildScaleTab(settings, provider, scale);
      case 3:
        return _buildOptionsTab(settings, provider, scale);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTemplatesTab(
    MosqueSettings settings,
    DisplayProvider provider,
    ScreenScale scale,
  ) {
    final templates = [
      (
        'classicAstrolabe',
        'الأسطرلاب الكلاسيكي المتوازن',
        'التصميم المعتمد الأصلي: 3 صلوات على اليمين و 3 على اليسار، تتوسطها ساعة أسطرلاب ذهبية دائرية مع عداد تنازلي نيون.',
        Icons.timelapse,
      ),
      (
        'modernHorizontal',
        'الشريط الأفقي العصري',
        'عرض كامل ومريح: شبكة أفقية لجميع الصلوات الست في صف واحد أسفل الشاشة، مع ساعة وبانر تنازلي عريض في الأعلى.',
        Icons.view_column,
      ),
      (
        'grandClock',
        'الساعة الملكية الكبرى',
        'وضوح فائق للمساجد الكبيرة: ساعة رقمية عملاقة وعداد تنازلي بارز في المنتصف، مع عمود مواقيت جانبي عريض.',
        Icons.access_time_filled,
      ),
      (
        'traditionalMinbar',
        'المحراب الأندلسي التقليدي',
        'طابع إسلامي عريق: تصميم مؤطر بأقواس المحراب وزخارف ذهبية مستوحاة من العمارة الإسلامية والمآذن المغاربية.',
        Icons.mosque,
      ),
    ];

    return Column(
      children: templates.map((tmpl) {
        final (key, title, desc, icon) = tmpl;
        final isSelected = settings.watchFaceTemplate == key;
        return _DesignCard(
          title: title,
          description: desc,
          icon: icon,
          isSelected: isSelected,
          onTap: () async {
            final newSettings = settings.copyWith(watchFaceTemplate: key);
            await provider.updateSettings(newSettings);
            await SettingsRepository.save(newSettings);
          },
        );
      }).toList(),
    );
  }

  Widget _buildThemesTab(
    MosqueSettings settings,
    DisplayProvider provider,
    ScreenScale scale,
  ) {
    final themes = [
      (
        'royalEmerald',
        'الزمرد الملكي الذهبي (الافتراضي)',
        'تدرجات الأخضر المسجدي العميق مع الذهب الإسلامي الفاخر — الطابع الأصيل لبيوت الله.',
        const [Color(0xFF042217), Color(0xFF0D5C3A), Color(0xFFD4AF37)],
      ),
      (
        'midnightSapphire',
        'الياقوت الأزرق الليلي',
        'أزرق ليلي ملكي هادئ مع إضاءة فضية ذهبية — يمنح راحة بصرية فائقة ووقاراً للمصلين.',
        const [Color(0xFF031424), Color(0xFF0B2D4D), Color(0xFF4FA3E2)],
      ),
      (
        'andalusianOnyx',
        'العقيق الأندلسي الداكن',
        'فحم دمشقي داكن مع عنبر دافئ ولمسات ذهبية رصينة — فخامة معمارية متميزة.',
        const [Color(0xFF151515), Color(0xFF262626), Color(0xFFE5A93C)],
      ),
      (
        'kiswahBlack',
        'سواد الكسوة الشريفة (OLED)',
        'أسود نقي مخصص لشاشات OLED مع حروف ذهبية براقة مستوحاة من كسوة الكعبة المشرفة.',
        const [Color(0xFF050505), Color(0xFF141414), Color(0xFFFFD700)],
      ),
    ];

    return Column(
      children: themes.map((thm) {
        final (key, title, desc, colors) = thm;
        final isSelected = settings.colorTheme == key;
        return _DesignCard(
          title: title,
          description: desc,
          isSelected: isSelected,
          colors: colors,
          onTap: () async {
            final newSettings = settings.copyWith(colorTheme: key);
            await provider.updateSettings(newSettings);
            await SettingsRepository.save(newSettings);
          },
        );
      }).toList(),
    );
  }

  Widget _buildScaleTab(
    MosqueSettings settings,
    DisplayProvider provider,
    ScreenScale scale,
  ) {
    final scales = [
      (
        0.80,
        'صغير جداً (80%)',
        'مخصص للشاشات الصغيرة أو شاشات 720p HD Ready لتقليص حجم القوائم ومنع خروج العناصر عن الحواف.',
      ),
      (
        0.90,
        'مدمج ومتوازن (90%) - موصى به',
        'النسبة المثالية لشاشات التلفزيون المنزلية والمسجدية 720p و 1080p — تناسق كامل وأناقة متناهية.',
      ),
      (
        1.00,
        'قياسي افتراضي (100%)',
        'المقياس القياسي المعتمد للشاشات العريضة والشاشات ذات المسافة المعتدلة.',
      ),
      (
        1.10,
        'كبير وبارز (110%)',
        'مخصص للمساجد الواسعة جداً ذات المسافة البعيدة (15-20 متراً) أو شاشات 4K فائقة الوضوح.',
      ),
    ];

    return Column(
      children: scales.map((sc) {
        final (val, title, desc) = sc;
        final isSelected = (settings.uiScaleFactor - val).abs() < 0.02;
        return _DesignCard(
          title: title,
          description: desc,
          isSelected: isSelected,
          badgeText: '${(val * 100).toInt()}%',
          onTap: () async {
            final newSettings = settings.copyWith(uiScaleFactor: val);
            await provider.updateSettings(newSettings);
            await SettingsRepository.save(newSettings);
          },
        );
      }).toList(),
    );
  }

  Widget _buildOptionsTab(
    MosqueSettings settings,
    DisplayProvider provider,
    ScreenScale scale,
  ) {
    return Column(
      children: [
        _ToggleRow(
          label: 'إظهار الثواني في الساعة الرئيسية',
          value: settings.showSeconds,
          onChanged: (v) async {
            final newSettings = settings.copyWith(showSeconds: v);
            await provider.updateSettings(newSettings);
            await SettingsRepository.save(newSettings);
          },
        ),
        SizedBox(height: scale.scale(12, min: 8, max: 16)),
        _ToggleRow(
          label: 'إظهار التاريخ الميلادي تحت التاريخ الهجري',
          value: settings.showGregorianDate,
          onChanged: (v) async {
            final newSettings = settings.copyWith(showGregorianDate: v);
            await provider.updateSettings(newSettings);
            await SettingsRepository.save(newSettings);
          },
        ),
        SizedBox(height: scale.scale(12, min: 8, max: 16)),
        _NumberStepper(
          label: 'مدة بقاء كاروسيل أذكار ما بعد الصلاة (بالدقائق)',
          value: settings.adhkarDurationMinutes,
          min: 2,
          max: 20,
          helperText: 'تختفي شاشة الأذكار تلقائياً وتعود إلى الواجهة الرئيسية بعد انقضاء هذه المدة.',
          onChanged: (v) async {
            final newSettings = settings.copyWith(adhkarDurationMinutes: v);
            await provider.updateSettings(newSettings);
            await SettingsRepository.save(newSettings);
          },
        ),
      ],
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
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            ...prayers.map((entry) {
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
            }),
            const SizedBox(height: 8),
            _NumberStepper(
              label: 'خطبة وانتظار الجمعة',
              value: delays.jumuah,
              min: 15,
              max: 90,
              onChanged: (v) async {
                final newDelays = delays.copyWith(jumuah: v);
                final newSettings = settings.copyWith(iqamahDelays: newDelays);
                await context.read<DisplayProvider>().updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
              },
            ),
          ],
        ),
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
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.emeraldDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldDim.withValues(alpha: 0.4)),
            ),
            child: _ToggleRow(
              label: 'إظهار أوقات الإمساك والإفطار (في رمضان ومواسم الصيام)',
              value: settings.showFastingTimes,
              onChanged: (val) async {
                final newSettings = settings.copyWith(showFastingTimes: val);
                await context.read<DisplayProvider>().updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
              },
            ),
          ),
          const SizedBox(height: 16),
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

                return _FocusableHijriCard(
                  title: title,
                  desc: desc,
                  optionPreview: optionPreview,
                  isSelected: isSelected,
                  onTap: () async {
                    final newSettings =
                        settings.copyWith(hijriOffsetDays: offsetVal);
                    await context
                        .read<DisplayProvider>()
                        .updateSettings(newSettings);
                    await SettingsRepository.save(newSettings);
                  },
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
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 24),
          ],
        ),
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
  String _newPin = '';
  String? _msg;

  void _appendDigit(String d) {
    if (_newPin.length < 4) {
      setState(() {
        _newPin += d;
        _msg = null;
      });
    }
  }

  void _backspace() {
    if (_newPin.isNotEmpty) {
      setState(() {
        _newPin = _newPin.substring(0, _newPin.length - 1);
        _msg = null;
      });
    }
  }

  Future<void> _savePin() async {
    if (_newPin.length == 4) {
      final newSettings = widget.settings.copyWith(pinCode: _newPin);
      await context.read<DisplayProvider>().updateSettings(newSettings);
      await SettingsRepository.save(newSettings);
      setState(() {
        _msg = 'تم حفظ رمز PIN بنجاح ✓';
        _newPin = '';
      });
    } else {
      setState(() => _msg = 'يجب إدخال 4 أرقام كاملة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
      title: 'رمز الأمان (PIN)',
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
              _appendDigit('0');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
              _appendDigit('1');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
              _appendDigit('2');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
              _appendDigit('3');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
              _appendDigit('4');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
              _appendDigit('5');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
              _appendDigit('6');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
              _appendDigit('7');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
              _appendDigit('8');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
              _appendDigit('9');
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
              _backspace();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
              _savePin();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'رمز PIN الحالي: ${widget.settings.pinCode}',
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 24, color: AppTheme.textPrimary),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              // PIN Indicator Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isFilled = i < _newPin.length;
                  return Container(
                    width: 50,
                    height: 54,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isFilled ? AppTheme.emeraldLight : AppTheme.emeraldMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFilled ? AppTheme.goldPrimary : AppTheme.emeraldLight,
                        width: 2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isFilled ? _newPin[i] : '—',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  );
                }),
              ),
              if (_msg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _msg!,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        color: AppTheme.goldPrimary),
                  ),
                ),
              const SizedBox(height: 16),
              // On-screen TV Numpad (D-pad operable, zero keyboard freezing)
              _buildNumpadRow(['1', '2', '3']),
              const SizedBox(height: 8),
              _buildNumpadRow(['4', '5', '6']),
              const SizedBox(height: 8),
              _buildNumpadRow(['7', '8', '9']),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NumpadKey(
                    label: 'مسح ⌫',
                    isAction: true,
                    onTap: _backspace,
                  ),
                  const SizedBox(width: 8),
                  _NumpadKey(
                    label: '0',
                    onTap: () => _appendDigit('0'),
                  ),
                  const SizedBox(width: 8),
                  _NumpadKey(
                    label: 'حفظ ✓',
                    isAction: true,
                    isSave: true,
                    onTap: _savePin,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _NumpadKey(
            label: d,
            onTap: () => _appendDigit(d),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  final bool isSave;

  const _NumpadKey({
    required this.label,
    required this.onTap,
    this.isAction = false,
    this.isSave = false,
  });

  @override
  State<_NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<_NumpadKey> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSave
        ? (_focused ? AppTheme.goldLight : AppTheme.goldPrimary)
        : (_focused ? AppTheme.emeraldLight : AppTheme.emeraldMid);
    final textCol = widget.isSave
        ? AppTheme.emeraldDeep
        : (_focused ? AppTheme.goldPrimary : AppTheme.textPrimary);

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.numpadEnter ||
             event.logicalKey == LogicalKeyboardKey.space ||
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: widget.isAction ? 92 : 72,
          height: 48,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppTheme.goldPrimary : AppTheme.emeraldLight,
              width: _focused ? 2.5 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: widget.isAction ? 17 : 22,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
        ),
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
    final scale = ScreenScale.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(22, min: 14, max: 32),
        vertical: scale.scale(14, min: 10, max: 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: scale.scale(24, min: 18, max: 30),
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.w700,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(height: scale.scale(6, min: 4, max: 10)),
          IslamicDivider(color: AppTheme.goldDim, height: scale.scale(14, min: 10, max: 18)),
          SizedBox(height: scale.scale(10, min: 6, max: 14)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NumberStepper extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? helperText;
  final bool isHighlighted;

  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.helperText,
    this.isHighlighted = false,
  });

  @override
  State<_NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<_NumberStepper> {
  bool _isFocused = false;

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScreenScale.of(context);
    final display = '${widget.value}';
    return Focus(
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) _ensureVisible();
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (widget.value > widget.min) {
              widget.onChanged(widget.value - 1);
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (widget.value < widget.max) {
              widget.onChanged(widget.value + 1);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(vertical: scale.scale(3, min: 2, max: 6)),
        padding: EdgeInsets.symmetric(
          vertical: scale.scale(7, min: 5, max: 12),
          horizontal: scale.scale(14, min: 10, max: 18),
        ),
        decoration: BoxDecoration(
          color: _isFocused
              ? AppTheme.emeraldLight.withValues(alpha: 0.5)
              : (widget.isHighlighted
                  ? AppTheme.goldPrimary.withValues(alpha: 0.12)
                  : AppTheme.emeraldMid.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(scale.scale(10, min: 8, max: 14)),
          border: Border.all(
            color: _isFocused
                ? AppTheme.goldPrimary
                : (widget.isHighlighted ? AppTheme.goldDim : AppTheme.emeraldLight),
            width: _isFocused ? 2.2 : (widget.isHighlighted ? 1.5 : 1.0),
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: scale.scale(18, min: 14, max: 22),
                      color: _isFocused || widget.isHighlighted
                          ? AppTheme.goldPrimary
                          : AppTheme.textPrimary,
                      fontWeight: _isFocused || widget.isHighlighted
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  if (widget.helperText != null)
                    Text(
                      widget.helperText!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: scale.scale(12, min: 10, max: 15),
                        color: AppTheme.textSecondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isFocused)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '◀ الأسهم للتعديل ▶',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scale(11, min: 9, max: 13),
                    color: AppTheme.goldDim,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Non-focusing decrement button
            GestureDetector(
              onTap: widget.value > widget.min
                  ? () => widget.onChanged(widget.value - 1)
                  : null,
              child: Container(
                width: scale.scale(36, min: 28, max: 44),
                height: scale.scale(36, min: 28, max: 44),
                decoration: BoxDecoration(
                  color: widget.value > widget.min
                      ? AppTheme.emeraldLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.value > widget.min
                        ? AppTheme.goldDim
                        : AppTheme.emeraldLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  color: widget.value > widget.min
                      ? AppTheme.goldPrimary
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  size: scale.scale(20, min: 16, max: 24),
                ),
              ),
            ),
            SizedBox(
              width: scale.scale(60, min: 46, max: 74),
              child: Text(
                display,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: scale.scale(22, min: 17, max: 28),
                  color: AppTheme.goldPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Non-focusing increment button
            GestureDetector(
              onTap: widget.value < widget.max
                  ? () => widget.onChanged(widget.value + 1)
                  : null,
              child: Container(
                width: scale.scale(36, min: 28, max: 44),
                height: scale.scale(36, min: 28, max: 44),
                decoration: BoxDecoration(
                  color: widget.value < widget.max
                      ? AppTheme.emeraldLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.value < widget.max
                        ? AppTheme.goldDim
                        : AppTheme.emeraldLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: widget.value < widget.max
                      ? AppTheme.goldPrimary
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  size: scale.scale(20, min: 16, max: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  bool _isFocused = false;

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScreenScale.of(context);
    return Focus(
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) _ensureVisible();
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onChanged(!widget.value);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(vertical: scale.scale(3, min: 2, max: 6)),
          padding: EdgeInsets.symmetric(
            vertical: scale.scale(6, min: 4, max: 10),
            horizontal: scale.scale(14, min: 10, max: 18),
          ),
          decoration: BoxDecoration(
            color: _isFocused
                ? AppTheme.emeraldLight.withValues(alpha: 0.4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(scale.scale(10, min: 8, max: 14)),
            border: _isFocused
                ? Border.all(color: AppTheme.goldPrimary, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: scale.scale(18, min: 14, max: 22),
                  color: _isFocused ? AppTheme.goldPrimary : AppTheme.textPrimary,
                  fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
                ),
                textDirection: TextDirection.rtl,
              ),
              const Spacer(),
              Switch(
                value: widget.value,
                onChanged: widget.onChanged,
                activeThumbColor: AppTheme.goldPrimary,
                activeTrackColor: AppTheme.emeraldLight,
              ),
            ],
          ),
        ),
      ),
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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (widget.maxLines == 1) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            node.nextFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            node.unfocus();
            return KeyEventResult.handled;
          }
        }
        if (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.goBack) {
          node.unfocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void didUpdateWidget(covariant _EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
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
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          textInputAction: widget.maxLines == 1
              ? TextInputAction.done
              : TextInputAction.newline,
          onSubmitted: (text) {
            _focusNode.unfocus();
            if (widget.maxLines == 1) {
              widget.onSaved(text.trim());
            }
          },
          onTapOutside: (_) => _focusNode.unfocus(),
          enableInteractiveSelection: true,
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
            onTap: () {
              _focusNode.unfocus();
              widget.onSaved(_ctrl.text.trim());
            }),
      ],
    );
  }
}

class _SettingsButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _SettingsButton({required this.label, this.onTap});

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (widget.onTap != null && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap!();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.onTap != null ? AppTheme.goldGradient : null,
            color: widget.onTap == null ? AppTheme.emeraldLight : null,
            borderRadius: BorderRadius.circular(10),
            border: _isFocused
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.onTap != null ? AppTheme.emeraldDeep : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sidebar Item ─────────────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;
  final bool autofocus;

  const _SidebarItem({
    required this.label,
    required this.isSelected,
    required this.onSelect,
    this.autofocus = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isFocused = false;

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScreenScale.of(context);
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) _ensureVisible();
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(
            horizontal: scale.scale(8, min: 4, max: 12),
            vertical: scale.scale(2, min: 1, max: 4),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: scale.scale(12, min: 8, max: 16),
            vertical: scale.scale(7, min: 5, max: 11),
          ),
          decoration: _isFocused
              ? AppTheme.focusedDecoration()
              : (widget.isSelected
                  ? BoxDecoration(
                      color: AppTheme.emeraldLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(scale.scale(10, min: 8, max: 14)),
                      border: Border.all(color: AppTheme.goldDim, width: 1.5),
                    )
                  : AppTheme.unfocusedDecoration()),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(15, min: 13, max: 19),
              color: _isFocused || widget.isSelected
                  ? AppTheme.goldPrimary
                  : AppTheme.textSecondary,
              fontWeight: _isFocused || widget.isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

// ── Design Selection Card ───────────────────────────────────────────────────

class _DesignCard extends StatefulWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final List<Color>? colors;
  final String? badgeText;

  const _DesignCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.colors,
    this.badgeText,
  });

  @override
  State<_DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends State<_DesignCard> {
  bool _isFocused = false;

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScreenScale.of(context);
    return Focus(
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) _ensureVisible();
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.only(bottom: scale.scale(7, min: 4, max: 10)),
          padding: EdgeInsets.symmetric(
            horizontal: scale.scale(14, min: 10, max: 20),
            vertical: scale.scale(10, min: 7, max: 14),
          ),
          decoration: _isFocused
              ? AppTheme.focusedDecoration()
              : BoxDecoration(
                  color: widget.isSelected
                      ? AppTheme.emeraldLight.withValues(alpha: 0.6)
                      : AppTheme.emeraldMid.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(scale.scale(12, min: 8, max: 16)),
                  border: Border.all(
                    color: widget.isSelected ? AppTheme.goldPrimary : AppTheme.emeraldLight,
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
          child: Row(
            children: [
              Icon(
                widget.isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: widget.isSelected
                    ? AppTheme.goldPrimary
                    : AppTheme.textSecondary,
                size: scale.scale(22, min: 18, max: 26),
              ),
              SizedBox(width: scale.scale(12, min: 8, max: 16)),
              if (widget.colors != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.colors!.map((c) => Container(
                    width: scale.scale(20, min: 16, max: 24),
                    height: scale.scale(20, min: 16, max: 24),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.goldDim, width: 1.2),
                    ),
                  )).toList(),
                ),
                SizedBox(width: scale.scale(12, min: 8, max: 16)),
              ],
              if (widget.badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isSelected ? AppTheme.goldPrimary : AppTheme.emeraldLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.badgeText!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: scale.scale(13, min: 11, max: 15),
                      fontWeight: FontWeight.bold,
                      color: widget.isSelected ? AppTheme.emeraldDeep : AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: scale.scale(12, min: 8, max: 16)),
              ],
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.isSelected ? AppTheme.goldPrimary : AppTheme.textSecondary,
                  size: scale.scale(26, min: 20, max: 32),
                ),
                SizedBox(width: scale.scale(12, min: 8, max: 16)),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: scale.scale(17, min: 14, max: 21),
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                        color: widget.isSelected || _isFocused
                            ? AppTheme.goldPrimary
                            : AppTheme.textPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: scale.scale(12, min: 10, max: 15),
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
      ),
    );
  }
}

// ── Tab Button ───────────────────────────────────────────────────────────────

class _TabButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive ? AppTheme.goldPrimary : AppTheme.emeraldLight,
            borderRadius: BorderRadius.circular(8),
            border: _isFocused
                ? Border.all(color: Colors.white, width: 2)
                : (widget.isActive ? Border.all(color: AppTheme.goldPrimary) : null),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isActive ? AppTheme.emeraldDeep : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Focusable List Tile ──────────────────────────────────────────────────────

class _FocusableListTile extends StatefulWidget {
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusableListTile({
    required this.title,
    this.leading,
    this.trailing,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FocusableListTile> createState() => _FocusableListTileState();
}

class _FocusableListTileState extends State<_FocusableListTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: _isFocused
              ? AppTheme.focusedDecoration()
              : (widget.isSelected
                  ? BoxDecoration(
                      color: AppTheme.emeraldLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.goldPrimary,
                        width: 2,
                      ),
                    )
                  : BoxDecoration(
                      color: AppTheme.emeraldMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.emeraldLight,
                        width: 1,
                      ),
                    )),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.title,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 10),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Focusable Font Card ──────────────────────────────────────────────────────

class _FocusableFontCard extends StatefulWidget {
  final IslamicFontOption font;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusableFontCard({
    required this.font,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FocusableFontCard> createState() => _FocusableFontCardState();
}

class _FocusableFontCardState extends State<_FocusableFontCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: _isFocused
              ? AppTheme.focusedDecoration()
              : BoxDecoration(
                  color: AppTheme.emeraldMid,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isSelected ? AppTheme.goldPrimary : AppTheme.emeraldLight,
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
          child: Row(
            children: [
              Icon(
                widget.isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: widget.isSelected
                    ? AppTheme.goldPrimary
                    : AppTheme.textSecondary,
                size: 26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.font.nameAr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected || _isFocused
                            ? AppTheme.goldPrimary
                            : AppTheme.textPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.font.descriptionAr,
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
                          color: widget.isSelected
                              ? AppTheme.goldDim
                              : AppTheme.emeraldLight,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.font.sample,
                        style: AppTheme.getIslamicStyle(
                          fontKey: widget.font.key,
                          fontSize: 24,
                          color: widget.isSelected || _isFocused
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
      ),
    );
  }
}

// ── Focusable Hijri Card ─────────────────────────────────────────────────────

class _FocusableHijriCard extends StatefulWidget {
  final String title;
  final String desc;
  final HijriDate optionPreview;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusableHijriCard({
    required this.title,
    required this.desc,
    required this.optionPreview,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FocusableHijriCard> createState() => _FocusableHijriCardState();
}

class _FocusableHijriCardState extends State<_FocusableHijriCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: _isFocused
              ? AppTheme.focusedDecoration()
              : BoxDecoration(
                  color: AppTheme.emeraldMid,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected ? AppTheme.goldPrimary : AppTheme.emeraldLight,
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                widget.isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: widget.isSelected
                    ? AppTheme.goldPrimary
                    : AppTheme.textSecondary,
                size: 26,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                      : AppTheme.emeraldDeep,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.goldPrimary
                        : AppTheme.emeraldLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${widget.optionPreview.day} ${widget.optionPreview.monthNameAr}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isSelected || _isFocused
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
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 21,
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: widget.isSelected || _isFocused
                            ? AppTheme.goldPrimary
                            : AppTheme.textPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      widget.desc,
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

// ── Remote Administration & QR Pairing Page ──────────────────────────────────

class _RemoteAdminPage extends StatelessWidget {
  final MosqueSettings settings;
  const _RemoteAdminPage({required this.settings});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final isRunning = provider.isRemoteAdminRunning;
    final url = provider.remoteAdminUrl ?? provider.remoteAdminDirectUrl ?? '';
    final ip = provider.remoteAdminIp ?? '127.0.0.1';
    final port = provider.remoteAdminPort ?? settings.remoteAdminPort;

    return _PageWrapper(
      title: 'التحكم عن بعد والاقتران اللاسلكي (QR)',
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enable Server Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.emeraldDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.goldDim.withValues(alpha: 0.4)),
              ),
              child: _ToggleRow(
                label: 'تفعيل خادم الإدارة اللاسلكية عبر شبكة Wi-Fi المحلية',
                value: settings.remoteAdminEnabled,
                onChanged: (val) async {
                  final newSettings = settings.copyWith(remoteAdminEnabled: val);
                  await context.read<DisplayProvider>().updateSettings(newSettings);
                  await SettingsRepository.save(newSettings);
                },
              ),
            ),
            const SizedBox(height: 16),

            if (!settings.remoteAdminEnabled || !isRunning)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.redAccent, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الخادم اللاسلكي متوقف حالياً',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'قم بتفعيل الخيار أعلاه للسماح للأئمة والمشرفين بالتحكم في شاشة المسجد وتعديل الإعدادات لاسلكياً من الهاتف.',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldDeep,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.6), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: QR Code Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.goldPrimary, width: 2),
                          ),
                          child: url.isNotEmpty
                              ? QrImageView(
                                  data: url,
                                  version: QrVersions.auto,
                                  size: 170,
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
                              : const SizedBox(
                                  width: 170,
                                  height: 170,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                        ),
                        const SizedBox(width: 20),

                        // Right: Instructions & Credentials
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF2ECC71)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'الخادم نشط ويعمل على الشبكة المحلية',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2ECC71),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'امسح رمز الـ QR بكاميرا هاتفك المحمول المتصل بنفس شبكة Wi-Fi للتحكم الفوري في إعدادات المسجد والمواقيت.',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: AppTheme.textPrimary.withValues(alpha: 0.95),
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 14),
                              // Connection info strip
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldMid,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.goldDim.withValues(alpha: 0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('الرابط المباشر: ', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                                        SelectableText('http://$ip:$port', style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('رمز PIN للدخول: ', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                                        Text(settings.pinCode, style: const TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.emeraldLight),
                    const SizedBox(height: 12),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('عرض رمز الـ QR بحجم شاشة كامل (Q)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: AppTheme.emeraldDeep,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => QrPairingDialog.show(context),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('تحديث الرمز السري (Token)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.goldLight,
                            side: const BorderSide(color: AppTheme.goldDim),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            provider.regenerateRemoteAdminToken();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Server Port Setting
            _NumberStepper(
              label: 'منفذ خادم الويب (Port)',
              value: settings.remoteAdminPort,
              min: 1024,
              max: 9999,
              helperText: 'المنفذ الافتراضي هو 8080. يمكنك تغييره في حال كان المنفذ مستخدماً من تطبيق آخر.',
              onChanged: (v) async {
                final newSettings = settings.copyWith(remoteAdminPort: v);
                await context.read<DisplayProvider>().updateSettings(newSettings);
                await SettingsRepository.save(newSettings);
              },
            ),
          ],
        ),
      ),
    );
  }
}

