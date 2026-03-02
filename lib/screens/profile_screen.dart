import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final AppState appState;
  const ProfileScreen({super.key, required this.appState});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _editName() async {
    final ctrl = TextEditingController(text: widget.appState.userName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(
        title: 'Your Name',
        controller: ctrl,
        hint: 'Enter your name',
        icon: Icons.person_rounded,
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      widget.appState.updateProfile(name: result.trim());
      setState(() {});
    }
  }

  void _addContact() async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (_) => _AddContactDialog(),
    );
    if (result != null) {
      widget.appState.addContact(result);
      setState(() {});
    }
  }

  void _setMode(DetectionMode mode) {
    widget.appState.setDetectionMode(mode);
    setState(() {});
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildProfileCard()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildDetectionModeSection()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildEmergencySection()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildAlertTimeoutCard()),
              SliverToBoxAdapter(child: const SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER
  Widget _buildHeader() {
    final isNormal = widget.appState.detectionMode == DetectionMode.normal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (isNormal ? AppTheme.accent : const Color(0xFF00EAAA))
                  .withOpacity(0.12),
              border: Border.all(
                  color: (isNormal ? AppTheme.accent : const Color(0xFF00EAAA))
                      .withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(widget.appState.modeIcon,
                    color: isNormal ? AppTheme.accent : const Color(0xFF00EAAA),
                    size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.appState.modeLabel,
                  style: TextStyle(
                    color: isNormal ? AppTheme.accent : const Color(0xFF00EAAA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PROFILE CARD
  Widget _buildProfileCard() {
    final initials = widget.appState.userName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join('');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppTheme.cardBg,
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A6DFF), Color(0xFF0830A0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.accent.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _editName,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.appState.userName,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_rounded,
                                color: AppTheme.accent, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.appState.emergencyContacts.isEmpty
                            ? 'No emergency contacts added'
                            : '${widget.appState.emergencyContacts.length} emergency contact${widget.appState.emergencyContacts.length > 1 ? 's' : ''} added',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 14),
            // Location toggle
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF00AAFF).withOpacity(0.12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFF00AAFF), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Share Location',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(
                        widget.appState.locationEnabled
                            ? widget.appState.currentLocation
                            : 'Included with emergency alerts',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.appState.locationEnabled,
                  onChanged: (_) {
                    widget.appState.toggleLocation();
                    setState(() {});
                  },
                  activeColor: AppTheme.accent,
                  activeTrackColor: AppTheme.accentDim,
                  inactiveThumbColor: AppTheme.textMuted,
                  inactiveTrackColor: AppTheme.border,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── DETECTION MODE
  Widget _buildDetectionModeSection() {
    final isNormal = widget.appState.detectionMode == DetectionMode.normal;
    final activeColor = isNormal ? AppTheme.accent : const Color(0xFF00EAAA);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('DETECTION MODE'),
          const SizedBox(height: 12),

          // Two mode buttons side by side
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                _ModeButton(
                  label: 'Normal',
                  icon: Icons.traffic_rounded,
                  subtitle: 'Roads & Traffic',
                  isSelected: isNormal,
                  color: AppTheme.accent,
                  onTap: () => _setMode(DetectionMode.normal),
                ),
                const SizedBox(width: 6),
                _ModeButton(
                  label: 'Indoor',
                  icon: Icons.home_rounded,
                  subtitle: 'Enclosed Spaces',
                  isSelected: !isNormal,
                  color: const Color(0xFF00EAAA),
                  onTap: () => _setMode(DetectionMode.indoor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          // Description strip
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: activeColor.withOpacity(0.07),
              border: Border.all(color: activeColor.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: activeColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.appState.modeDescription,
                    style: TextStyle(
                        color: activeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── EMERGENCY CONTACTS
  Widget _buildEmergencySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('EMERGENCY CONTACTS'),
              GestureDetector(
                onTap: _addContact,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppTheme.accent.withOpacity(0.12),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded,
                          color: AppTheme.accent, size: 16),
                      SizedBox(width: 4),
                      Text('Add',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.appState.emergencyContacts.isEmpty)
            _buildEmptyContacts()
          else ...[
            ...widget.appState.emergencyContacts
                .map((c) => _ContactCard(
                      contact: c,
                      onDelete: () {
                        widget.appState.removeContact(c.id);
                        setState(() {});
                      },
                    )),
            const SizedBox(height: 10),
            // Notification info strip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFF6B00).withOpacity(0.07),
                border: Border.all(
                    color: const Color(0xFFFF6B00).withOpacity(0.22)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: Color(0xFFFF6B00), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'They\'ll receive an SMS/notification if you don\'t dismiss an alert within ${widget.appState.alertDismissTimeout}s',
                      style: const TextStyle(
                          color: Color(0xFFFF6B00),
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyContacts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: AppTheme.surfaceElevated),
            child: const Icon(Icons.person_add_rounded,
                color: AppTheme.textMuted, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('No emergency contacts yet',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text(
            'Add people who will be alerted\nif you don\'t respond to a danger',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── ALERT TIMEOUT
  Widget _buildAlertTimeoutCard() {
    final options = [15, 30, 45, 60];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('AUTO-NOTIFY TIMEOUT'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notify emergency contacts if alert is not dismissed within:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: options.map((sec) {
                    final sel = widget.appState.alertDismissTimeout == sec;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          widget.appState.setAlertTimeout(sec);
                          setState(() {});
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: sel
                                ? AppTheme.accent.withOpacity(0.18)
                                : AppTheme.surfaceElevated,
                            border: Border.all(
                              color: sel ? AppTheme.accent : AppTheme.border,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '${sec}s',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: sel
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );
}

// ── MODE BUTTON ─────────────────────────────────────────────
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? color.withOpacity(0.14) : Colors.transparent,
            border: isSelected
                ? Border.all(color: color.withOpacity(0.45), width: 1.5)
                : null,
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 14)]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : AppTheme.surfaceElevated,
                ),
                child: Icon(icon,
                    color: isSelected ? color : AppTheme.textMuted, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          color: isSelected ? color : AppTheme.textSecondary,
                          fontSize: 14,
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
                Icon(Icons.check_circle_rounded, color: color, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CONTACT CARD ────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;

  const _ContactCard({required this.contact, required this.onDelete});

  static const _colors = [
    Color(0xFF1A6DFF),
    Color(0xFF00EAAA),
    Color(0xFFFF6B00),
    Color(0xFFFF2244),
    Color(0xFFFFBB00),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[contact.name.length % _colors.length];
    final initials = contact.name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join('');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(initials.isEmpty ? '?' : initials,
                  style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(contact.relation,
                        style: TextStyle(
                            color: color.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    const Text('  ·  ',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                    Flexible(
                      child: Text(contact.phone,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.alertSiren.withOpacity(0.1),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.alertSiren, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── EDIT NAME DIALOG ────────────────────────────────────────
class _EditDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _EditDialog(
      {required this.title,
      required this.controller,
      required this.hint,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit $title',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.accent, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.border)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppTheme.surfaceElevated,
                          border: Border.all(color: AppTheme.border)),
                      child: const Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, controller.text),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [
                          Color(0xFF1A6DFF),
                          Color(0xFF0830A0)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.accent.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                          child: Text('Save',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── ADD CONTACT DIALOG ──────────────────────────────────────
class _AddContactDialog extends StatefulWidget {
  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _relation = 'Family';
  final _relations = ['Family', 'Friend', 'Doctor', 'Caregiver', 'Other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Emergency Contact',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'They\'ll be notified if you don\'t dismiss a danger alert in time.',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4),
              ),
              const SizedBox(height: 20),
              _field(_nameCtrl, 'Full name', Icons.person_rounded),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone number', Icons.phone_rounded,
                  type: TextInputType.phone),
              const SizedBox(height: 14),
              const Text('RELATION',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relations.map((r) {
                  final sel = _relation == r;
                  return GestureDetector(
                    onTap: () => setState(() => _relation = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: sel
                            ? AppTheme.accent.withOpacity(0.15)
                            : AppTheme.surfaceElevated,
                        border: Border.all(
                            color:
                                sel ? AppTheme.accent : AppTheme.border,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Text(r,
                          style: TextStyle(
                            color: sel
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w500,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppTheme.surfaceElevated,
                            border: Border.all(color: AppTheme.border)),
                        child: const Center(
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_nameCtrl.text.trim().isEmpty ||
                            _phoneCtrl.text.trim().isEmpty) return;
                        Navigator.pop(
                          context,
                          EmergencyContact(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            relation: _relation,
                          ),
                        );
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: [
                            Color(0xFF1A6DFF),
                            Color(0xFF0830A0)
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.accent.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Center(
                            child: Text('Add Contact',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700))),
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

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.accent, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.border)),
      ),
    );
  }
}