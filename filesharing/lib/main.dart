import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:clipboard/clipboard.dart';
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
        chooserTitle: 'Example Chooser Title');
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
                  fontSize: 100,
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
                  ],
                ),
              ),
              SizedBox(height: 100),
              ElevatedButton(
                child: Text(
                  'UPLOAD FILE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.visible,
                  ),
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
                        'POST', Uri.parse('http://10.3.10.222:8000/upload'));
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
                        margin: EdgeInsets.fromLTRB(400, 10, 10, 10),
                        constraints: BoxConstraints(
                            minHeight: 50,
                            minWidth: 50,
                            maxWidth: 1000,
                            maxHeight: 70),
                        decoration: BoxDecoration(
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
                      child:
                          const Icon(Icons.copy, color: Colors.blue, size: 32),
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
                      onPressed: share,
                      icon: Icon(Icons.share, color: Colors.blue, size: 32),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  child: Text(
                    'DOWNLOAD FILE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  style: ButtonStyle(
                    textStyle: MaterialStateProperty.all(
                        const TextStyle(fontSize: 23)),
                    overlayColor: MaterialStateProperty.all(Colors.red),
                    shadowColor: MaterialStateProperty.all(Colors.lightBlue),
                    elevation: MaterialStateProperty.all(15),
                    minimumSize: MaterialStateProperty.all(const Size(200, 80)),
                  ),
                  onPressed: <String>() async {
                    final response = await http
                        .get(Uri.parse('http://10.3.10.222:8000/download'));
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
