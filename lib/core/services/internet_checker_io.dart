import 'dart:io';

Future<bool> checkInternetAccess() async {
  final lookupResult = await InternetAddress.lookup('google.com')
      .timeout(const Duration(seconds: 3));
  return lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
}

