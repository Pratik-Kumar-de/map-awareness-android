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

  // Send request
  final res = await client.send(Request(
      method: "GET",
      url: "",
      headers: {

      },
    )
  );
  //transforms list of int into Map
  if (res.statusCode == 200) {
    String jsonString = res.text();
    Map<String, dynamic> data = jsonDecode(jsonString);
    print(data);
  }
}