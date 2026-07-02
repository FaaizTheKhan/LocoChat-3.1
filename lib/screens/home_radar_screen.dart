import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locochat_provider.dart';

class HomeRadarScreen extends StatefulWidget {
  final Function(String) onStartAudioCall;
  final Function(String) onStartVideoCall;
  final Function(String) onOpenChat;

  const HomeRadarScreen({
    super.key,
    required this.onStartAudioCall,
    required this.onStartVideoCall,
    required this.onOpenChat,
  });

  @override
  State<HomeRadarScreen> createState() => _HomeRadarScreenState();
}

class _HomeRadarScreenState extends State<HomeRadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LocoChatProvider>(context);
    final myId = state.localIdentity ?? "Generating...";
    final peers = state.discoveredPeers;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LocoChat Radar", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("My MAC ID: $myId", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Radar UI
          Container(
            height: 250,
            width: double.infinity,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 200 * _pulseAnimation.value,
                      height: 200 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38BDF8).withValues(alpha: 1.0 - _pulseAnimation.value),
                      ),
                    );
                  },
                ),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF1E293B),
                  child: Icon(Icons.radar, size: 40, color: Color(0xFF38BDF8)),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Nearby Peers",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          // Reactive List of Discovered Devices
          Expanded(
            flex: 2,
            child: peers.isEmpty
                ? Center(
                    child: Text("Scanning for nearby devices...", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                  )
                : ListView.builder(
                    itemCount: peers.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      String peerId = peers[index];
                      return Card(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF818CF8).withValues(alpha: 0.2),
                            child: const Icon(Icons.person, color: Color(0xFF818CF8)),
                          ),
                          title: Text(peerId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text("Ready to connect", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.message, color: Color(0xFF818CF8)),
                                onPressed: () => widget.onOpenChat(peerId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call, color: Colors.greenAccent),
                                onPressed: () => widget.onStartAudioCall(peerId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.videocam, color: Color(0xFF38BDF8)),
                                onPressed: () => widget.onStartVideoCall(peerId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Local Diagnostic Terminal
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Terminal Logs", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final logs = state.telemetryLogs.reversed.toList();
                        return ListView.builder(
                          reverse: true,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                             return Text("> ${logs[index]}", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'));
                          },
                        );
                      }
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
