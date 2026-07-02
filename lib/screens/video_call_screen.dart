import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_engine.dart';

class VideoCallScreen extends StatefulWidget {
  final String peerId;
  final WebRTCEngine webrtcEngine;
  final VoidCallback onEndCall;

  const VideoCallScreen({
    super.key,
    required this.peerId,
    required this.webrtcEngine,
    required this.onEndCall,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Offset _pipPosition = const Offset(20, 40);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (Fullscreen)
          Positioned.fill(
            child: widget.webrtcEngine.remoteRenderer.srcObject != null
                ? RTCVideoView(
                    widget.webrtcEngine.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF38BDF8)),
                        SizedBox(height: 16),
                        Text("Connecting to peer...", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
          ),

          // Local Video (Draggable PiP)
          if (widget.webrtcEngine.localRenderer.srcObject != null)
            Positioned(
              left: _pipPosition.dx,
              top: _pipPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pipPosition += details.delta;
                    // Clamp to screen bounds roughly
                    _pipPosition = Offset(
                      _pipPosition.dx.clamp(0, MediaQuery.of(context).size.width - 100),
                      _pipPosition.dy.clamp(0, MediaQuery.of(context).size.height - 150),
                    );
                  });
                },
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      widget.webrtcEngine.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
            ),

          // Call Controls Header
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Call with ${widget.peerId}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),

          // Call Controls Bottom Bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: widget.webrtcEngine.isAudioMuted ? Icons.mic_off : Icons.mic,
                  color: widget.webrtcEngine.isAudioMuted ? Colors.redAccent : Colors.white24,
                  onPressed: () {
                    setState(() {
                      widget.webrtcEngine.toggleAudio();
                    });
                  },
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: Colors.redAccent,
                  iconSize: 32,
                  padding: 20,
                  onPressed: widget.onEndCall,
                ),
                _buildControlButton(
                  icon: widget.webrtcEngine.isVideoMuted ? Icons.videocam_off : Icons.videocam,
                  color: widget.webrtcEngine.isVideoMuted ? Colors.redAccent : Colors.white24,
                  onPressed: () {
                    setState(() {
                      widget.webrtcEngine.toggleVideo();
                    });
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double iconSize = 24,
    double padding = 12,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        padding: EdgeInsets.all(padding),
        onPressed: onPressed,
      ),
    );
  }
}
