import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';


// Settings providers
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier());

// App settings model
class AppSettings {
  final String theme;
  final String language;
  final double fontSize;
  final String fontFamily;
  final bool showTransliteration;
  final bool showTranslation;
  final bool showTafsir;
  final bool audioEnabled;
  final double audioVolume;
  final bool notificationsEnabled;
  final bool hapticFeedbackEnabled;
  final String reciter;
  final bool autoPlay;
  final bool repeatMode;

  AppSettings({
    this.theme = 'system',
    this.language = 'tajik',
    this.fontSize = 16.0,
    this.fontFamily = 'Roboto',
    this.showTransliteration = true,
    this.showTranslation = true,
    this.showTafsir = true,
    this.audioEnabled = true,
    this.audioVolume = 0.8,
    this.notificationsEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.reciter = 'default',
    this.autoPlay = false,
    this.repeatMode = false,
  });

  AppSettings copyWith({
    String? theme,
    String? language,
    double? fontSize,
    String? fontFamily,
    bool? showTransliteration,
    bool? showTranslation,
    bool? showTafsir,
    bool? audioEnabled,
    double? audioVolume,
    bool? notificationsEnabled,
    bool? hapticFeedbackEnabled,
    String? reciter,
    bool? autoPlay,
    bool? repeatMode,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTranslation: showTranslation ?? this.showTranslation,
      showTafsir: showTafsir ?? this.showTafsir,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      audioVolume: audioVolume ?? this.audioVolume,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      reciter: reciter ?? this.reciter,
      autoPlay: autoPlay ?? this.autoPlay,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  static const String _keyTheme = 'theme';
  static const String _keyLanguage = 'language';
  static const String _keyFontSize = 'font_size';
  static const String _keyFontFamily = 'font_family';
  static const String _keyShowTransliteration = 'show_transliteration';
  static const String _keyShowTranslation = 'show_translation';
  static const String _keyShowTafsir = 'show_tafsir';
  static const String _keyAudioEnabled = 'audio_enabled';
  static const String _keyAudioVolume = 'audio_volume';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyHapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const String _keyReciter = 'reciter';
  static const String _keyAutoPlay = 'auto_play';
  static const String _keyRepeatMode = 'repeat_mode';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    state = state.copyWith(
      theme: prefs.getString(_keyTheme) ?? 'system',
      language: prefs.getString(_keyLanguage) ?? 'tajik',
      fontSize: prefs.getDouble(_keyFontSize) ?? 16.0,
      fontFamily: prefs.getString(_keyFontFamily) ?? 'Roboto',
      showTransliteration: prefs.getBool(_keyShowTransliteration) ?? true,
      showTranslation: prefs.getBool(_keyShowTranslation) ?? true,
      showTafsir: prefs.getBool(_keyShowTafsir) ?? true,
      audioEnabled: prefs.getBool(_keyAudioEnabled) ?? true,
      audioVolume: prefs.getDouble(_keyAudioVolume) ?? 0.8,
      notificationsEnabled: prefs.getBool(_keyNotificationsEnabled) ?? true,
      hapticFeedbackEnabled: prefs.getBool(_keyHapticFeedbackEnabled) ?? true,
      reciter: prefs.getString(_keyReciter) ?? 'default',
      autoPlay: prefs.getBool(_keyAutoPlay) ?? false,
      repeatMode: prefs.getBool(_keyRepeatMode) ?? false,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, state.theme);
    await prefs.setString(_keyLanguage, state.language);
    await prefs.setDouble(_keyFontSize, state.fontSize);
    await prefs.setString(_keyFontFamily, state.fontFamily);
    await prefs.setBool(_keyShowTransliteration, state.showTransliteration);
    await prefs.setBool(_keyShowTranslation, state.showTranslation);
    await prefs.setBool(_keyShowTafsir, state.showTafsir);
    await prefs.setBool(_keyAudioEnabled, state.audioEnabled);
    await prefs.setDouble(_keyAudioVolume, state.audioVolume);
    await prefs.setBool(_keyNotificationsEnabled, state.notificationsEnabled);
    await prefs.setBool(_keyHapticFeedbackEnabled, state.hapticFeedbackEnabled);
    await prefs.setString(_keyReciter, state.reciter);
    await prefs.setBool(_keyAutoPlay, state.autoPlay);
    await prefs.setBool(_keyRepeatMode, state.repeatMode);
  }

  void setTheme(String theme) {
    state = state.copyWith(theme: theme);
    _saveSettings();
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
    _saveSettings();
  }

  void setFontSize(double fontSize) {
    state = state.copyWith(fontSize: fontSize);
    _saveSettings();
  }

  void setFontFamily(String fontFamily) {
    state = state.copyWith(fontFamily: fontFamily);
    _saveSettings();
  }

  void setShowTransliteration(bool show) {
    state = state.copyWith(showTransliteration: show);
    _saveSettings();
  }

  void setShowTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
    _saveSettings();
  }

  void setShowTafsir(bool show) {
    state = state.copyWith(showTafsir: show);
    _saveSettings();
  }

  void setAudioEnabled(bool enabled) {
    state = state.copyWith(audioEnabled: enabled);
    _saveSettings();
  }

  void setAudioVolume(double volume) {
    state = state.copyWith(audioVolume: volume);
    _saveSettings();
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _saveSettings();
  }

  void setHapticFeedbackEnabled(bool enabled) {
    state = state.copyWith(hapticFeedbackEnabled: enabled);
    _saveSettings();
  }

  void setReciter(String reciter) {
    state = state.copyWith(reciter: reciter);
    _saveSettings();
  }

  void setAutoPlay(bool enabled) {
    state = state.copyWith(autoPlay: enabled);
    _saveSettings();
  }

  void setRepeatMode(bool enabled) {
    state = state.copyWith(repeatMode: enabled);
    _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = AppSettings();
    await _saveSettings();
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Танзимот'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            } catch (e) {
              GoRouter.of(context).go('/');
            }
          },
        ),
      ),
      body: ListView(
        children: [
          // Display Settings
          _buildSectionHeader('Намоиш'),
          _buildThemeSetting(settings, ref, context),
          _buildFontSizeSetting(settings, ref, context),
          _buildFontFamilySetting(settings, ref, context),
          
          const Divider(),
          
          // Audio Settings
          _buildSectionHeader('Аудио'),
          _buildAudioEnabledSetting(settings, ref),
          _buildReciterSetting(settings, ref, context),
          
          const Divider(),
          
          // About
          _buildSectionHeader('Дар бораи барнома'),
          _buildAboutSettings(context),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeSetting(AppSettings settings, WidgetRef ref, BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Намуди зоҳирӣ'),
      subtitle: Text(_getThemeName(settings.theme)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showThemeDialog(context, ref),
    );
  }


  Widget _buildFontSizeSetting(AppSettings settings, WidgetRef ref, BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('Андозаи ҳарф'),
      subtitle: Text('${settings.fontSize.toInt()}px'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showFontSizeDialog(context, ref),
    );
  }

  Widget _buildFontFamilySetting(AppSettings settings, WidgetRef ref, BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.font_download),
      title: const Text('Хусусияти ҳарф'),
      subtitle: Text(settings.fontFamily),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showFontFamilyDialog(context, ref),
    );
  }


  Widget _buildAudioEnabledSetting(AppSettings settings, WidgetRef ref) {
    return SwitchListTile(
      title: const Text('Тиловат'),
      subtitle: const Text('Тиловати сура ё оят'),
      value: settings.audioEnabled,
      onChanged: (value) => ref.read(settingsProvider.notifier).setAudioEnabled(value),
    );
  }


  Widget _buildReciterSetting(AppSettings settings, WidgetRef ref, BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.record_voice_over),
      title: const Text('Қори'),
      subtitle: Text(_getReciterName(settings.reciter)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showReciterDialog(context, ref),
    );
  }



  Widget _buildAboutSettings(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Дар бораи барнома'),
          subtitle: const Text('Версия 1.0.0'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showAboutDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Кӯмак'),
          subtitle: const Text('Роҳнамои истифода'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showHelpDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Сиёсати махфият'),
          subtitle: const Text('Ҳифзи маълумоти шумо'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showPrivacyDialog(context),
        ),
      ],
    );
  }

  // Helper methods
  String _getThemeName(String theme) {
    switch (theme) {
      case 'light': return 'Равшан';
      case 'dark': return 'Торик';
      case 'system': return 'Система';
      default: return 'Система';
    }
  }


  String _getReciterName(String reciter) {
    switch (reciter) {
      case 'default': return 'Пешфарз';
      case 'abdul_basit': return 'Абдул Босит';
      case 'mishary': return 'Мишари Рашид';
      default: return 'Пешфарз';
    }
  }

  // Dialog methods
  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Намуди зоҳирӣ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Равшан'),
              value: 'light',
              groupValue: ref.watch(settingsProvider).theme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Торик'),
              value: 'dark',
              groupValue: ref.watch(settingsProvider).theme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Система'),
              value: 'system',
              groupValue: ref.watch(settingsProvider).theme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }


  void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Андозаи ҳарф'),
        content: StatefulBuilder(
          builder: (context, setState) {
            final currentSize = ref.watch(settingsProvider).fontSize;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${currentSize.toInt()}px'),
                Slider(
                  value: currentSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  onChanged: (value) {
                    setState(() {});
                    ref.read(settingsProvider.notifier).setFontSize(value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

  void _showFontFamilyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Хусусияти ҳарф'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Amiri'),
              value: 'Amiri',
              groupValue: ref.watch(settingsProvider).fontFamily,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setFontFamily(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Noto Sans Arabic'),
              value: 'NotoSansArabic',
              groupValue: ref.watch(settingsProvider).fontFamily,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setFontFamily(value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Интихоби қориъ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Пешфарз'),
              value: 'default',
              groupValue: ref.watch(settingsProvider).reciter,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReciter(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Абдул Босит'),
              value: 'abdul_basit',
              groupValue: ref.watch(settingsProvider).reciter,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReciter(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Мишори Рашид'),
              value: 'mishary',
              groupValue: ref.watch(settingsProvider).reciter,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReciter(value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }


  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дар бораи барнома'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Қуръон бо Тафсири Осонбаён',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Ин барномаи мобилӣ барои хондан ва фаҳмидани Қуръон бо тарҷумаи тоҷикӣ ва тафсири осонбаён мебошад.',
              ),
              SizedBox(height: 12),

              Text(
                'Хусусиятҳо',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),

              Text(
                '📖 Хондани Қуръон',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Матни пурраи Қуръон дар шрифи Усмонӣ'),
              Text('• Тарҷумаи тоҷикӣ'),
              Text('• Транслитератсияи матни арабӣ бо хатти кирилӣ'),
              Text('• Тарҷумаи калима ба калима'),
              Text('• Маълумоти мухтасар оиди ҳар як сура'),
              Text('• Тафсири осонбаёни ҳар як оят'),

              SizedBox(height: 12),
              Text(
                '🔊 Аудио',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Қироати пурраи сураҳо'),
              Text('• Қироати оятҳо як ба як'),
              Text('• Рӯйхати қориҳо барои интихоб кардан'),

              SizedBox(height: 12),
              Text(
                '🔍 Ҷустуҷӯ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Ҷустуҷӯи пешрафта дар матни арабӣ, тарҷума ва транслитератсия'),
              Text('• Филтрҳои оқилона'),
              Text('• Дастрасии зуд'),

              SizedBox(height: 12),
              Text(
                '📚 Абзорҳои исломӣ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Тасбеҳ: 10 зикри маъруф бо тарҷумаи тоҷикӣ'),
              Text('• Тасбеҳгӯяк: абзор барои шуморидани зикрҳо'),
              Text('• Дуоҳо: маҷмӯаи дуоҳои Қуръонӣ бо тарҷума ва пайванд ба сарчашмаашон'),

              SizedBox(height: 12),
              Text(
                '⚙️ Танзимот',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Намуди зоҳирӣ: равшан, торик, система'),
              Text('• Андозаи матн'),
              Text('• Забон ва тарҷума'),

              SizedBox(height: 12),
              Text(
                'Офлайн',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Барнома барои истифодаи бе интернет мувофиқ аст ва барои таҷрибаи хуби хондан ва аудио оптимизатсия шудааст.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }


  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Кӯмак'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Роҳнамои истифода:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Барои хондани Қуръон, сураҳоро интихоб кунед'),
              Text('• Барои ҷустуҷӯ, тугмаи ҷустуҷӯро пахш кунед'),
              Text('• Барои захира кардан, тугмаи захираро пахш кунед'),
              Text('• Барои пахши аудио, тугмаи пахшро пахш кунед'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }

    void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сиёсати махфият'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Санаи эътибор:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('17 октябри 2025'),
              SizedBox(height: 12),

              Text(
                '1. Муқаддима',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Барномаи QuranApp (“мо”) маълумоти шуморо ҳимоя мекунад ва ин сиёсат нишон медиҳад, ки чӣ гуна маълумоти шумо истифода ва ҳифз мешавад.',
              ),
              SizedBox(height: 12),

              Text(
                '2. Маълумоте, ки мо ҷамъоварӣ намекунем',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Мо ҳеҷ маълумоти шахсии шумо, аз қабили ном, суроғаи почта, рақам ва ё макони ҷуғрофиро ҷамъ намекунем.',
              ),
              SizedBox(height: 12),

              Text(
                '3. Маълумоте, ки ба таври худкор ҷамъоварӣ карда мешавад',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Барнома метавонад маълумоти ғайри шахсӣ, ба монанди: версияи барнома, намуди дастгоҳ, забони барнома, ва статистикаи истифода (шумораи кушодани сураҳо) ҷамъ кунад. Ин маълумот барои беҳтар кардани барнома истифода мешавад.',
              ),
              SizedBox(height: 12),

              Text(
                '4. Чӣ гуна мо онро истифода мекунем',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Мо маълумоти ҷамъшударо танҳо барои беҳтар кардани барнома ва ислоҳи хатогиҳо истифода мекунем ва ҳеҷ гоҳ онро бо каси сеюм мубодила намекунем.',
              ),
              SizedBox(height: 12),

              Text(
                '5. Захираи маълумот',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Маълумоти шумо, аз қабили нишонаҳо, шумораи такрор ва танзимот дар дастгоҳи шумо маҳфуз мемонад ва ҳеҷ гоҳ ба серверҳои беруна ирсол намешавад.',
              ),
              SizedBox(height: 12),

              Text(
                '6. Хизматрасониҳои тарафи сеюм',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Барнома метавонад хидматрасониҳои эътимодноки тарафи сеюмро барои ҳисобҳои оморӣ ва ҳалли хатогиҳо истифода барад. Ин хизматрасониҳо маълумоти шахсии шуморо ҷамъ намекунанд.',
              ),
              SizedBox(height: 12),

              Text(
                '7. Ҳуқуқҳои шумо',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Шумо метавонед маълумоти маҳаллӣ дар барнома ва кэши барномаро тоза кунед ва барномаро аз дастгоҳи худ нест кунед, ки ҳамаи маълумоти маҳаллӣ нест мешаванд.',
              ),
              SizedBox(height: 12),

              Text(
                '8. Навсозии сиёсат',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: 'Мо метавонем ин сиёсатро давра ба давра навсозӣ кунем. Ҳама навсозиҳо дар вебсайти мо нашр карда мешаванд: ',
                    ),
                    TextSpan(
                      text: 'www.quran.tj/privacy',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final url = Uri.parse('https://www.quran.tj/privacy');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              Text(
                '9. Тамос бо мо',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Агар савол ё нигароние дошта бошед, бо мо тавассути почта тамос гиред: info@quran.tj',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Пӯшидан'),
          ),
        ],
      ),
    );
  }
}
