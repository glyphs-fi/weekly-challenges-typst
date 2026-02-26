import "dart:io";
import "dart:typed_data";

import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

extension StringExtensions on String {
  String trimQuotes() {
    final RegExp unQuoter = RegExp(r"""^(["'])(.*)\1$""", multiLine: true);
    return unQuoter.firstMatch(this)!.group(2)!;
  }
}

Future<Directory> createEmptyFontDir(Directory fontsDir, {required String directoryName}) async {
  final Directory fontDir = Directory(p.join(fontsDir.path, directoryName));
  // Clear out the directory if it already exists, so that no files will be in it at the start.
  // This allows for crashing when downloading any files that already exist, to ensure that nothing is silently overwritten.
  if (fontDir.existsSync()) {
    await fontDir.delete(recursive: true);
  }
  await fontDir.create();
  return fontDir;
}

Future<void> downloadFile(http.Client client, {required Uri url, required String destinationPath}) async {
  // Download content into memory
  final Uint8List bytes = await client.readBytes(url);
  print("Downloaded $url to $destinationPath");

  // Save content to file
  final File fontFile = File(destinationPath);
  if (fontFile.existsSync()) {
    throw PathExistsException(fontFile.path, const OSError("This file has already been downloaded"));
  }
  await fontFile.writeAsBytes(bytes);
}
