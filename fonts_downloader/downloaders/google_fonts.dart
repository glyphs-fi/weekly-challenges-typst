import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../input_parsing.dart";
import "../utils.dart";

typedef _GoogleFontFile = ({String family, String style, String weight, Uri url});

Future<void> downloadFromGoogleFonts({
  required http.Client client,
  required Directory fontsDir,
  required List<TypstFontEntry> typstFontEntries,
}) async {
  // Categorise links with "font project" name
  final Map<String, List<Uri>> nameAndLinks = typstFontEntries.toNameUrlsMap();

  // For each "font project", download all the font files into its directory
  for (final MapEntry<String, List<Uri>> entry in nameAndLinks.entries) {
    final String projectName = entry.key;
    final List<Uri> links = entry.value;

    // Extract links to all the font files we need
    final Set<_GoogleFontFile> fontFiles = {};
    for (final Uri link in links) {
      fontFiles.addAll(await _getFileLinksFromGoogleFontsLink(client, link));
    }

    // Create a new empty directory for this "font project"
    final Directory projectDir = await createEmptyFontDir(fontsDir, directoryName: projectName);

    // Actually download all the font files for this "font project"
    for (final fontFileDef in fontFiles) {
      final Uri url = fontFileDef.url;
      final String filename = "${fontFileDef.family} [${fontFileDef.weight} ${fontFileDef.style}]${p.extension(url.path)}";

      await downloadFile(client, url: url, destinationPath: p.join(projectDir.path, filename));
    }
  }
}

final RegExp _familyExtractor = RegExp(r"font-family:\s*(.*);", caseSensitive: false);
final RegExp _styleExtractor = RegExp(r"font-style:\s*(.*);", caseSensitive: false);
final RegExp _weightExtractor = RegExp(r"font-weight:\s*(.*);", caseSensitive: false);
final RegExp _urlExtractor = RegExp(r"url\((.*?)\)", caseSensitive: false);

Future<List<_GoogleFontFile>> _getFileLinksFromGoogleFontsLink(http.Client client, Uri url) async {
  final String cssContent = await client.read(url);
  final List<String> fontFaceBlocks = cssContent
      .split(RegExp(r"(?:/\*.*\*/\s*)?@font-face\s*"))
      .where((str) => str.trim().isNotEmpty)
      .toList(growable: false);

  final List<_GoogleFontFile> results = [];
  for (final String fontFace in fontFaceBlocks) {
    final String family = _familyExtractor.firstMatch(fontFace)!.group(1)!.trimQuotes();
    final String style = _styleExtractor.firstMatch(fontFace)!.group(1)!;
    final String weight = _weightExtractor.firstMatch(fontFace)!.group(1)!;
    final String url = _urlExtractor.firstMatch(fontFace)!.group(1)!;
    final Uri uri = Uri.parse(url);
    results.add((family: family, style: style, weight: weight, url: uri));
  }

  return results;
}
