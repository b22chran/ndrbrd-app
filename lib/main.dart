import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:weather_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  int _selectedIndex = 0; // Default to InventoryPage

  // List of pages
  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    _pages = [
      const Center(child: Text('Home Page')),
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
      body: _pages[_selectedIndex], // Display selected page

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
              print("Button pressed"); //test wich step to start a meassure
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
                  print("returned"); //test to see wich step to stop a meassure
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

// Future<List<dynamic>> fetchNdrbrdData(String landskap, String station) async {
//   final response = await http.get(
//     Uri.parse(
//       'http://localhost:3000/ndrbrd?landskap=$landskap&station=$station')
//   );

//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else {
//     throw Exception('Failed to load data');
//   }
// }
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
                _searchTermStateMongo = _searchControllerStateMongo.text.toLowerCase();
                _searchTermStationMongo =
                    _searchControllerStationMongo.text.toLowerCase();
              });
              print("Button pressed"); //test wich step to start a meassure
              print("Fetching with landskap=$_searchTermStateMongo, station=$_searchTermStationMongo");
            },
            child: Text("Sök"),
          ),
          SizedBox(height: 8),
          Container(
            color: Colors.blue[100],
            height: 350,
            child: FutureBuilder(
              future: fetchNdrbrdData(_searchTermStateMongo, _searchTermStationMongo),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Hittade ingen data från mongoDB"));
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
