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
// import 'dart:html';
// import 'dart:typed_data';

// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:clipboard/clipboard.dart';
// import 'dart:io';
// import 'dart:convert';
import 'package:flutter_share/flutter_share.dart';
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
  Future<void> share() async {
    await FlutterShare.share(
        title: 'Example share',
        text: 'Example share text',
        linkUrl: 'https://flutter.dev/',
        chooserTitle: 'Example Chooser Title'
    );
  }
  var download = " ";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Sharing App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "FILE SHARING APP",
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                    overflow: TextOverflow.fade,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 40,
                    shadows: <Shadow>[
                Shadow(
                offset: Offset(2.0, 2.0),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              Shadow(
                offset: Offset(2.0, 2.0),
                blurRadius: 8.0,
                color: Color.fromARGB(125, 0, 0, 255),
              ),
            ],),

              ),
              SizedBox(height: 100),
              ElevatedButton(
                child: Text(
                  'UPLOAD FILE',
                  style: TextStyle(fontWeight: FontWeight.bold,overflow: TextOverflow.visible,),
                ),
                style: ButtonStyle(
                  textStyle:
                      MaterialStateProperty.all(const TextStyle(fontSize: 23)),
                  overlayColor: MaterialStateProperty.all(Colors.red),
                  shadowColor: MaterialStateProperty.all(Colors.lightBlue),
                  elevation: MaterialStateProperty.all(15),
                  minimumSize: MaterialStateProperty.all(const Size(200, 80)),
                  // splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
                ),
                onPressed: () async {
                  // Select a file using the file picker plugin
                  var result =
                      await FilePicker.platform.pickFiles(type: FileType.any);

                  if (result != null) {
                    var request = MultipartRequest(
                        'POST', Uri.parse('http://10.3.9.249:8000/upload'));
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
              SizedBox(height: 100),
              Center(
                child: Row(
                  children: [
                    Container(
                        margin: EdgeInsets.fromLTRB(10,10,10,10),
                        constraints: BoxConstraints(

                            minHeight: 50,
                            minWidth: 50,
                            maxWidth: 400,
                            maxHeight: 70),
                        decoration:BoxDecoration(
                          // border: Border(
                          //   top: BorderSide(),
                          //   left: BorderSide(),
                          //   right: BorderSide(),
                          //   bottom: BorderSide(),
                          // ),
                          border: Border.all(
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(download)),
                    GestureDetector(
                      child: const Icon(Icons.copy, color: Colors.blue, size: 32),
                      onTap: () {
                        if (download.trim() == "") {
                          print('enter text');
                        } else {
                          FlutterClipboard.copy(download).then((value) {
                            const snack = SnackBar(
                                content: Text("Text copied"),
                                duration: Duration(seconds: 2));
                            ScaffoldMessenger.of(context).showSnackBar(snack);
                          });
                        }
                        ;
                      },
                    ),
                    IconButton(
                      onPressed:share,
                      icon: Icon(Icons.share,
                          color: Colors.blue, size: 32

                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  child: Text(
                    'DOWNLOAD FILE',
                    style: TextStyle(fontWeight: FontWeight.bold,overflow: TextOverflow.visible,),
                  ),
                  style: ButtonStyle(
                    textStyle:
                        MaterialStateProperty.all(const TextStyle(fontSize: 23)),
                    overlayColor: MaterialStateProperty.all(Colors.red),
                    shadowColor: MaterialStateProperty.all(Colors.lightBlue),
                    elevation: MaterialStateProperty.all(15),
                    minimumSize: MaterialStateProperty.all(const Size(200, 80)),
                  ),
                  onPressed: <String>() async {
                    final response = await http
                        .get(Uri.parse('http://10.3.9.249:8000/download'));
                    if (response.statusCode == 200) {
                      print(response.body);
                      setState(() {
                        download = response.body;
                      });
                      // Text(response.body);
                    } else {
                      throw Exception('Failed to get string');
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
