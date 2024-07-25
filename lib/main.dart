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
  dynamic temperature = 0.0;
  dynamic humidity = 0.0;
  Timer? timer;
  bool isRunning = false;
  String apiUrl = '';
  final TextEditingController _controller = TextEditingController();

  void startDataFetch() {
    if (apiUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an API URL')),
      );
      return;
    }
    setState(() {
      isRunning = true;
    });
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => fetchData());
  }

  void stopDataFetch() {
    setState(() {
      isRunning = false;
    });
    timer?.cancel();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = data['temperature'];
          humidity = data['humidity'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sensor Data')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter API URL',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    apiUrl = value;
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
                        Text('${temperature.toStringAsFixed(1)}°C'),
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
                        Text('${humidity.toStringAsFixed(1)}%'),
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    super.dispose();
  }
}
