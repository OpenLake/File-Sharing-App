// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// void main() => runApp(const MyApp());
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     const appTitle = 'Form Validation Demo';
//
//     return MaterialApp(
//       title: appTitle,
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text(appTitle),
//         ),
//         body: const MyCustomForm(),
//       ),
//     );
//   }
// }
//
// // Create a Form widget.
// class MyCustomForm extends StatefulWidget {
//   const MyCustomForm({super.key});
//
//   @override
//   MyCustomFormState createState() {
//     return MyCustomFormState();
//   }
// }
//
// // Create a corresponding State class.
// // This class holds data related to the form.
// class MyCustomFormState extends State<MyCustomForm> {
//   // Create a global key that uniquely identifies the Form widget
//   // and allows validation of the form.
//   //
//   // Note: This is a GlobalKey<FormState>,
//   // not a GlobalKey<MyCustomFormState>.
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _controller = TextEditingController();
//   postTest(String Title) async {
//     // var requestBody = {
//     //
//     // };
//
//     http.Response response = await http.post(
//       Uri.parse('http://10.3.19.15:5500'),
//       // body: json.encode(requestBody),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'grant_type': Title,
//       },
//       body: jsonEncode(<String, String>{
//         'grant_type': Title,
//       }),
//     );
//     if (response.statusCode == 201) {
//       // If the server did return a 201 CREATED response,
//       // then parse the JSON.
//       return print('succeed');
//     } else {
//       // If the server did not return a 201 CREATED response,
//       // then throw an exception.
//       throw Exception('Failed to create album.');
//     }
//   }
//
//   // if (response.statusCode == 201) {
//   //   // If the server did return a 201 CREATED response,
//   //   // then parse the JSON.
//   //   return Home;
//   // } else {
//   //   // If the server did not return a 201 CREATED response,
//   //   // then throw an exception.
//   //   throw Exception('Failed to create album.');
//   // }
// }
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Sharing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Sharing App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text('Upload File'),
              onPressed: () async {
                // Select a file using the file picker plugin
                var result =
                    await FilePicker.platform.pickFiles(type: FileType.any);

                if (result != null) {
                  var request = MultipartRequest(
                      'POST', Uri.parse('http://10.3.18.69:8000/upload'));
                  request.files.add(await http.MultipartFile.fromPath(
                    'file',
                    result.files.first.path.toString(),
                  ));

                  // Send a POST request to the server to upload the file
                  var response = await request.send();
                  print(response.statusCode);
                  print(request.files.first.field);
                }
              },
            ),
            ElevatedButton(
              child: Text('Download File'),
              onPressed: () async {
                // Send a GET request to the server to download the file
                var response = await http
                    .get(Uri.parse('http://10.3.18.69:8000/download'));

                // Save the file to the device
                var file = File('/path/to/save/file.txt');
                file.writeAsStringSync(response.body);
              },
            ),
          ],
        ),
      ),
    );
  }
}
