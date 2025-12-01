import 'dart:convert';

import 'package:flutter_curl/flutter_curl.dart';

//Test method
Future<void> testMap()
async {

  // Initialize client
  Client client = Client(
      verbose: true,
      interceptors: [
        // HTTPCaching(),
      ],
    );
  await client.init();

  // Send request //point=53.084,8.798&point=53.538,10.033 coordinates from bremen to hamburg
  final res = await client.send(Request(
      method: "GET",
      url: "https://graphhopper.com/api/1/route?point=53.084,8.798&point=53.538,10.033&profile=car&locale=de&calc_points=false&key=95c5067c-b1d5-461f-823a-8ae69a6f6997",
      headers: {

      },
    )

  );
  //print(res);
  
  //transforms list of int into Map
  if (res.statusCode == 200) {
    String jsonString = res.text();
    Map<String, dynamic> data = jsonDecode(jsonString);
    //print(data);
  }
  else {

  //print("Request failed with status: ${res.statusCode}");
  }
}