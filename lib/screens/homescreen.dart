import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gemini_ai/utils/toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? pickedImage;
  String mytext = '';
  bool scanning = false;

  final TextEditingController _promptcontroller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=AIzaSyAGvm78vQFVsQwmkFbqfwt0bk-g9Bs8Fig';
  // Request header
  final header = {'Content-Type': 'application/json'};

  // Function to pick image from gallery
  Future<void> getImage(ImageSource ourSource) async {
    final XFile? result = await _imagePicker.pickImage(source: ourSource);

    if (result != null) {
      setState(() {
        pickedImage = result; // Update picked image
      });
    }
  }

  // Function to send image and prompt to Gemini API and get response
  Future<void> getdata(XFile? image, String promptValue) async {
    setState(() {
      scanning = true;
      mytext = '';
    });

    try {
      // Convert image to base64
      final List<int> imageBytes = File(image!.path).readAsBytesSync();
      final String base64File = base64.encode(imageBytes);

      // Construct request data
      final data = {
        "contents": [
          {
            "parts": [
              {"text": promptValue}, // Add prompt text
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64File,
                }
              }
            ]
          }
        ],
      };

      // Send POST request to Gemini API
      final response = await http.post(Uri.parse(apiUrl),
          headers: header, body: jsonEncode(data));

      // Handle API response
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Extracting Output from API Data
        mytext = result['candidates'][0]['content']['parts'][0]['text'];
      } else {
        mytext = 'Response status : ${response.statusCode}';
      }
    } catch (e) {
      Utils().toastmessage(e.toString());
    }

    setState(() {
      scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Google Gemini',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              getImage(ImageSource.gallery);
            },
            icon: const Icon(Icons.photo, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              getImage(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            pickedImage == null
                ? Container(
                    height: 340,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: const Center(
                      child: Text(
                        'No Image Selected',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 340,
                    child: Center(
                      child: Image.file(
                        File(pickedImage!.path),
                        height: 400,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            TextField(
              controller: _promptcontroller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),
                prefixIcon: const Icon(
                  Icons.pending_sharp,
                  color: Colors.black,
                ),
                hintText: 'Enter your prompt here',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                getdata(pickedImage, _promptcontroller.text);
              },
              style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.black)),
              child: const Text(
                'Generate Answer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            scanning
                ? const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: SpinKitThreeBounce(color: Colors.black, size: 20),
                    ),
                  )
                : Text(
                    mytext,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
          ],
        ),
      ),
    );
  }
}
