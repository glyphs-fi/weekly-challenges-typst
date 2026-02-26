# Fonts

This directory contains all the font files that the Typst script requires.

To test whether there are any missing fonts, run this command in the root of the project:

```bash
typst compile test.typ --ignore-system-fonts --font-path ./fonts/
```

If there are any missing fonts, Typst will log an error about it.
