import "dart:io";
import "dart:typed_data";

import "package:http/http.dart" as http;

extension StringExtensions on String {
  String trimQuotes() {
    final RegExp unQuoter = RegExp(r"""^(["'])(.*)\1$""", multiLine: true);
    return unQuoter.firstMatch(this)!.group(2)!;
  }
}

Future<void> downloadFile(http.Client client, {required String url, required String destinationPath}) async {
  // Download content into memory
  final Uri uri = Uri.parse(url);
  final Uint8List bytes = await client.readBytes(uri);

  // Save content to file
  final File fontFile = File(destinationPath);
  await fontFile.writeAsBytes(bytes);
}
