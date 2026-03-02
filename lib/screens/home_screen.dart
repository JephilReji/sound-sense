import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mock_detection_service.dart';
import '../models/sound_event.dart';
import '../theme/app_theme.dart';
import 'alert_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MockDetectionService _service = MockDetectionService();
  StreamSubscription<SoundEvent>? _sub;

  late AnimationController _pulseCtrl;

  bool _isListening = false;
  double _currentDb = 0;
  final List<SoundEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _sub = _service.eventStream.listen(_onEvent);
  }

  void _onEvent(SoundEvent event) {
    if (!mounted) return;
    setState(() {
      _currentDb = event.decibels;
      _recentEvents.insert(0, event);
      if (_recentEvents.length > 5) _recentEvents.removeLast();
    });

    if (event.isDangerous) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AlertScreen(event: event),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  void _toggleListening() {
    if (_isListening) {
      // Show confirmation before stopping — safety-critical friction
      _showStopConfirmation();
    } else {
      setState(() => _isListening = true);
      _service.start();
    }
  }

  void _showStopConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.alertSiren.withOpacity(0.12),
                ),
                child: const Icon(Icons.pause_circle_outline_rounded,
                    color: AppTheme.alertSiren, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pause Detection?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'SoundSense is acting as your digital ears.\nPausing detection may put you at risk in traffic.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
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
                          child: Text(
                            'Keep Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _service.stop();
                        setState(() {
                          _isListening = false;
                          _currentDb = 0;
                        });
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppTheme.surfaceElevated,
                          border: Border.all(
                            color: AppTheme.alertSiren.withOpacity(0.5),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Pause',
                            style: TextStyle(
                              color: AppTheme.alertSiren,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
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

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const _AnimatedBg(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        _buildMainButton(),
                        const SizedBox(height: 24),
                        _buildDbMeter(),
                        const SizedBox(height: 24),
                        _buildModeSwitch(),
                        const SizedBox(height: 24),
                        _buildRecentDetections(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF1A6DFF), Color(0xFF0D3A8A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hearing_disabled_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'SoundSense',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.surfaceElevated,
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? const Color(0xFF00FF88)
                        : AppTheme.textMuted,
                    boxShadow: _isListening
                        ? [BoxShadow(
                            color: const Color(0xFF00FF88).withOpacity(0.7),
                            blurRadius: 6)]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isListening ? 'LIVE' : 'IDLE',
                  style: TextStyle(
                    color: _isListening
                        ? const Color(0xFF00FF88)
                        : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _isListening
            ? AppTheme.accent.withOpacity(0.1)
            : AppTheme.cardBg,
        border: Border.all(
          color: _isListening ? AppTheme.accent.withOpacity(0.4) : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? Color.lerp(AppTheme.accent, Colors.white, _pulseCtrl.value * 0.3)
                    : AppTheme.textMuted,
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.6 * _pulseCtrl.value),
                          blurRadius: 8 * _pulseCtrl.value,
                          spreadRadius: 2 * _pulseCtrl.value,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isListening ? 'LISTENING ACTIVE' : 'DETECTION PAUSED',
                style: TextStyle(
                  color: _isListening ? AppTheme.accent : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                _isListening
                    ? 'AI model scanning environment...'
                    : 'Tap the button to start detection',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isListening)
            _WaveformBars(isActive: _isListening),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) {
          final scale = _isListening
              ? 1.0 + 0.02 * _pulseCtrl.value
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring glow
            if (_isListening)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accent.withOpacity(0.2 + 0.15 * _pulseCtrl.value),
                      width: 1,
                    ),
                  ),
                ),
              ),
            if (_isListening)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accent.withOpacity(0.3 + 0.2 * _pulseCtrl.value),
                      width: 1,
                    ),
                  ),
                ),
              ),

            // Main button
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isListening
                      ? [const Color(0xFF1A6DFF), const Color(0xFF0830A0)]
                      : [AppTheme.surfaceElevated, AppTheme.cardBg],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isListening
                        ? AppTheme.accent.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4),
                    blurRadius: _isListening ? 40 : 20,
                    spreadRadius: _isListening ? 4 : 0,
                  ),
                ],
                border: Border.all(
                  color: _isListening ? AppTheme.accentGlow : AppTheme.border,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: _isListening ? Colors.white : AppTheme.textMuted,
                    size: 44,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isListening ? 'TAP TO\nSTOP' : 'TAP TO\nSTART',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isListening ? Colors.white : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.3,
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

  Widget _buildDbMeter() {
    final normalized = (_currentDb.clamp(40, 110) - 40) / 70;
    final meterColor = normalized > 0.8
        ? AppTheme.alertSiren
        : normalized > 0.6
            ? AppTheme.alertHorn
            : AppTheme.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SOUND LEVEL',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                _isListening ? '${_currentDb.toStringAsFixed(0)} dB' : '— dB',
                style: TextStyle(
                  color: meterColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: AppTheme.surfaceElevated,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.85 * (_isListening ? normalized : 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accent, meterColor],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: meterColor.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dbLabel('40', 'Quiet'),
              _dbLabel('70', 'Normal'),
              _dbLabel('90', 'Loud'),
              _dbLabel('110+', 'DANGER'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dbLabel(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  // Current detection mode — in a real app this would come from AppState
  bool _isNormalMode = true;

  void _showModeConfirmation(bool switchToNormal) {
    final newLabel = switchToNormal ? 'Normal Mode' : 'Indoor Mode';
    final newIcon  = switchToNormal ? Icons.traffic_rounded : Icons.home_rounded;
    final newColor = switchToNormal ? AppTheme.accent : const Color(0xFF00EAAA);
    final newDesc  = switchToNormal
        ? 'Optimised for open roads & traffic'
        : 'Optimised for enclosed spaces & buildings';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: newColor.withOpacity(0.12),
                ),
                child: Icon(newIcon, color: newColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Switch to $newLabel?',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                newDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Changing mode alters which sounds the AI monitors. Only switch if your environment has changed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppTheme.surfaceElevated,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Center(
                          child: Text('Cancel',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _isNormalMode = switchToNormal);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: newColor.withOpacity(0.15),
                          border: Border.all(
                            color: newColor.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Switch',
                            style: TextStyle(
                              color: newColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
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

  Widget _buildModeSwitch() {
    final activeColor = _isNormalMode ? AppTheme.accent : const Color(0xFF00EAAA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETECTION MODE',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.cardBg,
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              _ModePill(
                label: 'Normal',
                icon: Icons.traffic_rounded,
                subtitle: 'Roads & Traffic',
                isSelected: _isNormalMode,
                color: AppTheme.accent,
                onTap: () => _isNormalMode ? null : _showModeConfirmation(true),
              ),
              const SizedBox(width: 6),
              _ModePill(
                label: 'Indoor',
                icon: Icons.home_rounded,
                subtitle: 'Enclosed Spaces',
                isSelected: !_isNormalMode,
                color: const Color(0xFF00EAAA),
                onTap: () => _isNormalMode ? _showModeConfirmation(false) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: activeColor.withOpacity(0.07),
            border: Border.all(color: activeColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: activeColor, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isNormalMode
                      ? 'Optimised for open roads & traffic sounds'
                      : 'Optimised for enclosed spaces & buildings',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDetections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT DETECTIONS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            if (_recentEvents.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _recentEvents.clear()),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppTheme.accent, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Icon(Icons.graphic_eq_rounded, color: AppTheme.textMuted.withOpacity(0.4), size: 36),
                const SizedBox(height: 8),
                const Text(
                  'No detections yet',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...(_recentEvents.take(5).map((e) => _DetectionTile(event: e))),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  const _ModePill({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? color.withOpacity(0.14) : Colors.transparent,
            border: isSelected
                ? Border.all(color: color.withOpacity(0.45), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : AppTheme.surfaceElevated,
                ),
                child: Icon(icon,
                    color: isSelected ? color : AppTheme.textMuted, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          color: isSelected ? color : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? color.withOpacity(0.65)
                              : AppTheme.textMuted,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionTile extends StatelessWidget {
  final SoundEvent event;
  const _DetectionTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(event.timestamp);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.cardBg,
        border: Border.all(
          color: event.isDangerous
              ? event.alertColor.withOpacity(0.3)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: event.alertColor.withOpacity(0.15),
            ),
            child: Center(
              child: Text(event.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(event.confidence * 100).toStringAsFixed(0)}% confidence · ${event.decibels.toStringAsFixed(0)} dB',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: event.alertColor.withOpacity(0.2),
                ),
                child: Text(
                  event.urgencyLabel,
                  style: TextStyle(
                    color: event.alertColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _WaveformBars extends StatefulWidget {
  final bool isActive;
  const _WaveformBars({required this.isActive});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final h = 8.0 + 16.0 * sin((i + _ctrl.value) * pi / 2).abs();
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: AppTheme.accent,
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedBg extends StatefulWidget {
  const _AnimatedBg();

  @override
  State<_AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<_AnimatedBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _BgPainter(_ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle top gradient orb
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accent.withOpacity(0.07 + 0.03 * sin(t * 2 * pi)),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(size.width * 0.8, 80), radius: 200),
      );
    canvas.drawCircle(Offset(size.width * 0.8, 80), 200, paint);

    // Bottom orb
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF003080).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.8), radius: 180),
      );
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 180, paint2);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}