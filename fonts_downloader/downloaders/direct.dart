import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../input_parsing.dart";
import "../utils.dart";

Future<void> downloadDirectFonts({
  required http.Client client,
  required Directory fontsDir,
  required List<TypstFontEntry> typstFontEntries,
}) async {
  // Categorise links with "font project" name
  final Map<String, List<Uri>> nameAndLinks = typstFontEntries.toNameUrlsMap();

  // Loop over all the fonts
  for (final MapEntry<String, List<Uri>> entry in nameAndLinks.entries) {
    final String directoryName = entry.key;
    final List<Uri> links = entry.value;

    // Create directory for the font file(s)
    final Directory fontDir = await createEmptyFontDir(fontsDir, directoryName: directoryName);

    // Download the font file(s) into the directory
    for (final Uri link in links) {
      await downloadFile(client, url: link, destinationPath: p.join(fontDir.path, p.basename(link.path)));
    }
  }
}
