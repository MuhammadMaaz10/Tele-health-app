import 'dart:async';



import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:flutter/foundation.dart';

import 'package:permission_handler/permission_handler.dart';



class AgoraCallService {

  AgoraCallService();



  RtcEngine? _engine;

  ConnectionStateType? _lastConnectionState;



  final ValueNotifier<int?> remoteUid = ValueNotifier<int?>(null);

  final ValueNotifier<bool> localJoined = ValueNotifier<bool>(false);

  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  final ValueNotifier<String> connectionStateLabel = ValueNotifier<String>('disconnected');



  /// Short heading for the call banner (Connecting… / Reconnecting… / Waiting… / Connected).

  final ValueNotifier<String> headlineStatus = ValueNotifier<String>('Connecting…');



  /// Display name used in “Waiting for …” (other participant).

  String peerWaitingDisplayName = 'participant';



  RtcEngine? get engine => _engine;



  bool _publishVideo = true;



  void _refreshHeadline() {

    final joined = localJoined.value;

    final remote = remoteUid.value;

    final st = _lastConnectionState;



    if (!joined) {

      final reconnect =

          st == ConnectionStateType.connectionStateReconnecting ||

              '$st'.contains('Reconnecting');

      headlineStatus.value = reconnect ? 'Reconnecting…' : 'Connecting…';

      return;

    }



    if (st == ConnectionStateType.connectionStateReconnecting ||

        '$st'.contains('Reconnecting')) {

      headlineStatus.value = 'Reconnecting…';

      return;

    }



    if (remote == null) {

      headlineStatus.value = 'Waiting for $peerWaitingDisplayName…';

      return;

    }



    headlineStatus.value = _publishVideo ? 'Video call active' : 'Voice call active';

  }



  Future<void> initialize({

    required String appId,

    required String channelName,

    required String token,

    required int uid,

    required Future<String> Function() onTokenRefresh,

    required bool publishVideo,

  }) async {

    debugPrint('[AgoraCallService] initialize called (channel=$channelName, uid=$uid, publishVideo=$publishVideo)');

    _publishVideo = publishVideo;

    peerWaitingDisplayName = peerWaitingDisplayName.trim().isEmpty ? 'participant' : peerWaitingDisplayName;



    await _ensurePermissions(publishVideo);



    final engine = createAgoraRtcEngine();

    await engine.initialize(RtcEngineContext(appId: appId));



    await engine.enableAudio();

    if (publishVideo) {

      await engine.enableVideo();

    } else {

      await engine.disableVideo();

    }



    await engine.setChannelProfile(ChannelProfileType.channelProfileCommunication);

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);



    if (publishVideo) {

      await engine.startPreview();

    }



    _engine = engine;

    headlineStatus.value = 'Connecting…';



    engine.registerEventHandler(

      RtcEngineEventHandler(

        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {

          debugPrint('[AgoraCallService] onJoinChannelSuccess (channel=${connection.channelId}, elapsed=$elapsed)');

          localJoined.value = true;

          connectionStateLabel.value = 'connected';

          _refreshHeadline();

        },

        onUserJoined: (RtcConnection connection, int remoteUserId, int elapsed) {

          debugPrint('[AgoraCallService] onUserJoined (remoteUid=$remoteUserId, elapsed=$elapsed)');

          remoteUid.value = remoteUserId;

          _refreshHeadline();

        },

        onFirstRemoteVideoDecoded:
            (RtcConnection connection, int remoteDecodedUid, int width, int height, int elapsed) {

          debugPrint(
            '[AgoraCallService] onFirstRemoteVideoDecoded uid=$remoteDecodedUid ${width}x$height',
          );

          unawaited(applyWebRemoteRenderFit(remoteDecodedUid));

        },

        onVideoSizeChanged:
            (RtcConnection connection, VideoSourceType sourceType, int sizedUid, int width,
                int height, int rotation) {

          if (!kIsWeb || !_publishVideo) return;

          if (sizedUid == 0 || sourceType != VideoSourceType.videoSourceRemote) return;

          unawaited(applyWebRemoteRenderFit(sizedUid));

        },

        onUserOffline: (RtcConnection connection, int remoteUserId, UserOfflineReasonType reason) {

          debugPrint('[AgoraCallService] onUserOffline (remoteUid=$remoteUserId, reason=$reason)');

          if (remoteUid.value == remoteUserId) {

            remoteUid.value = null;

          }

          _refreshHeadline();

        },

        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) async {

          debugPrint('[AgoraCallService] onTokenPrivilegeWillExpire triggered');

          try {

            final renewedToken = await onTokenRefresh();

            debugPrint('[AgoraCallService] token refreshed; renewing Agora token');

            await engine.renewToken(renewedToken);

          } catch (e) {

            debugPrint('[AgoraCallService] token refresh failed: $e');

            errorMessage.value = 'Call token refresh failed. Rejoin the call.';

          }

        },

        onError: (ErrorCodeType err, String msg) {

          debugPrint('[AgoraCallService] onError err=$err msg=$msg');

          errorMessage.value = 'Agora error: $msg';

        },

        onConnectionStateChanged: (

          RtcConnection connection,

          ConnectionStateType state,

          ConnectionChangedReasonType reason,

        ) {

          debugPrint('[AgoraCallService] onConnectionStateChanged state=$state reason=$reason');

          _lastConnectionState = state;

          connectionStateLabel.value = '$state';

          _refreshHeadline();

        },

      ),

    );



    await engine.joinChannel(

      token: token,

      channelId: channelName,

      uid: uid,

      options: ChannelMediaOptions(

        publishCameraTrack: publishVideo,

        publishMicrophoneTrack: true,

        autoSubscribeAudio: true,

        autoSubscribeVideo: publishVideo,

      ),

    );



    debugPrint('[AgoraCallService] joinChannel requested');

    _refreshHeadline();

  }



  Future<void> toggleMute(bool mute) async {

    debugPrint('[AgoraCallService] toggleMute mute=$mute');

    await _engine?.muteLocalAudioStream(mute);

  }



  Future<void> toggleCamera(bool disable) async {

    debugPrint('[AgoraCallService] toggleCamera disable=$disable');

    await _engine?.muteLocalVideoStream(disable);

  }



  Future<void> switchCamera() async {

    debugPrint('[AgoraCallService] switchCamera called');

    await _engine?.switchCamera();

  }



  Future<void> setSpeakerphone(bool enable) async {

    debugPrint('[AgoraCallService] setSpeakerphone enable=$enable');

    await _engine?.setEnableSpeakerphone(enable);

  }



  Future<void> leaveAndDispose() async {

    debugPrint('[AgoraCallService] leaveAndDispose called');

    try {

      await _engine?.leaveChannel();

    } finally {

      await _engine?.release();

      _engine = null;

      localJoined.value = false;

      remoteUid.value = null;

      connectionStateLabel.value = 'disconnected';

      _lastConnectionState = null;

      headlineStatus.value = 'Connecting…';

    }

  }



  /// Web Iris/SDK often ignores [VideoCanvas.renderMode]; force Fit after frames decode.

  Future<void> applyWebRemoteRenderFit(int remoteUserId) async {

    if (!kIsWeb || !_publishVideo) return;

    final eng = _engine;

    if (eng == null) return;

    try {

      debugPrint('[AgoraCallService] applyWebRemoteRenderFit uid=$remoteUserId');

      await eng.setRemoteRenderMode(

        uid: remoteUserId,

        renderMode: RenderModeType.renderModeFit,

        mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled,

      );

      await Future<void>.delayed(const Duration(milliseconds: 280));

      await eng.setRemoteRenderMode(

        uid: remoteUserId,

        renderMode: RenderModeType.renderModeFit,

        mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled,

      );

    } catch (e) {

      debugPrint('[AgoraCallService] applyWebRemoteRenderFit failed: $e');

    }

  }



  Future<void> _ensurePermissions(bool needsCamera) async {

    if (kIsWeb) {

      debugPrint('[AgoraCallService] _ensurePermissions skipped on web');

      return;

    }

    final mic = await Permission.microphone.request();

    PermissionStatus? cam;

    if (needsCamera) {

      cam = await Permission.camera.request();

    }

    final micGranted = mic.isGranted;

    final camGranted = needsCamera ? (cam?.isGranted ?? false) : true;

    debugPrint('[AgoraCallService] permissions mic=$micGranted cam=$camGranted (needsCamera=$needsCamera)');

    if (!micGranted || !camGranted) {

      throw Exception(

        needsCamera

            ? 'Camera and microphone permissions are required.'

            : 'Microphone permission is required for voice calls.',

      );

    }

  }

}


