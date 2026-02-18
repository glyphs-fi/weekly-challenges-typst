# weekly-challenges-typst

does the thing but in typst this time

# Usage

set up an `images` directory with the same format as `sample_images` (notably, `images/pfp` holds user profile pictures). then:

## Manual use

navigate to the "user area" in `main.typ` and follow the comments. then just compile it

## Command-line use

when compiling pass all the parameters as flags (done by including `--input key=val` for each key-val pair). the most important parameter is `to-generate` which accepts a single output type (like `glyph-announcement`) or a list (like `(glyph-announcement, ambigram-announcement)`) and determines what we actually output. if you look further down in `main.typ` you can figure out which output types need which parameters, but basically most need `current-week`, hall of fame images need the name of the winner, announcements and showcases need their respective glyph/ambi (and can optionally be passed a date, which is otherwise determined automatically).

also, `image-dir` can be used to control where images are searched for. if nothing is passed then an `images` directory will be assumed to exist in the project root.