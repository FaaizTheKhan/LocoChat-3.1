import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_state.dart';
import '../services/discovery_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final DiscoveryService _discoveryService = DiscoveryService();

  @override
  void initState() {
    super.initState();

    // Setup the Radar Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Give the UI a frame to build, then start the hardware antenna
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<ChatState>(context, listen: false);
      _discoveryService.startMeshNode(state);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _discoveryService.stopMeshNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the ChatState reactive provider
    final chatState = Provider.of<ChatState>(context);
    final myId = chatState.localIdentity ?? "Generating...";
    final peers = chatState.discoveredPeers;

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
          // The Radar UI
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

          // The Reactive List of Discovered Devices
          Expanded(
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
                                icon: const Icon(Icons.call, color: Colors.greenAccent),
                                onPressed: () {
                                  // Trigger Audio Call logic here
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.videocam, color: Color(0xFF38BDF8)),
                                onPressed: () {
                                  // Trigger Video Call logic here
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
