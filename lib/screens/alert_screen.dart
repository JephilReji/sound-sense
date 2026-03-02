import 'package:flutter/material.dart';
import '../models/sound_event.dart';
import '../theme/app_theme.dart';

class AlertScreen extends StatefulWidget {
  final SoundEvent event;
  const AlertScreen({super.key, required this.event});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _strobeCtrl;
  late AnimationController _scaleCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _ringCtrl;

  late Animation<double> _strobe;
  late Animation<double> _scale;
  late Animation<Offset> _slide;
  late Animation<double> _ring;

  // FIX 1: Removed unused `bool _visible = true;`

  @override
  void initState() {
    super.initState();

    _strobeCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.event.isPanic ? 250 : 600),
    )..repeat(reverse: true);

    _strobe = Tween<double>(
      begin: widget.event.isPanic ? 0.3 : 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _strobeCtrl, curve: Curves.easeInOut));

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _ring = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    Future.delayed(Duration(seconds: widget.event.isPanic ? 10 : 6), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _strobeCtrl.dispose();
    _scaleCtrl.dispose();
    _slideCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  Color get _alertColor => widget.event.screenColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _strobe,
        builder: (_, child) {
          return Stack(
            children: [
              // Full screen strobe background
              Container(
                color: _alertColor.withOpacity(
                  widget.event.isPanic
                      ? _strobe.value * 0.85
                      : _strobe.value * 0.6,
                ),
              ),
              // Radial overlay
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      _alertColor.withOpacity(0.1),
                      AppTheme.background.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildUrgencyBadge(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.4),
                          border: Border.all(
                              color: _alertColor.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconWithRings(),
                    const SizedBox(height: 32),
                    ScaleTransition(
                      scale: _scale,
                      child: Column(
                        children: [
                          Text(
                            widget.event.label.toUpperCase(),
                            style: TextStyle(
                              color: _alertColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: _alertColor.withOpacity(0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.event.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SlideTransition(
                position: _slide,
                child: _buildInfoCard(),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(
                        color: _alertColor.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'DISMISS ALERT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge() {
    final label = widget.event.isPanic
        ? '⚠️ PANIC MODE'
        : widget.event.urgencyLevel == 2
            ? '🚨 HIGH ALERT'
            : '⚡ DANGER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: _alertColor.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: _alertColor.withOpacity(0.3), blurRadius: 12),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _alertColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildIconWithRings() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ring,
          builder: (_, __) => Container(
            width: 200 * _ring.value,
            height: 200 * _ring.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _alertColor.withOpacity(
                    0.15 * (1 - (_ring.value - 0.6) / 0.4)),
                width: 1,
              ),
            ),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: _alertColor.withOpacity(0.2), width: 1),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _alertColor.withOpacity(0.15),
            border: Border.all(color: _alertColor.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                  color: _alertColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5),
            ],
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: Text(widget.event.emoji,
                  style: const TextStyle(fontSize: 52)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      // FIX 3: Removed invalid `backdropFilter: null`
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: _alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _InfoChip(
            label: 'CONFIDENCE',
            value: '${(widget.event.confidence * 100).toStringAsFixed(0)}%',
            color: _alertColor,
          ),
          _dividerLine(),
          _InfoChip(
            label: 'SOUND LEVEL',
            value: '${widget.event.decibels.toStringAsFixed(0)} dB',
            color: _alertColor,
          ),
          _dividerLine(),
          _InfoChip(
            label: 'URGENCY',
            value: widget.event.urgencyLabel,
            color: _alertColor,
          ),
        ],
      ),
    );
  }

  Widget _dividerLine() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: _alertColor.withOpacity(0.2),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}