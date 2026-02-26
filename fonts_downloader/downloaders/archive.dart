import "dart:io";

import "package:archive/archive_io.dart";
import "package:glob/glob.dart";
import "package:glob/list_local_fs.dart";
import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../input_parsing.dart";
import "../utils.dart";

Future<void> downloadArchivedFonts({
  required http.Client client,
  required Directory fontsDir,
  required List<TypstFontEntry> typstFontEntries,
}) async {
  for (final TypstFontEntry typstFontEntry in typstFontEntries) {
    final Directory fontDir = await createEmptyFontDir(fontsDir, directoryName: typstFontEntry.name);

    // Download the archive file
    final File archiveFile = File(p.join(fontDir.path, p.basename(typstFontEntry.url.path)));
    await downloadFile(client, url: typstFontEntry.url, destinationPath: archiveFile.path);

    // Extract the archive file into the fonts directory
    await extractFileToDisk(archiveFile.path, fontDir.path);
    print("Extracted ${archiveFile.path} to ${fontDir.path}");

    // Delete the archive file
    await archiveFile.delete();

    final List<FileSystemEntity> archiveContents = fontDir.listSync();
    if (archiveContents.length == 1) {
      final FileSystemEntity entity = archiveContents.first;
      if (entity is Directory) {
        // This was a nice archive and (presumedly) had a directory in the root that contains everything
        final Directory rootDir = entity;

        // Get list of things to keep
        final Set<Glob>? keepGlobs = typstFontEntry.keep;
        if (keepGlobs == null) {
          throw Exception(
            'Font "${typstFontEntry.name}" is of type "${typstFontEntry.downloadType.name}" but does not have the necessary "keep" defined.',
          );
        }

        // Pull out the things to keep into the font directory
        for (final Glob keep in keepGlobs) {
          final List<FileSystemEntity> items = keep.listSync(root: rootDir.path);
          for (final FileSystemEntity entity in items) {
            await entity.rename(p.join(fontDir.path, p.basename(entity.path))); //flattens the archive
            // await entity.rename(p.join(fontDir.path, p.relative(entity.path, from: rootDir.path))); //does not flatten
          }
        }

        // Delete the directory with the remaining files that we don't want to keep
        await rootDir.delete(recursive: true);
      } else if (entity is File) {
        // This archive contained just one file at the root, for some reason
        // This doesn't actually need any more handling than has already happened
        // The file has been extracted into the correct location already
      }
    } else {
      // This was an annoying archive and just had everything dumped in the archive root

      // Get list of things to keep
      final Set<Glob>? keepGlobs = typstFontEntry.keep;
      if (keepGlobs == null) {
        throw Exception(
          'Font "${typstFontEntry.name}" is of type "${typstFontEntry.downloadType.name}" but does not have the necessary "keep" defined.',
        );
      }

      // Get all files in the directory
      final Set<String> allFiles = fontDir.listSync(recursive: true).map((e) => p.canonicalize(e.path)).toSet();

      // Find out which files to keep
      final Set<String> filesToKeep = keepGlobs
          .expand((keep) => keep.listSync(root: fontDir.path))
          .map((e) => p.canonicalize(e.path))
          .toSet();

      // Find out which files to delete
      final Set<String> diff = allFiles.difference(filesToKeep);

      // Delete those files
      for (final String entityPath in diff) {
        final FileSystemEntityType type = FileSystemEntity.typeSync(entityPath);
        switch (type) {
          case FileSystemEntityType.directory:
            await Directory(entityPath).delete(recursive: true);
          case FileSystemEntityType.file:
            await File(entityPath).delete();
          case .notFound:
            // File was (probably) inside a directory that was already deleted
            break;
          // I am okay with treating "All Other" ones like this
          // ignore: no_default_cases
          default:
            print("Unexpected type $type at path $entityPath");
        }
      }
    }
  }
}
