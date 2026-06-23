import 'dart:math';
import 'package:flutter/material.dart';

class ChatState extends ChangeNotifier {
  String? localIdentity;

  // Use a Set internally to prevent duplicate MACs/IDs from showing up
  final Set<String> _discoveredPeers = {};

  // Expose as a List for the UI to consume
  List<String> get discoveredPeers => _discoveredPeers.toList();

  // Generates a random 12-character hex string as a mock MAC address/ID
  void generateIdentity() {
    if (localIdentity == null) {
      const chars = 'ABCDEF0123456789';
      final random = Random();
      localIdentity = List.generate(12, (i) => chars[random.nextInt(chars.length)]).join();
      notifyListeners();
    }
  }

  // Adds a newly discovered peer to the radar
  void addPeer(String peerId) {
    if (_discoveredPeers.add(peerId)) {
      notifyListeners(); // Tells the UI to rebuild the list
    }
  }

  // Removes a peer if they go offline or out of range
  void removePeer(String peerId) {
    if (_discoveredPeers.remove(peerId)) {
      notifyListeners();
    }
  }

  // Clears all peers (useful when stopping the radar)
  void clearPeers() {
    _discoveredPeers.clear();
    notifyListeners();
  }
}
