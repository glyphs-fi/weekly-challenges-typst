# Fonts Downloader

This directory contains a Dart Script which automatically downloads
the latest versions of all the fonts we need into the `../fonts` directory.

## Adding fonts

To add new fonts to the downloader, open `fonts_downloader.dart` and find
the `List`s and `Map`s at the top.  
You can add new links to those and the re-run the script to download them.

If the download came with more than we need, please copy a `.gitignore` file
from one of the other font directories and modify it to ignore everything,
except the exact files we need (plus the license).

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
