import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:weather_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/performance_tester.dart';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

TextEditingController _searchControllerState = TextEditingController();
String _searchTermState = '';

TextEditingController _searchControllerStation = TextEditingController();
String _searchTermStation = '';

TextEditingController _searchControllerStateMongo = TextEditingController();
String _searchTermStateMongo = '';

TextEditingController _searchControllerStationMongo = TextEditingController();
String _searchTermStationMongo = '';

Future<Map<String, List<String>>> fetchAllStationsAndLandskap() async {
  final snapshot = await FirebaseFirestore.instance.collection('ndrbrd').get();

  final Set<String> stations = {};
  final Set<String> landskap = {};

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (data.containsKey('Station')) {
      stations.add(data['Station']);
    }
    if (data.containsKey('Landskap')) {
      landskap.add(data['Landskap']);
    }
  }

  return {
    'stations': stations.toList(),
    'landskap': landskap.toList(),
  };
}

List<String> generateRandomQueries(
    List<String> allPossibleQueries, int count, int seed) {
  final random = Random(seed);
  final List<String> randomized = [];

  for (int i = 0; i < count; i++) {
    final index = random.nextInt(allPossibleQueries.length);
    randomized.add(allPossibleQueries[index]);
  }

  return randomized;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Väder Applikation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    _pages = [
      PerformanceTestHomePage(title: "Prestanda Test (ms)"),
      MyFirebasePage(title: 'Nederbörd Firebase'),
      MyMongoPage(title: "Nederbörd MoongoDB"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_rounded),
            label: 'Firebase',
          ),
          NavigationDestination(
              icon: Icon(Icons.dataset_outlined), label: 'MongoDB'),
        ],
      ),
    );
  }
}

class PerformanceTestHomePage extends StatefulWidget {
  @override
  const PerformanceTestHomePage({super.key, required this.title});

  final String title;
  _PerformanceTestHomePageState createState() =>
      _PerformanceTestHomePageState();
}

class _PerformanceTestHomePageState extends State<PerformanceTestHomePage> {
  final TextEditingController _countController =
      TextEditingController(text: "10");
  String _queryType = 'station';
  String _source = 'mongo';
  bool _isRunning = false;
  String _status = 'Idle';

  Future<List<dynamic>> fetchFromMongo(String queryValue) async {
    final uri =
        Uri.parse('http://localhost:3000/weather?$_queryType=$queryValue');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('MongoDB fetch failed');
    return json.decode(resp.body);
  }

  Future<List<dynamic>> fetchFromFirebase(String queryValue) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('ndrbrd')
        .where(_queryType == 'station' ? 'Station' : 'Landskap',
            isEqualTo: queryValue)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> startPerformanceTest() async {
    setState(() {
      _isRunning = true;
      _status = "Running...";
    });

    final int numberOfQueries = int.tryParse(_countController.text) ?? 10;
    final int seed = 42;

    // Fetch station and landskap names from database dynamically
    final allValues = await fetchAllStationsAndLandskap();
    final allStations = allValues['stations']!;
    final allLandskap = allValues['landskap']!;

    // Randomize queries using seed
    List<String> queries;
    if (_queryType == 'station') {
      queries = generateRandomQueries(allStations, numberOfQueries, seed);
    } else {
      queries = generateRandomQueries(allLandskap, numberOfQueries, seed);
    }

    // Start the performance test
    final tester = PerformanceTester(
      queryValues: queries,
      fetcher: _source == 'mongo' ? fetchFromMongo : fetchFromFirebase,
      queryType: _queryType,
      intervalMs: 1500,
      testName: '${_source}_${_queryType}_test',
    );

    await tester.runTest();

    setState(() {
      _isRunning = false;
      _status = "Done! CSV saved.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(
            value: _queryType,
            items: ['station', 'landskap']
                .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                .toList(),
            onChanged: (value) => setState(() => _queryType = value!),
          ),
          DropdownButton<String>(
            value: _source,
            items: ['mongo', 'firebase']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) => setState(() => _source = value!),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _countController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Number of Iterations",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isRunning ? null : startPerformanceTest,
            child: const Text("Start Performance Test"),
          ),
          const SizedBox(height: 20),
          Text ('Status: $_status'),
        ],
      ),
    );
  }
}

class MyFirebasePage extends StatefulWidget {
  const MyFirebasePage({super.key, required this.title});

  final String title;

  @override
  State<MyFirebasePage> createState() => _MyFirebasePage();
}

class _MyFirebasePage extends State<MyFirebasePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blueAccent,
            width: double.infinity,
            height: 50.0,
            child: TextField(
              controller: _searchControllerState,
              decoration: InputDecoration(
                hintText: 'Sök efter Landskap...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            color: Colors.blueAccent,
            width: double.infinity,
            height: 50.0,
            child: TextField(
              controller: _searchControllerStation,
              decoration: InputDecoration(
                hintText: 'Sök efter Station...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchTermState = _searchControllerState.text.toLowerCase();
                _searchTermStation =
                    _searchControllerStation.text.toLowerCase();
              });
            },
            child: Text("Sök"),
          ),
          SizedBox(height: 8),
          Container(
            color: Colors.blue[100],
            height: 350,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('ndrbrd').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Hittade ingen data"));
                }

                var ndrbrdData = snapshot.data!.docs.where((doc) {
                  var landskap = doc['Landskap']?.toString().toLowerCase();
                  var station = doc['Station']?.toString().toLowerCase();

                  final matchLandskap = _searchTermState.isEmpty ||
                      landskap!.contains(_searchTermState);
                  final matchStation = _searchTermStation.isEmpty ||
                      station!.contains(_searchTermStation);

                  return matchLandskap && matchStation;
                }).toList();

                if (ndrbrdData.isEmpty) {
                  return const Center(child: Text("Ingen matchning"));
                }

                return ListView.builder(
                  itemCount: ndrbrdData.length,
                  itemBuilder: (context, index) {
                    var dataNdrbrd = ndrbrdData[index];
                    return ListTile(
                      title: Text(
                          'Station: ${dataNdrbrd['Station']} - ${dataNdrbrd['Landskap']}'),
                      subtitle: Text(
                          "jan: ${dataNdrbrd['jan']} feb: ${dataNdrbrd['feb']} mar: ${dataNdrbrd['mar']} apr: ${dataNdrbrd['apr']} maj: ${dataNdrbrd['maj']} juni: ${dataNdrbrd['jun']} juli: ${dataNdrbrd['jul']} aug: ${dataNdrbrd['aug']} sep: ${dataNdrbrd['sep']} okt: ${dataNdrbrd['okt']} nov: ${dataNdrbrd['nov']} dec: ${dataNdrbrd['dec']}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<dynamic>> fetchNdrbrdData(String landskap, String station) async {
  final uri = Uri.parse(
    'http://localhost:3000/weather?landskap=$landskap&station=$station',
  );

  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('Failed to load data (status: ${resp.statusCode})');
  }

  return json.decode(resp.body) as List<dynamic>;
}

class MyMongoPage extends StatefulWidget {
  const MyMongoPage({super.key, required this.title});

  final String title;

  @override
  State<MyMongoPage> createState() => _MyMongoPage();
}

class _MyMongoPage extends State<MyMongoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.purple[50],
            width: double.infinity,
            height: 50.0,
            child: TextField(
              controller: _searchControllerStateMongo,
              decoration: InputDecoration(
                hintText: 'Sök efter Landskap...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            color: Colors.purple[50],
            width: double.infinity,
            height: 50.0,
            child: TextField(
              controller: _searchControllerStationMongo,
              decoration: InputDecoration(
                hintText: 'Sök efter Station...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchTermStateMongo =
                    _searchControllerStateMongo.text.toLowerCase();
                _searchTermStationMongo =
                    _searchControllerStationMongo.text.toLowerCase();
              });
            },
            child: Text("Sök"),
          ),
          SizedBox(height: 8),
          Container(
            color: Colors.blue[100],
            height: 350,
            child: FutureBuilder(
              future: fetchNdrbrdData(
                  _searchTermStateMongo, _searchTermStationMongo),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Hittade ingen data från mongoDB"));
                }

                final data = snapshot.data!;
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final entry = data[index];
                    return ListTile(
                      title: Text(
                          'Station: ${entry['Station']} - ${entry['Landskap']}'),
                      subtitle: Text(
                          "jan: ${entry['jan']} feb: ${entry['feb']} mar: ${entry['mar']} apr: ${entry['apr']} maj: ${entry['maj']} juni: ${entry['jun']} juli: ${entry['jul']} aug: ${entry['aug']} sep: ${entry['sep']} okt: ${entry['okt']} nov: ${entry['nov']} dec: ${entry['dec']}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
