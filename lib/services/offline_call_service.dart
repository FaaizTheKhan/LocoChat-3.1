import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../providers/locochat_provider.dart';

class OfflineCallService {
  final Strategy strategy = Strategy.P2P_STAR;

  // Maps peer names (IDs) to endpoint IDs.
  final Map<String, String> _peerEndpoints = {};

  // Callback mapping for WebRTC engine
  Function(String peerId, Map<String, dynamic> data)? onSignalingMessage;
  Function(String peerId, String message)? onTextMessage;

  Future<void> startMeshNode(LocoChatProvider state) async {
    // Ensure the user has an identity before broadcasting
    if (state.localIdentity == null) {
      await state.generateIdentity();
    }

    String myId = state.localIdentity!;

    try {
      // Start Advertising
      await Nearby().startAdvertising(
        myId,
        strategy,
        onConnectionInitiated: (id, info) async {
          debugPrint("Connection Initiated: $id (Name: ${info.endpointName})");
          state.logTelemetry("Connection Initiated: ${info.endpointName}");
          // Automatically accept connection for P2P mesh
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              if (payload.type == PayloadType.BYTES) {
                _handleIncomingBytes(endpointId, payload.bytes!, state);
              }
            },
            onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
          );
        },
        onConnectionResult: (id, status) {
          debugPrint("Connection Result: $id - Status: $status");
          state.logTelemetry("Connection Result: $status");
          if (status == Status.CONNECTED) {
            // Need to map endpoint ID to peer ID, but we only have endpoint ID here.
            // A more robust implementation would use a handshake.
          }
        },
        onDisconnected: (id) {
          debugPrint("Disconnected from endpoint: $id");
          state.logTelemetry("Disconnected from: $id");

          String? peerId;
          _peerEndpoints.forEach((key, value) {
            if (value == id) peerId = key;
          });

          if (peerId != null) {
            _peerEndpoints.remove(peerId);
            state.removePeer(peerId!);
          }
        },
      );
      debugPrint("LocoChat Mesh Advertiser started: $myId");
      state.logTelemetry("Started Advertising as $myId");

      // Start Discovering
      await Nearby().startDiscovery(
        "LocoChat",
        strategy,
        onEndpointFound: (id, name, serviceId) {
          debugPrint("Discovered peer: $name (Endpoint: $id)");
          state.logTelemetry("Discovered peer: $name");
          _peerEndpoints[name] = id;
          state.addPeer(name);

          // Initiate connection
          Nearby().requestConnection(
            myId,
            id,
            onConnectionInitiated: (id, info) async {
              await Nearby().acceptConnection(
                id,
                onPayLoadRecieved: (endpointId, payload) {
                  if (payload.type == PayloadType.BYTES) {
                    _handleIncomingBytes(endpointId, payload.bytes!, state);
                  }
                },
                onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
              );
            },
            onConnectionResult: (id, status) {
              debugPrint("Connection Result (Discovery): $id - Status: $status");
            },
            onDisconnected: (id) {
               // handle disconnection similarly
            },
          );
        },
        onEndpointLost: (id) {
          debugPrint("Lost connection to endpoint: $id");
          // Remove from _peerEndpoints and state
          String? peerId;
          _peerEndpoints.forEach((key, value) {
            if (value == id) peerId = key;
          });

          if (peerId != null) {
            _peerEndpoints.remove(peerId);
            state.removePeer(peerId!);
          }
        },
      );
      debugPrint("LocoChat Mesh Scanner started.");
      state.logTelemetry("Started Discovery");

    } catch (e) {
      debugPrint("Mesh Node failed to start: $e");
      state.logTelemetry("Error starting Mesh: $e");
    }
  }

  void _handleIncomingBytes(String endpointId, Uint8List bytes, LocoChatProvider state) {
    try {
      final jsonString = utf8.decode(bytes);
      final payload = jsonDecode(jsonString);

      // Find the peer ID for this endpoint
      String? peerId;
      _peerEndpoints.forEach((key, value) {
        if (value == endpointId) peerId = key;
      });

      if (peerId == null) {
        debugPrint("Received bytes from unknown endpoint: $endpointId");
        return;
      }

      if (payload['type'] == 'text') {
        final message = payload['message'];
        state.addMessage(peerId!, message);
        if (onTextMessage != null) {
          onTextMessage!(peerId!, message);
        }
      } else if (payload['type'] == 'webrtc_signaling') {
        if (onSignalingMessage != null) {
          onSignalingMessage!(peerId!, payload['data']);
        }
      }
    } catch (e) {
      debugPrint("Error decoding incoming bytes: $e");
    }
  }

  void sendTextMessage(String peerId, String message) {
    final endpointId = _peerEndpoints[peerId];
    if (endpointId != null) {
      final payload = {
        'type': 'text',
        'message': message,
      };
      final bytes = utf8.encode(jsonEncode(payload));
      Nearby().sendBytesPayload(endpointId, Uint8List.fromList(bytes));
    }
  }

  void sendSignalingMessage(String peerId, Map<String, dynamic> data) {
    final endpointId = _peerEndpoints[peerId];
    if (endpointId != null) {
      final payload = {
        'type': 'webrtc_signaling',
        'data': data,
      };
      final bytes = utf8.encode(jsonEncode(payload));
      Nearby().sendBytesPayload(endpointId, Uint8List.fromList(bytes));
    }
  }

  void stopMeshNode() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    _peerEndpoints.clear();
  }
}
