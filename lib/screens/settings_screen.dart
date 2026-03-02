import 'package:flutter/material.dart';
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

  // Settings state
  bool _notifications = true;
  bool _panicMode = true;
  double _sensitivity = 0.65;
  double _panicThreshold = 100.0;
  bool _hornEnabled = true;
  bool _sirenEnabled = true;
  bool _engineEnabled = true;
  bool _heavyEnabled = true;
  bool _bgEnabled = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
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
          onChanged: (v) => setState(() => _notifications = v),
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
                      '${(_sensitivity * 100).toStringAsFixed(0)}%',
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
                  value: _sensitivity,
                  min: 0.4,
                  max: 0.95,
                  onChanged: (v) => setState(() => _sensitivity = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Sensitive', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text('Strict', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
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
      {'emoji': '⚙️', 'title': 'Engine Revving', 'subtitle': 'High-rev motorcycle/car', 'sc': SoundClass.engine},
      {'emoji': '🚛', 'title': 'Heavy Vehicles', 'subtitle': 'Trucks, buses, lorries', 'sc': SoundClass.heavyVehicle},
      {'emoji': '🔈', 'title': 'Background Noise', 'subtitle': 'General traffic ambience', 'sc': SoundClass.background},
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
      case SoundClass.horn: return _hornEnabled;
      case SoundClass.siren: return _sirenEnabled;
      case SoundClass.engine: return _engineEnabled;
      case SoundClass.heavyVehicle: return _heavyEnabled;
      case SoundClass.background: return _bgEnabled;
    }
  }

  void _setEnabled(SoundClass sc, bool v) {
    setState(() {
      switch (sc) {
        case SoundClass.horn: _hornEnabled = v; break;
        case SoundClass.siren: _sirenEnabled = v; break;
        case SoundClass.engine: _engineEnabled = v; break;
        case SoundClass.heavyVehicle: _heavyEnabled = v; break;
        case SoundClass.background: _bgEnabled = v; break;
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
          onChanged: (v) => setState(() => _panicMode = v),
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
                      '${_panicThreshold.toStringAsFixed(0)} dB',
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
                  value: _panicThreshold,
                  min: 85,
                  max: 115,
                  onChanged: _panicMode ? (v) => setState(() => _panicThreshold = v) : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('85 dB', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text('115 dB', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorGuideCard() {
    final guide = [
      {'color': AppTheme.alertSiren, 'emoji': '🚨', 'label': 'Emergency Siren', 'shade': 'Bright Red'},
      {'color': AppTheme.alertHorn, 'emoji': '📯', 'label': 'Vehicle Horn', 'shade': 'Orange'},
      {'color': AppTheme.alertHeavy, 'emoji': '🚛', 'label': 'Heavy Vehicle', 'shade': 'Deep Orange'},
      {'color': AppTheme.alertEngine, 'emoji': '⚙️', 'label': 'Engine Rev', 'shade': 'Amber'},
      {'color': AppTheme.alertBackground, 'emoji': '🔈', 'label': 'Background', 'shade': 'Green'},
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: guide.map((g) {
            final col = g['color'] as Color;
            return Container(
              width: (MediaQuery.of(context).size.width - 80) / 2 - 4,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: col.withOpacity(0.1),
                border: Border.all(color: col.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(g['emoji'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g['label'] as String, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w700)),
                        Text(g['shade'] as String, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
                ],
              ),
            );
          }).toList(),
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