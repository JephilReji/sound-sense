import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/sound_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  bool _notifications = true;
  bool _panicMode = true;
  double _sensitivity = 0.65;
  double _panicThreshold = 100.0;
  double _pendingSensitivity = 0.65;
  double _pendingPanicThreshold = 100.0;
  bool _sensitivitySaved = false;
  bool _panicThresholdSaved = false;
  bool _hornEnabled = true;
  bool _sirenEnabled = true;
  bool _safetyAlarmEnabled = true;
  bool _heavyEnabled = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('settings_notifications') ?? true;
      _panicMode = prefs.getBool('settings_panicMode') ?? true;
      _sensitivity = prefs.getDouble('settings_sensitivity') ?? 0.65;
      _pendingSensitivity = _sensitivity;
      _panicThreshold = prefs.getDouble('settings_panicThreshold') ?? 100.0;
      _pendingPanicThreshold = _panicThreshold;
      _hornEnabled = prefs.getBool('settings_horn') ?? true;
      _sirenEnabled = prefs.getBool('settings_siren') ?? true;
      _safetyAlarmEnabled = prefs.getBool('settings_safety') ?? true;
      _heavyEnabled = prefs.getBool('settings_heavy') ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _sectionHeader('ALERT METHODS'),
                    _buildAlertMethodsCard(),
                    const SizedBox(height: 20),
                    _sectionHeader('DETECTION SENSITIVITY'),
                    _buildSensitivityCard(),
                    const SizedBox(height: 20),
                    _sectionHeader('SOUND CLASSES'),
                    _buildSoundClassesCard(),
                    const SizedBox(height: 20),
                    _sectionHeader('PANIC PROTOCOL'),
                    _buildPanicCard(),
                    const SizedBox(height: 20),
                    _sectionHeader('ALERT COLOR GUIDE'),
                    _buildColorGuideCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        'Settings',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAlertMethodsCard() {
    return _SettingsCard(
      children: [
        _ToggleRow(
          icon: Icons.notifications_rounded,
          iconColor: const Color(0xFF00EAAA),
          title: 'Notifications',
          subtitle: 'Show system notification on danger',
          value: _notifications,
          onChanged: (v) {
            setState(() => _notifications = v);
            _saveBool('settings_notifications', v);
          },
        ),
      ],
    );
  }

  Widget _buildSensitivityCard() {
    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detection Threshold',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.accent.withOpacity(0.15),
                    ),
                    child: Text(
                      '${(_pendingSensitivity * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Minimum AI confidence to trigger an alert',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.accent,
                  inactiveTrackColor: AppTheme.border,
                  thumbColor: Colors.white,
                  overlayColor: AppTheme.accent.withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _pendingSensitivity,
                  min: 0.4,
                  max: 0.95,
                  onChanged: (v) => setState(() {
                    _pendingSensitivity = v;
                    _sensitivitySaved = false;
                  }),
                  onChangeEnd: (v) => _confirmSlider(
                    label: 'Detection Threshold',
                    displayValue: '${(v * 100).toStringAsFixed(0)}%',
                    onConfirm: () {
                      setState(() {
                        _sensitivity = v;
                        _sensitivitySaved = true;
                      });
                      _saveDouble('settings_sensitivity', v);
                    },
                    onCancel: () => setState(() {
                      _pendingSensitivity = _sensitivity;
                    }),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Sensitive', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text('Strict', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
              if (_sensitivitySaved) ...[
                const SizedBox(height: 8),
                _savedIndicator(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoundClassesCard() {
    final classes = [
      {'emoji': '📯', 'title': 'Vehicle Horns', 'subtitle': 'Loud, close-range honking', 'sc': SoundClass.horn},
      {'emoji': '🚨', 'title': 'Emergency Sirens', 'subtitle': 'Ambulance, police, fire', 'sc': SoundClass.siren},
      {'emoji': '🔔', 'title': 'Safety Alarms', 'subtitle': 'Fire alarms & danger alerts', 'sc': SoundClass.safetyAlarm},
      {'emoji': '🚛', 'title': 'Heavy Vehicles', 'subtitle': 'Trucks, buses, lorries', 'sc': SoundClass.heavyVehicle},
    ];

    return _SettingsCard(
      children: [
        ...classes.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final sc = c['sc'] as SoundClass;
          final enabled = _getEnabled(sc);
          return Column(
            children: [
              _EmojiToggleRow(
                emoji: c['emoji'] as String,
                title: c['title'] as String,
                subtitle: c['subtitle'] as String,
                value: enabled,
                onChanged: (v) => _setEnabled(sc, v),
              ),
              if (i < classes.length - 1) _divider(),
            ],
          );
        }),
      ],
    );
  }

  bool _getEnabled(SoundClass sc) {
    switch (sc) {
      case SoundClass.horn:
        return _hornEnabled;
      case SoundClass.siren:
        return _sirenEnabled;
      case SoundClass.safetyAlarm:
        return _safetyAlarmEnabled;
      case SoundClass.heavyVehicle:
        return _heavyEnabled;
    }
  }

  void _setEnabled(SoundClass sc, bool v) {
    setState(() {
      switch (sc) {
        case SoundClass.horn:
          _hornEnabled = v;
          _saveBool('settings_horn', v);
          break;
        case SoundClass.siren:
          _sirenEnabled = v;
          _saveBool('settings_siren', v);
          break;
        case SoundClass.safetyAlarm:
          _safetyAlarmEnabled = v;
          _saveBool('settings_safety', v);
          break;
        case SoundClass.heavyVehicle:
          _heavyEnabled = v;
          _saveBool('settings_heavy', v);
          break;
      }
    });
  }

  Widget _buildPanicCard() {
    return _SettingsCard(
      children: [
        _ToggleRow(
          icon: Icons.warning_amber_rounded,
          iconColor: AppTheme.alertSiren,
          title: 'Panic Protocol',
          subtitle: 'Triggers when sound exceeds panic threshold',
          value: _panicMode,
          onChanged: (v) {
            setState(() => _panicMode = v);
            _saveBool('settings_panicMode', v);
          },
        ),
        _divider(),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Panic Threshold',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.alertSiren.withOpacity(0.15),
                    ),
                    child: Text(
                      '${_pendingPanicThreshold.toStringAsFixed(0)} dB',
                      style: const TextStyle(
                        color: AppTheme.alertSiren,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Maximum intensity triggers strobe + max vibration',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.alertSiren,
                  inactiveTrackColor: AppTheme.border,
                  thumbColor: Colors.white,
                  overlayColor: AppTheme.alertSiren.withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _pendingPanicThreshold,
                  min: 85,
                  max: 115,
                  onChanged: _panicMode
                      ? (v) => setState(() {
                            _pendingPanicThreshold = v;
                            _panicThresholdSaved = false;
                          })
                      : null,
                  onChangeEnd: _panicMode
                      ? (v) => _confirmSlider(
                            label: 'Panic Threshold',
                            displayValue: '${v.toStringAsFixed(0)} dB',
                            onConfirm: () {
                              setState(() {
                                _panicThreshold = v;
                                _panicThresholdSaved = true;
                              });
                              _saveDouble('settings_panicThreshold', v);
                            },
                            onCancel: () => setState(() {
                              _pendingPanicThreshold = _panicThreshold;
                            }),
                          )
                      : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('85 dB', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text('115 dB', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
              if (_panicThresholdSaved) ...[
                const SizedBox(height: 8),
                _savedIndicator(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorGuideCard() {
    final guide = [
      {'color': AppTheme.alertSiren, 'emoji': '🚨', 'label': 'Emergency Siren', 'shade': 'Blue'},
      {'color': AppTheme.alertHorn, 'emoji': '📯', 'label': 'Vehicle Horn', 'shade': 'Orange'},
      {'color': AppTheme.alertHeavy, 'emoji': '🚛', 'label': 'Heavy Vehicle', 'shade': 'Green'},
      {'color': AppTheme.alertSafetyAlarm, 'emoji': '🔔', 'label': 'Safety Alarm', 'shade': 'Red'},
    ];

    return _SettingsCard(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Each sound type triggers a unique screen color to help you identify the threat at a glance.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
        ),
        Column(
          children: guide.asMap().entries.map((entry) {
            final i = entry.key;
            final g = entry.value;
            final col = g['color'] as Color;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: col.withOpacity(0.08),
                    border: Border.all(color: col.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Text(g['emoji'] as String, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g['label'] as String,
                                style: TextStyle(
                                    color: col,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            Text(g['shade'] as String,
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: col,
                          boxShadow: [
                            BoxShadow(color: col.withOpacity(0.4), blurRadius: 8)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < guide.length - 1) const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  void _confirmSlider({
    required String label,
    required String displayValue,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.12),
                ),
                child: const Icon(Icons.save_rounded,
                    color: AppTheme.accent, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                'Save $label?',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apply $label at $displayValue?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onCancel();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppTheme.surfaceElevated,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A6DFF), Color(0xFF0830A0)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('Save',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savedIndicator() {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF00EAAA), size: 15),
        const SizedBox(width: 6),
        const Text(
          'Saved successfully',
          style: TextStyle(
            color: Color(0xFF00EAAA),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Divider(color: AppTheme.border, height: 1, thickness: 1);
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: iconColor.withOpacity(0.15),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accentDim,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.border,
          ),
        ],
      ),
    );
  }
}

class _EmojiToggleRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EmojiToggleRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(emoji, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accentDim,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.border,
          ),
        ],
      ),
    );
  }
}