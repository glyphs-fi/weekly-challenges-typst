#!/usr/bin/env dart

import "dart:io";

import "package:http/http.dart" as http;
import "package:http/io_client.dart" as http;
import "package:path/path.dart" as p;

import "downloaders/archive.dart";
import "downloaders/direct.dart";
import "downloaders/gitlab.dart";
import "downloaders/google_fonts.dart";
import "input_parsing.dart";

Future<void> main(List<String> args) async {
  final Directory repoRoot = Directory(p.normalize(p.join(Platform.script.toFilePath(), "..", "..")));
  final Directory fontsDir = Directory(p.join(repoRoot.path, "fonts"));

  final entries = await queryFontsFromTypst(repoRoot);

  final http.Client client = http.IOClient(
    HttpClient()..userAgent = "G&A Font Downloader (please continue giving us simple .ttf files)",
  );

  await downloadFromGoogleFonts(
    client: client,
    fontsDir: fontsDir,
    typstFontEntries: entries.filter(on: .gfonts),
  );

  await downloadFromGitLab(
    client: client,
    fontsDir: fontsDir,
    typstFontEntries: entries.filter(on: .gitlab),
  );

  await downloadDirectFonts(
    client: client,
    fontsDir: fontsDir,
    typstFontEntries: entries.filter(on: .url),
  );

  await downloadArchivedFonts(
    client: client,
    fontsDir: fontsDir,
    typstFontEntries: entries.filter(on: .archive),
  );

  client.close();
}
