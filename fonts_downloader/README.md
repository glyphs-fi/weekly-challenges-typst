# Fonts Downloader

This directory contains a Dart Script which automatically downloads
the latest versions of all the fonts we need into the `../fonts` directory.

To run it, first install the Dart SDK, change your working directory to this directory,
and then run this command to download the packages that the script uses:

```bash
dart pub get
```

From then on, you can run either of these two commands to execute the script:

```bash
dart run fonts_downloader.dart
./fonts_downloader.dart
```
