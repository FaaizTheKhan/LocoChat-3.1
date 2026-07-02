import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'offline_call_service.dart';

class WebRTCEngine {
  final OfflineCallService _signalingService;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _currentPeerId;

  bool isAudioMuted = false;
  bool isVideoMuted = false;

  Function()? onStateChange;

  WebRTCEngine(this._signalingService) {
    // handled in router
  }

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> dispose() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }

  Future<void> startLocalMedia({bool video = true, bool audio = true}) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': audio,
      'video': video ? {
        'mandatory': {
          'minWidth': '640', // Optimized for offline encoding
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      } : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
      onStateChange?.call();
    } catch (e) {
      debugPrint("Error starting local media: $e");
    }
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      "iceServers": [] // No ICE servers needed for local P2P
    };

    final Map<String, dynamic> constraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _peerConnection = await createPeerConnection(configuration, constraints);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_currentPeerId != null) {
        _signalingService.sendSignalingMessage(_currentPeerId!, {
          'type': 'candidate',
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        onStateChange?.call();
      }
    };

    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  Future<void> startCall(String peerId) async {
    _currentPeerId = peerId;
    await _createPeerConnection();

    final RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _signalingService.sendSignalingMessage(peerId, {
      'type': 'offer',
      'sdp': offer.toMap(),
    });
  }

  Future<void> endCall() async {
    if (_currentPeerId != null) {
      _signalingService.sendSignalingMessage(_currentPeerId!, {
        'type': 'bye'
      });
    }
    await _peerConnection?.close();
    _peerConnection = null;
    remoteRenderer.srcObject = null;
    _currentPeerId = null;
    onStateChange?.call();
  }

  void handleSignalingMessage(String peerId, Map<String, dynamic> data) async {
    final type = data['type'];
    _currentPeerId = peerId;

    if (type == 'offer') {
      // Incoming call: start local media automatically to participate
      await startLocalMedia(video: true, audio: true);
      await _createPeerConnection();
      final sdpData = data['sdp'];
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );

      final RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _signalingService.sendSignalingMessage(peerId, {
        'type': 'answer',
        'sdp': answer.toMap(),
      });
    } else if (type == 'answer') {
      final sdpData = data['sdp'];
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpData['sdp'], sdpData['type']),
      );
    } else if (type == 'candidate') {
      final candidateData = data['candidate'];
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        ),
      );
    } else if (type == 'bye') {
       await _peerConnection?.close();
       _peerConnection = null;
       remoteRenderer.srcObject = null;
       _currentPeerId = null;
       onStateChange?.call();
    }
  }

  void toggleAudio() {
    if (_localStream != null) {
      isAudioMuted = !isAudioMuted;
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !isAudioMuted;
      });
      onStateChange?.call();
    }
  }

  void toggleVideo() {
    if (_localStream != null) {
      isVideoMuted = !isVideoMuted;
      _localStream!.getVideoTracks().forEach((track) {
        track.enabled = !isVideoMuted;
      });
      onStateChange?.call();
    }
  }
}
