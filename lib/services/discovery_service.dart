import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../providers/chat_state.dart';

class DiscoveryService {
  final Strategy strategy = Strategy.P2P_STAR;

  Future<void> startMeshNode(ChatState state) async {
    // 1. Ensure the user has an identity before broadcasting
    if (state.localIdentity == null) {
      state.generateIdentity();
    }

    String myId = state.localIdentity!;

    try {
      // 2. Start Advertising (Broadcasting our presence)
      await Nearby().startAdvertising(
        myId,
        strategy,
        onConnectionInitiated: (id, info) {},
        onConnectionResult: (id, status) {},
        onDisconnected: (id) => state.removePeer(id),
      );
      debugPrint("LocoChat Mesh Advertiser started: $myId");

      // 3. Start Discovering (Scanning for others)
      await Nearby().startDiscovery(
        "LocoChat", // Must match exactly across all devices
        strategy,
        onEndpointFound: (id, name, serviceId) {
          // 'name' is the localIdentity of the peer that we found
          debugPrint("Discovered peer: $name (Endpoint: $id)");
          state.addPeer(name);
        },
        onEndpointLost: (id) {
          // Note: Nearby Connections uses endpoint 'id' here, you might need to map IDs to names
          debugPrint("Lost connection to endpoint: $id");
        },
      );
      debugPrint("LocoChat Mesh Scanner started.");

    } catch (e) {
      debugPrint("Mesh Node failed to start: $e");
    }
  }

  void stopMeshNode() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
  }
}
