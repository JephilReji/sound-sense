import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sound_event.dart';
import '../models/mock_detection_service.dart';
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

  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;

  bool _isListening = false;
  double _currentDb = 0;
  SoundEvent? _lastEvent;
  final List<SoundEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _sub = _service.eventStream.listen(_onEvent);
  }

  void _onEvent(SoundEvent event) {
    if (!mounted) return;
    setState(() {
      _lastEvent = event;
      _currentDb = event.decibels;
      _recentEvents.insert(0, event);
      if (_recentEvents.length > 5) _recentEvents.removeLast();
    });

    if (event.isDangerous) {
      _waveCtrl.forward(from: 0);
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
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      _service.start();
    } else {
      _service.stop();
      setState(() {
        _currentDb = 0;
        _lastEvent = null;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    _waveCtrl.dispose();
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
                        _buildSoundClasses(),
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

  Widget _buildSoundClasses() {
    final classes = [
      {'sc': SoundClass.horn, 'emoji': '📯', 'label': 'Horn'},
      {'sc': SoundClass.siren, 'emoji': '🚨', 'label': 'Siren'},
      {'sc': SoundClass.engine, 'emoji': '⚙️', 'label': 'Engine'},
      {'sc': SoundClass.heavyVehicle, 'emoji': '🚛', 'label': 'Heavy'},
      {'sc': SoundClass.background, 'emoji': '🔈', 'label': 'BG Noise'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOUND CLASSES',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: classes.map((c) {
            final sc = c['sc'] as SoundClass;
            final emoji = c['emoji'] as String;
            final label = c['label'] as String;
            final isActive = _lastEvent?.soundClass == sc;
            return Expanded(
              child: GestureDetector(
                onTap: _isListening
                    ? () => _service.triggerManual(sc)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isActive
                        ? _getClassColor(sc).withOpacity(0.2)
                        : AppTheme.cardBg,
                    border: Border.all(
                      color: isActive
                          ? _getClassColor(sc)
                          : AppTheme.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: isActive
                              ? _getClassColor(sc)
                              : AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap any class to simulate detection',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getClassColor(SoundClass sc) {
    switch (sc) {
      case SoundClass.horn: return AppTheme.alertHorn;
      case SoundClass.siren: return AppTheme.alertSiren;
      case SoundClass.engine: return AppTheme.alertEngine;
      case SoundClass.heavyVehicle: return AppTheme.alertHeavy;
      case SoundClass.background: return AppTheme.alertBackground;
    }
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