import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locochat_provider.dart';
import '../services/offline_call_service.dart';
import '../services/webrtc_engine.dart';
import 'permissions_screen.dart';
import 'home_radar_screen.dart';
import 'chat_bottom_sheet.dart';
import 'video_call_screen.dart';

class LocoChatScreen extends StatefulWidget {
  const LocoChatScreen({super.key});

  @override
  State<LocoChatScreen> createState() => _LocoChatScreenState();
}

class _LocoChatScreenState extends State<LocoChatScreen> {
  bool _permissionsGranted = false;
  late OfflineCallService _offlineCallService;
  late WebRTCEngine _webrtcEngine;

  bool _inCall = false;
  String? _callPeerId;

  @override
  void initState() {
    super.initState();
    _offlineCallService = OfflineCallService();
    _webrtcEngine = WebRTCEngine(_offlineCallService);

    _webrtcEngine.onStateChange = () {
      if (mounted) setState(() {});
    };

    // Listen for incoming call events from signaling layer
    _offlineCallService.onSignalingMessage = (peerId, data) {
      if (data['type'] == 'offer' && !_inCall) {
         setState(() {
           _inCall = true;
           _callPeerId = peerId;
         });
      }
      // Re-route to WebRTC engine
      _webrtcEngine.handleSignalingMessage(peerId, data);
    };
  }

  @override
  void dispose() {
    _offlineCallService.stopMeshNode();
    _webrtcEngine.dispose();
    super.dispose();
  }

  void _onPermissionsGranted() {
    setState(() {
      _permissionsGranted = true;
    });

    final state = Provider.of<LocoChatProvider>(context, listen: false);
    _offlineCallService.startMeshNode(state);

    // Wire up text message handler
    _offlineCallService.onTextMessage = (peerId, message) {
       // Handled by state in service, but we can notify if needed
       // Or show a snackbar
    };
  }

  void _startAudioCall(String peerId) async {
    await _webrtcEngine.initialize();
    await _webrtcEngine.startLocalMedia(video: false, audio: true);
    await _webrtcEngine.startCall(peerId);
    setState(() {
      _inCall = true;
      _callPeerId = peerId;
    });
  }

  void _startVideoCall(String peerId) async {
    await _webrtcEngine.initialize();
    await _webrtcEngine.startLocalMedia(video: true, audio: true);
    await _webrtcEngine.startCall(peerId);
    setState(() {
      _inCall = true;
      _callPeerId = peerId;
    });
  }

  void _endCall() async {
     await _webrtcEngine.endCall();
     setState(() {
       _inCall = false;
       _callPeerId = null;
     });
  }

  void _openChat(String peerId) {
    final state = Provider.of<LocoChatProvider>(context, listen: false);
    state.setBottomSheetVisible(true, peerId: peerId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      return PermissionsScreen(onPermissionsGranted: _onPermissionsGranted);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main Router Body
          HomeRadarScreen(
            onStartAudioCall: _startAudioCall,
            onStartVideoCall: _startVideoCall,
            onOpenChat: _openChat,
          ),

          // Chat Bottom Sheet Overlay
          Consumer<LocoChatProvider>(
            builder: (context, state, child) {
              if (state.isBottomSheetVisible && state.activeChatPeer != null) {
                return ChatBottomSheet(
                  peerId: state.activeChatPeer!,
                  onClose: () => state.setBottomSheetVisible(false),
                  onSendMessage: (msg) {
                    _offlineCallService.sendTextMessage(state.activeChatPeer!, msg);
                    state.addMessage(state.activeChatPeer!, "Me: $msg");
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Video Call Overlay
          if (_inCall && _callPeerId != null)
             VideoCallScreen(
               peerId: _callPeerId!,
               webrtcEngine: _webrtcEngine,
               onEndCall: _endCall,
             )
        ],
      ),
    );
  }
}
