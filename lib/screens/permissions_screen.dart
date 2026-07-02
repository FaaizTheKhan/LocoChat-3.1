import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionsScreen({super.key, required this.onPermissionsGranted});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissionsAndStart() async {
    setState(() => _isRequesting = true);

    // Request the core hardware permissions required for offline P2P
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.camera,
      Permission.microphone,
    ].request();

    setState(() => _isRequesting = false);

    // Check if the most critical permissions were granted
    if (statuses[Permission.bluetooth]!.isGranted && statuses[Permission.location]!.isGranted) {
      // Notify parent
      widget.onPermissionsGranted();
    } else {
      // Show an error if they denied the permissions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth and Location are required for offline mesh!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 80, color: Color(0xFF38BDF8)),
            const SizedBox(height: 24),
            const Text(
              "LocoChat",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Completely offline peer-to-peer messaging and calling. No internet required.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 60),
            _isRequesting
              ? const CircularProgressIndicator(color: Color(0xFF38BDF8))
              : ElevatedButton.icon(
                  onPressed: _requestPermissionsAndStart,
                  icon: const Icon(Icons.rocket_launch, color: Colors.white),
                  label: const Text(
                    "Grant Access & Start",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                    shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
