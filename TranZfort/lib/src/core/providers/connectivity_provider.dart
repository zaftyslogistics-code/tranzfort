import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  Future<bool> mapResults(List<ConnectivityResult> results) async {
    return results.any((result) => result != ConnectivityResult.none);
  }

  yield await mapResults(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.asyncMap(mapResults);
});
