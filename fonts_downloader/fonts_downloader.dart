#!/usr/bin/env dart

import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "downloaders/archive.dart";
import "downloaders/direct.dart";
import "downloaders/gitlab.dart";
import "downloaders/google_fonts.dart";

final List<String> googleFontsLinks = [
  "https://fonts.googleapis.com/css2?family=STIX+Two+Text:ital,wght@0,400..700;1,400..700",
  "https://fonts.googleapis.com/css2?family=Noto+Sans+TC:wght@400..900",
];

final List<String> gitlabReleasesFontsLinks = [
  "https://gitlab.gnome.org/GNOME/adwaita-fonts",
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

Future<void> main(List<String> args) async {
  final http.Client client = http.Client();

  final Directory fontsDir = Directory(p.normalize(p.join(Platform.script.toFilePath(), "..", "..", "fonts")));

  await downloadFromGoogleFonts(client: client, fontsDir: fontsDir, links: googleFontsLinks);

  await downloadFromGitLab(client: client, fontsDir: fontsDir, links: gitlabReleasesFontsLinks);

  await downloadDirectFonts(client: client, fontsDir: fontsDir, links: directFontsLinks);

  await downloadArchivedFonts(client: client, fontsDir: fontsDir, links: archivedFontsLinks);

  client.close();
}
