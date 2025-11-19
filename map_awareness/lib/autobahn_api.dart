import 'package:flutter_curl/flutter_curl.dart';

//Test method
Future<void> test()
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
      url: "https://verkehr.autobahn.de/o/autobahn/A1/services/roadworks",
      headers: {

      },

      //body: RequestBody.form({"identifier": "Uk9BRFdPUktTX19tZG0uc2hfXzYzMTU="})
      )
  );

  /*
  print(res);
  res.headers.forEach((key, value) {
    print("$key: $value");
    });
  */

  //testing print statement
  //prints entire body of the autobahnAPI as text 
  print(res.text());
}