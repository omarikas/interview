import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:geolocator/geolocator.dart';

// ...


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Tabs Demo'),
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
  Future? _futureData;
  @override
  void initState() {
    super.initState();
  _futureData =  fetchPosts();
  }
  late Map<String,dynamic> city={"name":"loading"};
  Future fetchPosts() async {
    try {
      QuerySnapshot locs = await FirebaseFirestore.instance.collection("locs").get();
      List<Map<String, dynamic>> cities = [];

      for (var doc in locs.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double lat = data["lat"];
        double long = data["long"];
        String docId = doc.id;

        final response = await http.get(Uri.parse(
            'https://nominatim.openstreetmap.org/reverse.php?lat=$lat&lon=$long&zoom=18&format=jsonv2'));

        if (response.statusCode == 200) {
          final displayName = jsonDecode(response.body)["display_name"];
          if (displayName != null) {
            cities.add({
              "id": docId,
              "name": displayName,
              "lat":lat,
              "long":long
            });
          }
        } else {
          print('Failed to load city for lat: $lat, long: $long');
        }
      }

      setState(() {
        city = cities[0];
      });
    } catch (e) {
      print('Error fetching posts: $e');
    }
    return "done";
  }











  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(city["name"]),
          actions: [
            IconButton(
              icon: Icon(Icons.add_location),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title:Text("locations"),
                    
                      content:
               location(),
                      
                      actions: [
                        TextButton(
                          onPressed: () {
                          _futureData=  fetchPosts();
                            Navigator.of(context).pop();
                          },
                          child: Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
         body: FutureBuilder<dynamic>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return  TabBarView(
          children: [
            Currentweather(long: city["long"],lat:city["lat"]),
            hourly(long: city["long"],lat:city["lat"]),
            daily(long: city["long"],lat:city["lat"]),
          ]);
  }
  
  
   return  TabBarView(
          children: [
            Currentweather(long: city["long"],lat:city["lat"]),
            hourly(long: city["long"],lat:city["lat"]),
            daily(long: city["long"],lat:city["lat"]),
          ]);
        }
  
  
  
  
  
  
  
  
  ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.sunny_snowing), text: "Current weather"),
            Tab(icon: Icon(Icons.lock_clock), text: "Hourly forecast"),
            Tab(icon: Icon(Icons.calendar_month), text: "Daily forecast"),
          ],
        ),
      ),
    );
  }
}

class Currentweather extends StatefulWidget {
dynamic long;
dynamic lat;
   Currentweather({super.key, this.long,this.lat});

  @override
  CurrentweatherState createState() => CurrentweatherState();
}

class CurrentweatherState extends State<Currentweather> {
  double currweathervar = 0;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  void fetchPosts() async {
    final response = await http.get(Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=${widget.lat}&longitude=${widget.long}&current=temperature_2m"));

    if (response.statusCode == 200) {
      setState(() {
        currweathervar = jsonDecode(response.body)["current"]["temperature_2m"];
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(currweathervar.toString()),
    );
  }
}

class daily extends StatefulWidget {
  
dynamic long;
dynamic lat;
   daily({super.key, this.long,this.lat});
  @override
  dailystate createState() => dailystate();
}

class dailystate extends State<daily> {
  List<dynamic> max = [];
  List<dynamic> min = [];
  List<dynamic> date = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  void fetchPosts() async {
     final response = await http.get(Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=${widget.lat}&longitude=${widget.long}&daily=temperature_2m_max,temperature_2m_min"));
    if (response.statusCode == 200) {
      setState(() {
        max = jsonDecode(response.body)["daily"]["temperature_2m_max"];
        min = jsonDecode(response.body)["daily"]["temperature_2m_min"];
        date = jsonDecode(response.body)["daily"]["time"];
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: max.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(date[index].toString()),
          subtitle: Text(max[index].toString() + "," + min[index].toString()),
        );
      },
    );
  }
}

class hourly extends StatefulWidget {
  
dynamic long;
dynamic lat;
   hourly({super.key, this.long,this.lat});

  @override
  hourlystate createState() => hourlystate();
}

class hourlystate extends State<hourly> {
  List<dynamic> temper = [];
  List<dynamic> date = [];

  
















  @override
  void initState() {
    super.initState();
    if(widget.lat!=null){
      print("yayayay");
    fetchPosts();
    }
  }

  void fetchPosts() async {
    final response = await http.get(Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=${widget.lat}&longitude=${widget.long}&current=temperature_2m&hourly=temperature_2m"));
    if (response.statusCode == 200) {
      if(this.mounted)
      setState(() {
        temper = jsonDecode(response.body)["hourly"]["temperature_2m"];
        date = jsonDecode(response.body)["hourly"]["time"];
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: temper.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(date[index].toString()),
          subtitle: Text(temper[index].toString()),
        );
      },
    );
  }
}

class location extends StatefulWidget {
  const location({super.key});

  @override
  locationstate createState() => locationstate();
}
class locationstate extends State<location> {
  List<Map<String, dynamic>> citiesWithIds = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void fetchPosts() async {
    try {
      QuerySnapshot locs = await FirebaseFirestore.instance.collection("locs").get();
      List<Map<String, dynamic>> cities = [];

      for (var doc in locs.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double lat = data["lat"];
        double long = data["long"];
        String docId = doc.id;

        final response = await http.get(Uri.parse(
            'https://nominatim.openstreetmap.org/reverse.php?lat=$lat&lon=$long&zoom=18&format=jsonv2'));

        if (response.statusCode == 200) {
          final displayName = jsonDecode(response.body)["display_name"];
          if (displayName != null) {
            cities.add({
              "id": docId,
              "name": displayName,
            });
          }
        } else {
          print('Failed to load city for lat: $lat, long: $long');
        }
      }

      setState(() {
        citiesWithIds = cities;
      });
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 400,
      child: Column(
        
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dialog Title'),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  try {
                    Position pos = await _getCurrentPosition();
                    await FirebaseFirestore.instance.collection("locs").add({
                      "lat": pos.latitude,
                      "long": pos.longitude
                    });

                  fetchPosts();
                  } catch (e) {
                    print('Error getting position or adding to Firestore: $e');
                  }
                },
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: citiesWithIds.length,
              itemBuilder: (context, index) {
                final city = citiesWithIds[index];
                return Dismissible(
                  key: Key(city["id"]),
                  onDismissed: (direction) async {
                    try {
                      // Remove item from Firestore
                      await FirebaseFirestore.instance.collection("locs").doc(city["id"]).delete();

                      // Update local list
                      setState(() {
                        citiesWithIds.removeAt(index);
                      });
                    } catch (e) {
                      print('Error removing item from Firestore: $e');
                    }
                  },
                  child: ListTile(
                    title: Text(city["name"]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
