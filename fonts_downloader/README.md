# Fonts Downloader

This directory contains a Dart Script which automatically downloads
the latest versions of all the fonts we need into the [`../fonts`](../fonts) directory.

## Adding fonts

To add new fonts to the downloader, edit [`global-config.typ`](../global-config.typ).
You can add new fonts with links there and then re-run this script to download them.

If the download came with more than we need, please fill in the `keep` option
with globs that list exactly the files we need to keep.
Please also include the license files there.

## Running

The script will automatically run every once in a while, through GitHub Actions,
to get any potential new versions of fonts.

To run this script yourself, first install the Dart SDK,
change your working directory to this directory, and then run this command
to download the packages that the script uses:

```bash
dart pub get
```

From then on, you can run either of these two commands to execute the script:

```bash
dart run fonts_downloader.dart
./fonts_downloader.dart
```
