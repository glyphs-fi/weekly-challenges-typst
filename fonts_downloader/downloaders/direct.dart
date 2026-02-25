import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../utils.dart";

Future<void> downloadDirectFonts({
  required http.Client client,
  required Directory fontsDir,
  required Map<String, List<String>> links,
}) async {
  // Loop over all the fonts
  for (final MapEntry<String, List<String>> entry in links.entries) {
    final String directoryName = entry.key;
    final List<String> links = entry.value;

    // Create directory for the font file(s)
    final Directory fontDir = await createEmptyFontDir(fontsDir, directoryName: directoryName);

    // Download the font file(s) into the directory
    for (final String link in links) {
      await downloadFile(client, url: link, destinationPath: p.join(fontDir.path, p.basename(link)));
    }
  }
}
