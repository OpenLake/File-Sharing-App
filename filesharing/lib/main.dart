import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Form Validation Demo';

    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: const MyCustomForm(),
      ),
    );
  }
}

// Create a Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class MyCustomFormState extends State<MyCustomForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  postTest(String Title) async {
    // var requestBody = {
    //
    // };

    http.Response response = await http.post(
      Uri.parse('http://10.3.20.224:5500'),
      // body: json.encode(requestBody),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'grant_type': Title,
      },
      body: jsonEncode(<String, String>{
        'grant_type': Title,
      }),
    );
    if (response.statusCode == 201) {
      // If the server did return a 201 CREATED response,
      // then parse the JSON.
      return print('succeed');
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception.
      throw Exception('Failed to create album.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                postTest(_controller.text);
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processing Data')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

// createAlbum(String title) async {
//   final response = await http.post(
//     Uri.parse('https://192.168.87.169:5500'),
//     headers: <String, String>{
//       'Content-Type': 'application/json; charset=UTF-8',
//     },
//     body: jsonEncode(<String, String>{
//       'title': title,
//     }),
//   );
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
