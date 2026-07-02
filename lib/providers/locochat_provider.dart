import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class LocoChatProvider extends ChangeNotifier {
  String? localIdentity;

  // State Management properties
  bool _isBottomSheetVisible = false;
  bool get isBottomSheetVisible => _isBottomSheetVisible;

  String? _activeChatPeer;
  String? get activeChatPeer => _activeChatPeer;

  // Telemetry logs
  final List<String> _telemetryLogs = [];
  List<String> get telemetryLogs => _telemetryLogs;

  // Use a Set internally to prevent duplicate MACs/IDs from showing up
  final Set<String> _discoveredPeers = {};

  // Expose as a List for the UI to consume
  List<String> get discoveredPeers => _discoveredPeers.toList();

  // Chat history state: map of peer ID to list of messages
  final Map<String, List<String>> _chatHistory = {};

  // Hashed ID generator
  Future<void> generateIdentity() async {
    if (localIdentity == null) {
      final deviceInfo = DeviceInfoPlugin();
      String hardwareId = "UNKNOWN";

      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          hardwareId = androidInfo.id;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          hardwareId = iosInfo.identifierForVendor ?? "UNKNOWN_IOS";
        }
      } catch (e) {
        debugPrint("Could not get hardware info: $e");
      }

      // Synthesize a permanent 12-digit MAC address representation by running a SHA-256 hash
      final bytes = utf8.encode(hardwareId);
      final digest = sha256.convert(bytes);
      localIdentity = digest.toString().substring(0, 12).toUpperCase();

      logTelemetry("Generated ID: $localIdentity");
      notifyListeners();
    }
  }

  void logTelemetry(String message) {
    _telemetryLogs.add(message);
    if (_telemetryLogs.length > 50) {
      _telemetryLogs.removeAt(0);
    }
    notifyListeners();
  }

  // Adds a newly discovered peer to the radar
  void addPeer(String peerId) {
    if (_discoveredPeers.add(peerId)) {
      logTelemetry("Discovered peer: $peerId");
      notifyListeners(); // Tells the UI to rebuild the list
    }
  }

  // Removes a peer if they go offline or out of range
  void removePeer(String peerId) {
    if (_discoveredPeers.remove(peerId)) {
      logTelemetry("Peer disconnected: $peerId");
      notifyListeners();
    }
  }

  // Clears all peers (useful when stopping the radar)
  void clearPeers() {
    _discoveredPeers.clear();
    logTelemetry("Cleared peers");
    notifyListeners();
  }

  // UI state mutators
  void setBottomSheetVisible(bool visible, {String? peerId}) {
    _isBottomSheetVisible = visible;
    if (visible && peerId != null) {
      _activeChatPeer = peerId;
    } else if (!visible) {
      _activeChatPeer = null;
    }
    notifyListeners();
  }

  void addMessage(String peerId, String message) {
    if (!_chatHistory.containsKey(peerId)) {
      _chatHistory[peerId] = [];
    }
    _chatHistory[peerId]!.add(message);
    notifyListeners();
  }

  List<String> getMessages(String peerId) {
    return _chatHistory[peerId] ?? [];
  }
}
