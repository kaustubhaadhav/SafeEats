import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected; // ← Simple question: "Is there internet?"
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity; // ← Uses connectivity_plus package

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none; // ← true if WiFi/Mobile data
  }
}