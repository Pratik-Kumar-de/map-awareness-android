import 'dart:convert';
import 'package:flutter_curl/flutter_curl.dart';

//uses the Graphopper API to decode an adress into coordinates

//return needs to be changed to coordinates
//unfinished
Future<void> geocoding(String adress)
async {

  // Initialize client
  Client client = Client(
      verbose: true,
      interceptors: [
        // HTTPCaching(),
      ],
    );
  await client.init();

  // Send request
  final res = await client.send(Request(
      method: "GET",
      url: "", //https://graphhopper.com/api/1/geocode?q=berlin&locale=de&key=api_key,
      headers: {

      },
    )
  );
  //print(res.text());
  
  //transforms list of int into Map
  if (res.statusCode == 200) {
    String jsonString = res.text();
    Map<String, dynamic> data = jsonDecode(jsonString);
    print(data);
    }
  }