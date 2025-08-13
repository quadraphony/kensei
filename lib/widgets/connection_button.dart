import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class ConnectionButton extends StatelessWidget {
  final VPNConnectionState connectionState;
  final VoidCallback onPressed;

  const ConnectionButton({
    super.key,
    required this.connectionState,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _getGradient(),
            boxShadow: [
              BoxShadow(
                color: _getColor().withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (connectionState == VPNConnectionState.connecting ||
                  connectionState == VPNConnectionState.disconnecting)
                const SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(),
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (connectionState) {
      case VPNConnectionState.connected:
        return Colors.green;
      case VPNConnectionState.connecting:
      case VPNConnectionState.disconnecting:
        return Colors.orange;
      case VPNConnectionState.error:
        return Colors.red;
      case VPNConnectionState.disconnected:
      default:
        return Colors.grey;
    }
  }

  Gradient _getGradient() {
    final color = _getColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.8),
        color,
      ],
    );
  }

  IconData _getIcon() {
    switch (connectionState) {
      case VPNConnectionState.connected:
        return Icons.shield;
      case VPNConnectionState.connecting:
      case VPNConnectionState.disconnecting:
        return Icons.sync;
      case VPNConnectionState.error:
        return Icons.error;
      case VPNConnectionState.disconnected:
      default:
        return Icons.shield_outlined;
    }
  }

  String _getText() {
    switch (connectionState) {
      case VPNConnectionState.connected:
        return 'CONNECTED';
      case VPNConnectionState.connecting:
        return 'CONNECTING';
      case VPNConnectionState.disconnecting:
        return 'DISCONNECTING';
      case VPNConnectionState.error:
        return 'ERROR';
      case VPNConnectionState.disconnected:
      default:
        return 'DISCONNECTED';
    }
  }
}

