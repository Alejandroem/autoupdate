import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

Future<bool> newBuildExist() async {
  //Call backend API to check if new build exist
  //Return true if new build exist
  //http request to localhost3001/version
  final url = Uri.http('localhost:3001', 'version');
  final response = await http.get(url);
  final decodedResponse = jsonDecode(response.body);

  final packageInfo = await PackageInfo.fromPlatform();
  final version = packageInfo.version;

  if (response.statusCode == 200) {
    List<int> versionList = version.split('.').map(int.parse).toList();

    if (decodedResponse["major"] > versionList[0]) {
      return true;
    } else if (decodedResponse["major"] == versionList[0]) {
      if (decodedResponse["minor"] > versionList[1]) {
        return true;
      } else if (decodedResponse["minor"] == versionList[1]) {
        if (decodedResponse["patch"] > versionList[2]) {
          return true;
        }
      }
    }
  }
  return false;
}

Future<void> installBuildInTempPath() async {
  final url = Uri.parse('http://localhost:3001/autoupdate.msix');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var tempDir = await getTemporaryDirectory();
    var file = File('${tempDir.path}\\autoupdate.msix');
    await file.writeAsBytes(response.bodyBytes);
    log('File downloaded to: ${file.path}');
  } else {
    log('Failed to download file: ${response.statusCode}');
  }
}

Future<void> executeNewBuildInstaller() async {
  // execute the new build installer
  // using the command line
  var tempDir = await getTemporaryDirectory();
  var file = File('${tempDir.path}\\autoupdate.msix');
  if (file.existsSync()) {
    var shell = Shell();
    try {
      await shell.run('powershell.exe ${file.path}');
      log('Installer executed');
    } catch (e) {
      log('Error executing installer: $e');
    } finally {
      log('Installer executed');
      shell.kill();
    }
  }
}

void main() async {
  Future.delayed(const Duration(minutes: 1), () async {
    if (await newBuildExist()) {
      await installBuildInTempPath();
      await executeNewBuildInstaller();
    }
  });
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
