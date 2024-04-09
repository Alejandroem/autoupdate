import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

import 'constants.dart';

Future<bool> newBuildExist() async {
  //Call backend API to check if new build exist
  //Return true if new build exist
  //http request to localhost3001/version
  final response = await http.get(Uri.parse('$serverUrl/version'));
  final decodedResponse = jsonDecode(response.body);

  final packageInfo = await PackageInfo.fromPlatform();
  final version = packageInfo.version;
  log('Current version: $version');

  if (response.statusCode == 200) {
    log('New version: ${decodedResponse["major"]}.${decodedResponse["minor"]}.${decodedResponse["patch"]}');
    List<int> versionList = version.split('.').map(int.parse).toList();

    if (decodedResponse["major"] > versionList[0]) {
      log('New version available major update');
      return true;
    } else if (decodedResponse["major"] == versionList[0]) {
      if (decodedResponse["minor"] > versionList[1]) {
        log('New version available minor update');
        return true;
      } else if (decodedResponse["minor"] == versionList[1]) {
        if (decodedResponse["patch"] > versionList[2]) {
          log('New version available patch update');
          return true;
        }
      }
    }
  }
  log('No new version');
  return false;
}

Future<void> installBuildInTempPath() async {
  final response = await http.get(Uri.parse('$serverUrl/autoupdate.msix'));
  if (response.statusCode == 200) {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}\\autoupdate.msix');
    await file.writeAsBytes(response.bodyBytes);
    log('File downloaded to: ${file.path}');
  } else {
    log('Failed to download file: ${response.statusCode}');
  }
}

Future<void> executeNewBuildInstaller() async {
  // execute the new build installer
  // using the command line
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}\\autoupdate.msix');
  if (file.existsSync()) {
    final shell = Shell();
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

void scheduleVersionCheck() {
  Future.delayed(const Duration(minutes: 1), () async {
    if (await newBuildExist()) {
      await installBuildInTempPath();
      await executeNewBuildInstaller();
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  scheduleVersionCheck();

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
