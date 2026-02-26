import "dart:convert";
import "dart:io";

import "package:glob/glob.dart";

Future<List<TypstFontEntry>> queryFontsFromTypst(Directory repoRoot) async {
  final ProcessResult typstQueryResult = await Process.run("typst", [
    "query",
    "global-config.typ",
    "--one",
    "--field",
    "value",
    "<fonts-download-json>",
  ], workingDirectory: repoRoot.path);
  final String jsonString = typstQueryResult.stdout.toString();
  final jsonDecoded = jsonDecode(jsonString) as List<Object?>;
  final List<TypstFontEntry> entries = jsonDecoded
      .map((Object? e) => TypstFontEntry.fromJson(e! as Map<String, Object?>))
      .toList(growable: false);
  return entries;
}

enum DownloadType { gitlab, url, archive, gfonts }

class TypstFontEntry {
  final String name;
  final DownloadType downloadType;
  final Uri url;
  final Set<Glob>? keep;

  const TypstFontEntry._(this.name, this.downloadType, this.url, this.keep);

  TypstFontEntry._strings(this.name, String src, String url, List<String>? keep)
    : downloadType = DownloadType.values.asNameMap()[src]!,
      url = Uri.parse(url),
      keep = keep?.map((e) => Glob(e, caseSensitive: false)).toSet();

  factory TypstFontEntry.fromJson(Map<String, Object?> json) => TypstFontEntry._strings(
    json["name"]! as String,
    json["src"]! as String,
    json["url"]! as String,
    (json["keep"] as List<dynamic>?)?.map((e) => e as String).toList(growable: false),
  );

  TypstFontEntry copyWith({
    String? name,
    DownloadType? downloadType,
    Uri? url,
    Set<Glob>? keep,
  }) {
    return TypstFontEntry._(
      name ?? this.name,
      downloadType ?? this.downloadType,
      url ?? this.url,
      keep ?? this.keep,
    );
  }
}

extension TypstFontEntryExtensions on List<TypstFontEntry> {
  List<TypstFontEntry> filter({required DownloadType on}) {
    return where((element) => element.downloadType == on).toList(growable: false);
  }

  Map<String, List<Uri>> toNameUrlsMap() {
    final Map<String, List<Uri>> nameAndLinks = {};
    for (final TypstFontEntry typstFontEntry in this) {
      final String name;
      final partExtractor = RegExp(r"(.*) Pa?r?t?\s*(\d+)", caseSensitive: false);
      final RegExpMatch? partMatch = partExtractor.firstMatch(typstFontEntry.name);
      if (partMatch != null) {
        name = partMatch[1]!;
      } else if (typstFontEntry.name.contains(RegExp("noto", caseSensitive: false))) {
        // Put all Noto Music/Sans/Serif fonts together
        name = "Noto ${typstFontEntry.name.split(RegExp(r"\s"))[1]}";
      } else {
        name = typstFontEntry.name;
      }
      nameAndLinks[name] = [...?nameAndLinks[name], typstFontEntry.url];
    }
    return nameAndLinks;
  }
}
