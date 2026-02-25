import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../utils.dart";

typedef _GoogleFontFile = ({String family, String style, String weight, String url});

Future<void> downloadFromGoogleFonts({
  required http.Client client,
  required Directory fontsDir,
  required List<String> links,
}) async {
  // Collect links to all the font files we need
  final Set<_GoogleFontFile> fontFiles = {};
  for (final String link in links) {
    fontFiles.addAll(await _getFileLinksFromGoogleFontsLink(client, link));
  }

  // Create new empty directories for each font family
  final Set<String> fontFamilies = fontFiles.map((e) => e.family).toSet();
  for (final String fontFamily in fontFamilies) {
    await createEmptyFontDir(fontsDir, directoryName: fontFamily);
  }

  // Download all the font files into the family directory that was created above, with a nice filename
  for (final fontFileDef in fontFiles) {
    final Directory fontDir = Directory(p.join(fontsDir.path, fontFileDef.family));
    final String filename = "${fontFileDef.family}_${fontFileDef.weight}_${fontFileDef.style}${p.extension(fontFileDef.url)}";

    await downloadFile(client, url: fontFileDef.url, destinationPath: p.join(fontDir.path, filename));
  }
}

final RegExp _familyExtractor = RegExp(r"font-family:\s*(.*);", caseSensitive: false);
final RegExp _styleExtractor = RegExp(r"font-style:\s*(.*);", caseSensitive: false);
final RegExp _weightExtractor = RegExp(r"font-weight:\s*(.*);", caseSensitive: false);
final RegExp _urlExtractor = RegExp(r"url\((.*?)\)", caseSensitive: false);

Future<List<_GoogleFontFile>> _getFileLinksFromGoogleFontsLink(http.Client client, String link) async {
  final Uri uri = Uri.parse(link);
  final String cssContent = await client.read(uri);
  final Iterable<String> fontFaceBlocks = cssContent.split("@font-face").where((str) => str.trim().isNotEmpty);

  final List<_GoogleFontFile> results = [];
  for (final String fontFace in fontFaceBlocks) {
    final String family = _familyExtractor.firstMatch(fontFace)!.group(1)!.trimQuotes();
    final String style = _styleExtractor.firstMatch(fontFace)!.group(1)!;
    final String weight = _weightExtractor.firstMatch(fontFace)!.group(1)!;
    final String url = _urlExtractor.firstMatch(fontFace)!.group(1)!;
    results.add((family: family, style: style, weight: weight, url: url));
  }

  return results;
}
