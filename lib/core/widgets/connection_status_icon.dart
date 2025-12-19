import 'package:flutter/material.dart';
import '../services/connection_service.dart';

class ConnectionStatusIcon extends StatelessWidget {
  const ConnectionStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectionService.instance.connectionStream,
      builder: (context, snap) {
        final online = snap.data ?? ConnectionService.instance.isOnline;
        return Icon(
          online 
              ? Icons.cloud_outlined 
              : Icons.cloud_off_outlined,
          size: 22,
          color: online 
              ? Colors.blueAccent 
              : Colors.redAccent,
        );
      },
    );
  }
}