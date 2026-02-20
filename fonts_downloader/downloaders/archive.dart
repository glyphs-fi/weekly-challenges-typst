import "dart:io";

import "package:archive/archive_io.dart";
import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../utils.dart";

Future<void> downloadArchivedFonts({
  required http.Client client,
  required Directory fontsDir,
  required List<String> links,
}) async {
  for (final String link in links) {
    // Download the archive file
    final File archiveFile = File(p.join(fontsDir.path, p.basename(link)));
    await downloadFile(client, url: link, destinationPath: archiveFile.path);

    // Extract the archive file into the fonts directory
    await extractFileToDisk(archiveFile.path, fontsDir.path);

    // Delete the archive file
    await archiveFile.delete();
  }
}
