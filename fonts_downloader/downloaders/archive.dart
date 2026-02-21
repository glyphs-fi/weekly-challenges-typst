import "dart:io";

import "package:archive/archive_io.dart";
import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../utils.dart";

Future<void> downloadArchivedFonts({
  required http.Client client,
  required Directory fontsDir,
  required Iterable<String> links,
}) async {
  for (final String link in links) {
    // Download the archive file
    final File archiveFile = File(p.join(fontsDir.path, p.basename(link)));
    await downloadFile(client, url: link, destinationPath: archiveFile.path);

    String? nDirname;
    // Extract the archive file into the fonts directory
    await extractFileToDisk(
      archiveFile.path,
      fontsDir.path,
      callback: (ArchiveFile entry) {
        // Record the shortest name; that will be the name of the directory that the files will be extracted to
        if (nDirname == null || entry.name.length < nDirname!.length) {
          nDirname = entry.name;
        }
      },
    );

    // Delete the archive file
    await archiveFile.delete();

    // If a name was recorded, we clean up any potential version numbers from it
    if (nDirname != null) {
      final String dirname = nDirname!;

      // The directory that we just extracted from the archive
      final Directory extractedDir = Directory(p.join(fontsDir.path, dirname));
      // Remove version number from the extracted dir's name
      final String cleanedUpPath = extractedDir.path.replaceFirst(RegExp(r"-[\d.]*?/?$"), "");
      final Directory dirWithCleanedUpName = Directory(cleanedUpPath);

      // If the downloader has already run before
      if (dirWithCleanedUpName.existsSync()) {
        // So we move any potential .gitignore file into the newly extracted directory
        final File gitignoreFile = File(p.join(cleanedUpPath, ".gitignore"));
        if (gitignoreFile.existsSync()) {
          await gitignoreFile.rename(p.join(extractedDir.path, ".gitignore"));
        }

        // Then we delete old directory
        await dirWithCleanedUpName.delete(recursive: true);
        // And we replace it with the newly extracted one
      }

      // Rename the extracted directory with the cleaned up name
      await extractedDir.rename(cleanedUpPath);
    }
  }
}
