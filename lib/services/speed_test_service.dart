import 'dart:async';
import 'dart:io';

class SpeedTestService {
  static Future<int> testLatency(String serverAddress, int port) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(serverAddress, port, timeout: const Duration(seconds: 5));
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      print('Latency test error: $e');
      return -1; // Indicate failure
    }
  }

  // A basic speed test. For a more accurate test, a dedicated speed test server and larger data transfers would be needed.
  static Future<double> testDownloadSpeed(String url, {int fileSize = 1024 * 1024}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      int downloadedBytes = 0;
      await for (var contents in response) {
        downloadedBytes += contents.length;
        if (downloadedBytes >= fileSize) break; // Stop after downloading a certain amount
      }
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds == 0) return 0.0;
      return (downloadedBytes / 1024) / (stopwatch.elapsedMilliseconds / 1000); // KBps
    } catch (e) {
      print('Download speed test error: $e');
      return 0.0;
    }
  }
}

