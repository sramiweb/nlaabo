import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  
  const NetworkStatusWidget({super.key, required this.child});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool _isCheckingNetwork = false;
  NetworkStatus? _lastNetworkStatus;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_lastNetworkStatus != null && !_lastNetworkStatus!.isConnected)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkNetwork,
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _checkNetwork() async {
    if (_isCheckingNetwork) return;
    
    setState(() {
      _isCheckingNetwork = true;
    });

    try {
      final status = await ConnectivityService.checkConnectivity();
      setState(() {
        _lastNetworkStatus = status;
      });
    } catch (e) {
      setState(() {
        _lastNetworkStatus = NetworkStatus(
          isConnected: false,
          canReachSupabase: false,
          message: 'Network check failed',
          details: e.toString(),
          failureType: NetworkFailureType.unknownError,
        );
      });
    } finally {
      setState(() {
        _isCheckingNetwork = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkNetwork();
  }
}
