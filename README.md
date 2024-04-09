# Autoupdate

## Create MSI installer

Edit pubspec.yaml to set the right version 

```yaml
    msix_config:
  display_name: Flutter App
  publisher_display_name: Company Name
  identity_name: company.suite.flutterapp
  msix_version: 1.0.0.0
```

Create a new package

```bash
    dart run msix:create
```

Set the package version in the server, the server should return a json with the following format

```json
    {
    "major":2,
    "minor":0,
    "patch":0
    }
```

Ensure the main.dart is connected to the server in the functions

```dart
    Future<bool> newBuildExist() async {
        //Call backend API to check if new build exist
        //Return true if new build exist
        //http request to localhost3001/version
        final url = Uri.http('localhost:3001', 'version');
    ...
```

```dart
    Future<void> installBuildInTempPath() async {
        final url = Uri.parse('http://localhost:3001/autoupdate.msix');
        final response = await http.get(url);
    ...
```

Deploy this version, then if you want to update, make sure to update your server with the new version and the new msix file.