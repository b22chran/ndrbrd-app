import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';

typedef DataFetcher = Future<List<dynamic>> Function(String queryValue);

class PerformanceTester {
  final List<String> queryValues;
  final DataFetcher fetcher;
  final String queryType; // landskap or station
  final int intervalMs;
  final String testName;
  
  int _iterationCounter = 0;

  final List<List<dynamic>> _results = [];

  PerformanceTester({
    required this.queryValues,
    required this.fetcher,
    required this.queryType,
    required this.intervalMs,
    this.testName = "performance_test",
  });

  Future<void> runTest() async {
    print("Starting performance test...");
    _iterationCounter = 0; 
    _results.clear();      

    for (var value in queryValues) {
      _iterationCounter++; 
      final stopwatch = Stopwatch()..start();

      try {
        final data = await fetcher(value);
        stopwatch.stop();

        final row = [
          _iterationCounter,                 
          DateTime.now().toIso8601String(),
          queryType,
          value,
          stopwatch.elapsedMilliseconds,
          data.length
        ];

        _results.add(row);
        print("Iter $_iterationCounter | ${value.padRight(15)} | Time: ${stopwatch.elapsedMilliseconds} ms | Count: ${data.length}");
      } catch (e) {
        stopwatch.stop();
        final row = [
          _iterationCounter,                 
          DateTime.now().toIso8601String(),
          queryType,
          value,
          "ERROR",
          0
        ];
        _results.add(row);
        print("Iter $_iterationCounter | ${value.padRight(15)} | ERROR: $e");
      }

      await Future.delayed(Duration(milliseconds: intervalMs));
    }

    await _saveResultsToCsvWeb();
  }

  Future<void> _saveResultsToCsvWeb() async {
    final csvData = [
      ["Iteration", "Timestamp", "QueryType", "QueryValue", "TimeMs", "ResultCount"],
      ..._results
    ];

    final csvString = const ListToCsvConverter().convert(csvData);

    final now = DateTime.now();
    final timestamp = "${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_${_twoDigits(now.hour)}-${_twoDigits(now.minute)}";

    final filename = "${testName}_$timestamp.csv";

    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();

    html.Url.revokeObjectUrl(url);

    print("CSV file generated and download started! Saved as $filename");
  }

  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }
}
