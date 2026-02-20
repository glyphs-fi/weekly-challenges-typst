#!/usr/bin/env dart

import "dart:io";
import "dart:typed_data";

import "package:archive/archive_io.dart";
import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

final List<String> googleFontsLinks = [
  "https://fonts.googleapis.com/css2?family=STIX+Two+Text:ital,wght@0,400..700;1,400..700",
  "https://fonts.googleapis.com/css2?family=Noto+Sans+TC:wght@400..900",
];

//<Directory Name, Font Links>
final Map<String, List<String>> directFontsLinks = {
  "Plangothic": [
    "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/latest/download/PlangothicP1-Regular.ttf",
    "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/latest/download/PlangothicP2-Regular.ttf",
  ],
};

final List<String> archivedFontsLinks = [
  "https://ftp.gnu.org/gnu/freefont/freefont-otf-20120503.tar.gz" /* For FreeSerif. No need for version checking, because we are not expecting a new version ever. */,
];

typedef FontFileDefinition = ({String family, String style, String weight, String url});

final http.Client client = http.Client();

Future<void> main(List<String> args) async {
  final Directory fontsDir = Directory(p.dirname(Platform.script.toFilePath()));
  final Set<FontFileDefinition> fontFiles = {};

  for (final String link in googleFontsLinks) {
    fontFiles.addAll(await getFileLinksFromGoogleFontsLink(link));
  }

  for (final fontFileDef in fontFiles) {
    final Uri uri = Uri.parse(fontFileDef.url);

    final Directory fontDir = Directory(p.join(fontsDir.path, fontFileDef.family))..createSync();
    final String filename = "${fontFileDef.family}_${fontFileDef.weight}_${fontFileDef.style}${p.extension(fontFileDef.url)}";

    final File fontFile = File(p.join(fontDir.path, filename));
    final Uint8List bytes = await client.readBytes(uri);
    await fontFile.writeAsBytes(bytes);
  }

  for (final MapEntry<String, List<String>> entry in directFontsLinks.entries) {
    final String directoryName = entry.key;
    final List<String> links = entry.value;

    final Directory fontDir = Directory(p.join(fontsDir.path, directoryName))..createSync();

    for (final String link in links) {
      final Uri uri = Uri.parse(link);
      final File fontFile = File(p.join(fontDir.path, p.basename(link)));
      final Uint8List bytes = await client.readBytes(uri);
      await fontFile.writeAsBytes(bytes);
    }
  }

  for (final String link in archivedFontsLinks) {
    final Uri uri = Uri.parse(link);
    final Uint8List bytes = await client.readBytes(uri);
    final File archiveFile = File(p.join(fontsDir.path, p.basename(link)));
    await archiveFile.writeAsBytes(bytes);
    await extractFileToDisk(archiveFile.path, ".");
    await archiveFile.delete();
  }

  client.close();

  print(fontFiles.join("\n"));
}

Future<List<FontFileDefinition>> getFileLinksFromGoogleFontsLink(String link) async {
  final RegExp familyExtractor = RegExp(r"font-family:\s*(.*);", caseSensitive: false);
  final RegExp styleExtractor = RegExp(r"font-style:\s*(.*);", caseSensitive: false);
  final RegExp weightExtractor = RegExp(r"font-weight:\s*(.*);", caseSensitive: false);
  final RegExp urlExtractor = RegExp(r"url\((.*?)\)", caseSensitive: false);

  final Uri uri = Uri.parse(link);
  final String cssFile = await client.read(uri);
  final fontFaces = cssFile.split("@font-face").where((str) => str.trim().isNotEmpty);

  final List<FontFileDefinition> results = [];
  for (final String fontFace in fontFaces) {
    final String family = familyExtractor.firstMatch(fontFace)!.group(1)!.trimQuotes();
    final String style = styleExtractor.firstMatch(fontFace)!.group(1)!;
    final String weight = weightExtractor.firstMatch(fontFace)!.group(1)!;
    final String url = urlExtractor.firstMatch(fontFace)!.group(1)!;
    results.add((family: family, style: style, weight: weight, url: url));
  }

  return results;
}

extension StringExtensions on String {
  String trimQuotes() {
    final RegExp unQuoter = RegExp(r"""^(["'])(.*)\1$""", multiLine: true);
    return unQuoter.firstMatch(this)!.group(2)!;
  }
}
