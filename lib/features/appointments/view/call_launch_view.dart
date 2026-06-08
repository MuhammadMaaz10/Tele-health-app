import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/features/appointments/controller/appointment_provider.dart';
import 'package:telehealth_app/features/appointments/controller/video_provider.dart';
import 'package:telehealth_app/features/appointments/model/appointment_model.dart';
import 'package:telehealth_app/features/appointments/model/appointment_note_model.dart';
import 'package:telehealth_app/features/appointments/model/call_media_mode.dart';
import 'package:telehealth_app/features/appointments/services/appointment_api.dart';
import 'package:telehealth_app/features/appointments/view/agora_call_view.dart';
import 'package:telehealth_app/features/profile/controller/profile_provider.dart';

/// Route shown after tapping “Start appointment call”: compact preview + join options.
class CallLaunchView extends StatelessWidget {
  const CallLaunchView({
    super.key,
    required this.appointment,
  });

  final Appointment appointment;

  static String _normEmail(String? e) => (e ?? '').trim().toLowerCase();

  static bool _roleIsStaff(String? userRole) {
    final r = userRole?.trim().toUpperCase() ?? '';
    return r == 'DOCTOR' || r == 'NURSE';
  }

  static String? _myEmail(AppointmentProvider ap) {
    final cached = ap.userEmail?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return Supabase.instance.client.auth.currentUser?.email?.trim();
  }

  static ({String name, String email, String roleLabel}) _otherParty(
    Appointment a,
    String? myEmail,
    String? userRole,
  ) {
    final me = _normEmail(myEmail);
    final doc = _normEmail(a.doctorAssigned);
    final pat = _normEmail(a.patientBooked);

    final imDoctor = me.isNotEmpty && me == doc;
    final imPatient = me.isNotEmpty && me == pat;

    if (imDoctor && !imPatient) {
      return (
        name: a.patientDisplayName,
        email: a.patientBooked.trim().isEmpty ? '—' : a.patientBooked.trim(),
        roleLabel: 'Patient',
      );
    }
    if (imPatient && !imDoctor) {
      return (
        name: a.doctorDisplayName,
        email: a.doctorAssigned.trim().isEmpty ? '—' : a.doctorAssigned.trim(),
        roleLabel: 'Doctor',
      );
    }

    if (_roleIsStaff(userRole)) {
      return (
        name: a.patientDisplayName,
        email: a.patientBooked.trim().isEmpty ? '—' : a.patientBooked.trim(),
        roleLabel: 'Patient',
      );
    }
    return (
      name: a.doctorDisplayName,
      email: a.doctorAssigned.trim().isEmpty ? '—' : a.doctorAssigned.trim(),
      roleLabel: 'Doctor',
    );
  }

  Future<void> _startCall(BuildContext context, CallMediaMode mode) async {
    final videoProvider = context.read<VideoProvider>();
    final ap = context.read<AppointmentProvider>();
    final party = _otherParty(appointment, _myEmail(ap), ap.userRole);

    final ok = await videoProvider.startVideo(appointment.id);
    if (!context.mounted) return;

    if (!ok || videoProvider.videoStartResponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(videoProvider.error ?? 'Could not start call.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final start = videoProvider.videoStartResponse!;

    void go() {
      Get.off(
        () => AgoraCallShell(
          videoProvider: videoProvider,
          appointment: appointment,
          startResponse: start,
          mediaMode: mode,
          otherPartyName: party.name,
          otherPartyEmail: party.email,
          otherPartyRoleLabel: party.roleLabel,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => go());
  }

  static String _displayNameForProfile(ProfileProvider p) {
    final u = p.user?.username?.trim();
    if (u != null && u.isNotEmpty) return u;
    final mail = p.userEmail?.trim();
    if (mail != null && mail.contains('@')) return mail.split('@').first;
    return 'You';
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();
    final videoProvider = context.watch<VideoProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final party = _otherParty(appointment, _myEmail(appointmentProvider), appointmentProvider.userRole);
    final theme = Theme.of(context);
    final locale = MaterialLocalizations.of(context);

    final dateLabel = locale.formatFullDate(appointment.startTime);
    final timeLabel = locale.formatTimeOfDay(TimeOfDay.fromDateTime(appointment.startTime));

    final myName = _displayNameForProfile(profileProvider);
    final myPic = profileProvider.user?.profilePicUrl;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Join call'),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textColor,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = math.min(constraints.maxWidth, 440.0);
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CurrentUserCard(displayName: myName, photoUrl: myPic),
                    const SizedBox(height: 18),
                    _AppointmentParticipantCard(
                      partyName: party.name,
                      partyEmail: party.email,
                      partyRoleLabel: party.roleLabel,
                      dateLabel: dateLabel,
                      timeLabel: timeLabel,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'How would you like to join?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _JoinMediaTile(
                      icon: Icons.graphic_eq_rounded,
                      title: 'Voice',
                      subtitle: 'Microphone only',
                      accent: const Color(0xFF0D9488),
                      enabled: !videoProvider.isLoading,
                      onTap: () => _startCall(context, CallMediaMode.audioOnly),
                    ),
                    const SizedBox(height: 10),
                    _JoinMediaTile(
                      icon: Icons.videocam_rounded,
                      title: 'Video',
                      subtitle: 'Camera and microphone',
                      accent: AppColors.primary,
                      enabled: !videoProvider.isLoading,
                      onTap: () => _startCall(context, CallMediaMode.audioVideo),
                    ),
                    if (videoProvider.isLoading) ...[
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Connecting…',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({
    required this.displayName,
    this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorderColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage:
                  photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentParticipantCard extends StatelessWidget {
  const _AppointmentParticipantCard({
    required this.partyName,
    required this.partyEmail,
    required this.partyRoleLabel,
    required this.dateLabel,
    required this.timeLabel,
  });

  final String partyName;
  final String partyEmail;
  final String partyRoleLabel;
  final String dateLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorderColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded, size: 20, color: AppColors.primary.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                'Appointment',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _metaRow(context, Icons.calendar_today_outlined, dateLabel),
          const SizedBox(height: 8),
          _metaRow(context, Icons.schedule_rounded, timeLabel),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.lightBorderColor.withValues(alpha: 0.85)),
          ),
          Text(
            'Joining with',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PartyAvatarLoader(
                email: partyEmail,
                name: partyName,
                diameter: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partyRoleLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.hintColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _PartyAvatarLoader extends StatefulWidget {
  const _PartyAvatarLoader({
    required this.email,
    required this.name,
    required this.diameter,
  });

  final String email;
  final String name;
  final double diameter;

  @override
  State<_PartyAvatarLoader> createState() => _PartyAvatarLoaderState();
}

class _PartyAvatarLoaderState extends State<_PartyAvatarLoader> {
  final _api = AppointmentApi();
  Future<String?>? _future;
  String? _loadedForEmail;

  void _resolveFuture() {
    final e = widget.email.trim();
    if (e.isEmpty || e == '—') {
      _future = Future.value(null);
      _loadedForEmail = e;
      return;
    }
    if (_loadedForEmail != e) {
      _loadedForEmail = e;
      _future = _api.fetchProfilePicUrlForEmail(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _resolveFuture();
  }

  @override
  void didUpdateWidget(covariant _PartyAvatarLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email) {
      _resolveFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
    final r = widget.diameter / 2;

    return SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: FutureBuilder<String?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: SizedBox(
                width: r,
                height: r,
                child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            );
          }
          final url = snapshot.data;
          if (url != null && url.isNotEmpty) {
            return CircleAvatar(
              radius: r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: NetworkImage(url),
            );
          }
          return CircleAvatar(
            radius: r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: r * 0.85,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JoinMediaTile extends StatelessWidget {
  const _JoinMediaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightBorderColor.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: enabled ? AppColors.textColor : AppColors.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accent.withValues(alpha: 0.65)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Own type so GetX uses a stable route name (not `ChangeNotifierProvider<VideoProvider>`).
class CallLaunchShell extends StatelessWidget {
  const CallLaunchShell({
    super.key,
    required this.videoProvider,
    required this.appointment,
  });

  final VideoProvider videoProvider;
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoProvider>.value(
      value: videoProvider,
      child: CallLaunchView(appointment: appointment),
    );
  }
}

class AgoraCallShell extends StatelessWidget {
  const AgoraCallShell({
    super.key,
    required this.videoProvider,
    required this.appointment,
    required this.startResponse,
    required this.mediaMode,
    required this.otherPartyName,
    required this.otherPartyEmail,
    required this.otherPartyRoleLabel,
  });

  final VideoProvider videoProvider;
  final Appointment appointment;
  final VideoStartResponse startResponse;
  final CallMediaMode mediaMode;
  final String otherPartyName;
  final String otherPartyEmail;
  final String otherPartyRoleLabel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoProvider>.value(
      value: videoProvider,
      child: AgoraCallView(
        appointment: appointment,
        startResponse: startResponse,
        mediaMode: mediaMode,
        otherPartyName: otherPartyName,
        otherPartyEmail: otherPartyEmail,
        otherPartyRoleLabel: otherPartyRoleLabel,
      ),
    );
  }
}
