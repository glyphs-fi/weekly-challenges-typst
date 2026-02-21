import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;

import "archive.dart";

Future<void> downloadFromGitLab({
  required http.Client client,
  required Directory fontsDir,
  required List<String> links,
}) async {
  final Set<String> archiveLinks = {};
  for (final String link in links) {
    // Extract data from link
    final Uri uri = Uri.parse(link);
    final String orgName = uri.pathSegments[0];
    final String projectName = uri.pathSegments[1];

    // Create link for the API call to the GitLab API to get information about the latest release
    final Uri apiUri = Uri.parse("https://${uri.authority}/api/v4/projects/$orgName%2F$projectName/releases/permalink/latest");

    // Actually do the API call
    final String jsonString = await client.read(apiUri);

    // Decode the information from the API call
    final _Release gitlabRelease = _Release.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

    // Find the link to download the release's tar.gz
    // (Because getting the zip somehow results in files with very broken permissions..?)
    final _Source zipSource = gitlabRelease.assets.sources.firstWhere((element) => element.format == "tar.gz");

    // Record the archive link for later downloading ↓
    archiveLinks.add(zipSource.url);
  }

  // This is later downloading ↑
  await downloadArchivedFonts(client: client, fontsDir: fontsDir, links: archiveLinks);
}

// The API call's json is decoded into these data classes:
class _Release {
  final _Assets assets;

  const _Release(this.assets);

  factory _Release.fromJson(Map<String, dynamic> json) => _Release(_Assets.fromJson(json["assets"] as Map<String, dynamic>));
}

class _Assets {
  final List<_Source> sources;

  const _Assets(this.sources);

  factory _Assets.fromJson(Map<String, dynamic> json) => _Assets(
    (json["sources"] as List<dynamic>).map((e) => _Source.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class _Source {
  final String format;
  final String url;

  const _Source(this.format, this.url);

  factory _Source.fromJson(Map<String, dynamic> json) => _Source(json["format"] as String, json["url"] as String);
}
