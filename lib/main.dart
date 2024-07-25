import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Data',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  dynamic temperature = '0.0';
  dynamic humidity = '0.0';
  Timer? timer;
  bool isRunning = false;
  String postUrl = '';
  String getUrl = '';
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _getController = TextEditingController();

  void startDataFetch() {
    if (postUrl.isEmpty || getUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both POST and GET URLs')),
      );
      return;
    }
    setState(() {
      isRunning = true;
    });
    postData('start');
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => fetchData());
  }

  void stopDataFetch() {
    setState(() {
      isRunning = false;
    });
    postData('stop');
    timer?.cancel();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(getUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = data['data']['_temperature'].toString();
          humidity = data['data']['_humidity'].toString();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      stopDataFetch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data. Stopped fetching.')),
      );
    }
  }

  Future<void> postData(String status) async {
    try {
      final response = await http.post(
        Uri.parse(postUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          '_status': status,
        }),
      );
      if (response.statusCode == 200) {
        print('Data posted successfully');
      } else {
        throw Exception('Failed to post data');
      }
    } catch (e) {
      print('Error posting data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sensor Data')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  controller: _postController,
                  decoration: InputDecoration(
                    labelText: 'Enter POST URL',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      postUrl = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  controller: _getController,
                  decoration: InputDecoration(
                    labelText: 'Enter GET URL',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      getUrl = value;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Temperature'),
                          Text('$temperature°C'),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Humidity'),
                          Text('$humidity%'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isRunning ? null : startDataFetch,
                    child: Text('Start'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: isRunning ? stopDataFetch : null,
                    child: Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    _getController.dispose();
    timer?.cancel();
    super.dispose();
  }
}
