import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/features/appointments/controller/video_provider.dart';
import 'package:telehealth_app/features/appointments/model/appointment_model.dart';
import 'package:telehealth_app/features/appointments/model/appointment_note_model.dart';
import 'package:telehealth_app/features/appointments/model/call_media_mode.dart';
import 'package:telehealth_app/features/appointments/services/agora_call_service.dart';
import 'package:telehealth_app/features/appointments/services/appointment_api.dart';

class AgoraCallView extends StatefulWidget {
  const AgoraCallView({
    super.key,
    required this.appointment,
    required this.startResponse,
    this.mediaMode = CallMediaMode.audioVideo,
    required this.otherPartyName,
    required this.otherPartyEmail,
    required this.otherPartyRoleLabel,
  });

  final Appointment appointment;
  final VideoStartResponse startResponse;
  final CallMediaMode mediaMode;
  final String otherPartyName;
  final String otherPartyEmail;
  final String otherPartyRoleLabel;

  @override
  State<AgoraCallView> createState() => _AgoraCallViewState();
}

class _AgoraCallViewState extends State<AgoraCallView> {
  final AgoraCallService _callService = AgoraCallService();
  final AppointmentApi _appointmentApi = AppointmentApi();

  VideoViewController? _localVideoCtrl;
  VideoViewController? _remoteVideoCtrl;
  int? _remoteVideoCtrlUid;

  String? _otherPartyAvatarUrl;

  bool _isMuted = false;
  bool _cameraOff = false;
  bool _speakerOn = true;
  bool _isJoining = true;
  Duration _remaining = Duration.zero;
  Timer? _timer;

  bool get _isVideoCall => widget.mediaMode == CallMediaMode.audioVideo;

  @override
  void initState() {
    super.initState();
    debugPrint('[AgoraCallView] initState appointmentId=${widget.appointment.id} mode=${widget.mediaMode}');
    _remaining = widget.appointment.endTime.difference(DateTime.now());
    _joinCall();
    _startRemainingTimer();
    _loadOtherPartyAvatar();
  }

  Future<void> _loadOtherPartyAvatar() async {
    final email = widget.otherPartyEmail.trim();
    if (email.isEmpty || email == '—') return;
    final url = await _appointmentApi.fetchProfilePicUrlForEmail(email);
    if (!mounted) return;
    setState(() => _otherPartyAvatarUrl = url);
  }

  @override
  void dispose() {
    debugPrint('[AgoraCallView] dispose appointmentId=${widget.appointment.id}');
    _timer?.cancel();
    _localVideoCtrl = null;
    _remoteVideoCtrl = null;
    _remoteVideoCtrlUid = null;
    _callService.leaveAndDispose();
    super.dispose();
  }

  Future<void> _joinCall() async {
    debugPrint('[AgoraCallView] _joinCall start room=${widget.startResponse.roomName}');
    try {
      _callService.peerWaitingDisplayName = widget.otherPartyName;
      await _callService.initialize(
        appId: widget.startResponse.appId,
        channelName: widget.startResponse.roomName,
        token: widget.startResponse.accessToken,
        uid: widget.startResponse.uid,
        publishVideo: _isVideoCall,
        onTokenRefresh: _refreshToken,
      );
      debugPrint('[AgoraCallView] _joinCall initialize success');
    } catch (e) {
      debugPrint('[AgoraCallView] _joinCall error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        Get.back();
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<String> _refreshToken() async {
    final refreshed = await _appointmentApi.refreshVideoToken(
      appointmentId: widget.appointment.id,
    );
    return refreshed.accessToken;
  }

  void _startRemainingTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = widget.appointment.endTime.difference(DateTime.now());
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        _handleEndCall();
      } else if (mounted) {
        setState(() => _remaining = remaining);
      }
    });
  }

  Future<void> _handleEndCall() async {
    debugPrint('[AgoraCallView] _handleEndCall called');
    await _callService.leaveAndDispose();
    if (!mounted) return;
    await context.read<VideoProvider>().endVideo(widget.appointment.id);
    if (mounted) Get.back();
  }

  Color _bannerTint(String headline) {
    if (headline.startsWith('Reconnecting')) return Colors.deepPurple.shade700;
    if (headline.startsWith('Connecting')) return Colors.blue.shade700;
    if (headline.startsWith('Waiting')) return Colors.deepOrange.shade800;
    if (headline.contains('active')) return Colors.green.shade800;
    return Colors.blueGrey.shade800;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _isVideoCall
        ? 'Video appointment · Room ${widget.startResponse.roomName}'
        : 'Voice appointment · Room ${widget.startResponse.roomName}';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isVideoCall ? 'Video call' : 'Voice call'),
            Text(
              'Time left ${_formatRemaining(_remaining)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ValueListenableBuilder<String>(
              valueListenable: _callService.headlineStatus,
              builder: (context, headline, _) {
                return Material(
                  color: _bannerTint(headline),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              headline,
                              key: ValueKey<String>(headline),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _buildOtherPartyAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherPartyRoleLabel,
                        style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 0.5),
                      ),
                      Text(
                        widget.otherPartyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.otherPartyEmail,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: _callService.errorMessage,
            builder: (context, value, child) {
              if (value == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Material(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          ),
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ValueListenableBuilder<int?>(
                valueListenable: _callService.remoteUid,
                builder: (context, rUid, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _callService.connectionStateLabel,
                    builder: (context, state, _) {
                      return Text(
                        'Debug · Channel ${widget.startResponse.roomName} · Me ${widget.startResponse.uid} · Remote ${rUid ?? '—'} · $state',
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: ClipRect(
              child: _isVideoCall ? _buildVideoMainStage() : _buildAudioMainStage(),
            ),
          ),
          _buildControlsFooter(context),
        ],
      ),
    );
  }

  Widget _buildAudioMainStage() {
    return ValueListenableBuilder<int?>(
      valueListenable: _callService.remoteUid,
      builder: (context, remoteUid, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _callService.localJoined,
          builder: (context, localJoined, _) {
            if (_isJoining) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!localJoined || _callService.engine == null) {
              return const Center(
                child: Text(
                  'Connecting to secure room…',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            final joinedPeer = remoteUid != null;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      joinedPeer ? Icons.phone_in_talk_rounded : Icons.mic_none_rounded,
                      size: 72,
                      color: joinedPeer ? Colors.greenAccent : Colors.white54,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      joinedPeer ? 'Connected' : 'You’re in the room',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      joinedPeer
                          ? 'You’re on an audio call with ${widget.otherPartyName}.'
                          : 'Waiting for ${widget.otherPartyName} to join…',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoMainStage() {
    return ValueListenableBuilder<int?>(
      valueListenable: _callService.remoteUid,
      builder: (context, remoteUid, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _callService.localJoined,
          builder: (context, localJoined, _) {
            if (_isJoining) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!localJoined || _callService.engine == null) {
              return const Center(
                child: Text('Connecting to secure room…', style: TextStyle(color: Colors.white70)),
              );
            }

            final uid = remoteUid;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (uid != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black,
                      child: SizedBox.expand(
                        child: ClipRect(
                          child: AgoraVideoView(
                            key: ValueKey<String>('remote-$uid'),
                            controller: _remoteVideoController(uid),
                            onAgoraVideoViewCreated: kIsWeb
                                ? (_) {
                                    unawaited(_callService.applyWebRemoteRenderFit(uid));
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: uid == null ? 0 : null,
                  top: uid == null ? 0 : 24,
                  right: uid == null ? 0 : 16,
                  bottom: uid == null ? 0 : null,
                  width: uid == null ? null : 120,
                  height: uid == null ? null : 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(uid == null ? 0 : 12),
                    child: ColoredBox(
                      color: Colors.black,
                      child: AgoraVideoView(
                        key: const ValueKey<String>('local-camera'),
                        controller: _localVideoController(),
                        onAgoraVideoViewCreated: (_) {
                          final eng = _callService.engine;
                          if (eng != null) eng.startPreview();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlsFooter(BuildContext context) {
    final bottom = 12 + MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chips = <Widget>[
            _circleButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              onTap: () async {
                final next = !_isMuted;
                await _callService.toggleMute(next);
                setState(() => _isMuted = next);
              },
            ),
            if (_isVideoCall) ...[
              const SizedBox(width: 10),
              _circleButton(
                icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                onTap: () async {
                  final next = !_cameraOff;
                  await _callService.toggleCamera(next);
                  setState(() => _cameraOff = next);
                },
              ),
              const SizedBox(width: 10),
              _circleButton(icon: Icons.cameraswitch, onTap: () => _callService.switchCamera()),
            ],
            const SizedBox(width: 10),
            _circleButton(
              icon: _speakerOn ? Icons.volume_up : Icons.hearing,
              onTap: () async {
                final next = !_speakerOn;
                await _callService.setSpeakerphone(next);
                setState(() => _speakerOn = next);
              },
            ),
            const SizedBox(width: 14),
            _circleButton(
              icon: Icons.call_end,
              color: Colors.red.shade700,
              diameter: 64,
              onTap: _handleEndCall,
            ),
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth - 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: chips,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D2D2D),
    double diameter = 52,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(diameter),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: diameter > 56 ? 28 : 24),
      ),
    );
  }

  String _formatRemaining(Duration remaining) {
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _videoUseFlutterTexture =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  bool get _videoUseAndroidSurfaceView => false;

  Widget _buildOtherPartyAvatar() {
    final url = _otherPartyAvatarUrl;
    final initial =
        widget.otherPartyName.isNotEmpty ? widget.otherPartyName[0].toUpperCase() : '?';
    const size = 44.0;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.white12,
        alignment: Alignment.center,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            : Text(
                initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  VideoViewController _localVideoController() {
    final engine = _callService.engine!;
    return _localVideoCtrl ??= VideoViewController(
      rtcEngine: engine,
      canvas: const VideoCanvas(
        uid: 0,
        renderMode: RenderModeType.renderModeHidden,
      ),
      useFlutterTexture: _videoUseFlutterTexture,
      useAndroidSurfaceView: _videoUseAndroidSurfaceView,
    );
  }

  VideoViewController _remoteVideoController(int uid) {
    final engine = _callService.engine!;
    if (_remoteVideoCtrlUid != uid) {
      _remoteVideoCtrl = VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(
          uid: uid,
          renderMode: RenderModeType.renderModeFit,
        ),
        connection: RtcConnection(channelId: widget.startResponse.roomName),
        useFlutterTexture: _videoUseFlutterTexture,
        useAndroidSurfaceView: _videoUseAndroidSurfaceView,
      );
      _remoteVideoCtrlUid = uid;
    }
    return _remoteVideoCtrl!;
  }
}
