import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:weather_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      home: const MyHomePage(title: 'Nederbörd'),
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
            height: 500,
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
