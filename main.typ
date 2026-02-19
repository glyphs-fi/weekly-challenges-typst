#import "showcase.typ" as showcase
#import "announcement.typ" as announcement
#import "hall-of-fame.typ" as hall-of-fame

#let current-date = datetime.today()
//page exactly as big as its contents
#set page(width: auto, height: auto, margin: 0pt)

//to prevent automatic spacing between `block`s
#set par(spacing: 0pt)

//we always place objects relative to the topleft of their container
#set place(top + left)



/////////////////////USER AREA////////////////////////


//comment or uncomment lines to change what's generated
//use /* ... */ for a multiline comment
#let to-generate = (
  /*
  "glyph-announcement",
  "glyph-showcase",
  "glyph-winners",
  "ambigram-announcement",
  "ambigram-showcase",
  "ambigram-winners",
  */
)

////ALWAYS CHANGE////

//this week's (glyph) week number (determines the colour cycle)
#let current-week = 0



////GLYPH CHALLENGE////

//upcoming week's glyph
#let announcement-glyph = ""

//outgoing week's glyph
#let showcase-glyph = ""

//winner display names
#let glyph-winner-first = ""
#let glyph-winner-second = ""
#let glyph-winner-third = ""



////AMBIGRAM CHALLENGE////

//upcoming week's ambigram
#let announcement-ambi = ""

//outgoing week's ambigram
#let showcase-ambi = ""

//winner display names
#let ambi-winner-first = ""
#let ambi-winner-second = ""
#let ambi-winner-third = ""



////ADVANCED SETTINGS////

//these have default values, but you can override them by uncommenting and editing the relevant line (no need to comment the default value line)

//start/end date of upcoming challenges
#let announcement-start-date = datetime.today()
//#let announcement-start-date = datetime(year: 2069, month: 4, day: 20)
#let announcement-end-date = announcement-start-date + duration(days: 7)
//#let announcement-start-date = datetime(year: 2069, month: 4, day: 27)

//start date of outgoing challenges
#let showcase-start-date = current-date - duration(days: 7)
//#let showcase-date = datetime(year: 2069, month: 4, day: 13)
#let showcase-end-date = showcase-start-date + duration(days: 7)
//#let announcement-start-date = datetime(year: 2069, month: 4, day: 20)

//directory to search for images
#let image-dir = "images"


//////////////////END OF USER AREA////////////////////


//helper functions

//prioritise values from the command line
#let cmd-line-override = (key, val, fn: x => x) => {
  let cmd-line-val = sys.inputs.at(key, default: none)
  if cmd-line-val != none {
    fn(cmd-line-val)
  } else {
    val
  }
}

//lmao this is the only way to parse a string into a date
#let parse-date = x => {
  toml(bytes("date = " + x)).date
}

//oh god the copypaste
//the strings specify the names you need to pass on the command line, but they're just the same as the variable names
#let to-generate = cmd-line-override("to-generate", to-generate, fn: x => x.split(" "))
#let current-week = cmd-line-override("current-week", current-week, fn: eval)
#let announcement-start-date = cmd-line-override("announcement-start-date", announcement-start-date, fn: parse-date)
#let announcement-end-date = cmd-line-override(
  "announcement-end-date",
  if "announcement-start-date" in sys.inputs.keys() {
    //if a start date is specified on the command line, default to one week after that
    announcement-start-date + duration(days: 7)
  } else {
    announcement-end-date
  },
  fn: parse-date,
)
#let showcase-start-date = cmd-line-override("showcase-start-date", showcase-start-date, fn: parse-date)
#let showcase-end-date = cmd-line-override(
  "showcase-end-date",
  if "showcase-start-date" in sys.inputs.keys() {
    //if a start date is specified on the command line, default to one week after that
    showcase-start-date + duration(days: 7)
  } else {
    showcase-end-date
  },
  fn: parse-date,
)
#let image-dir = cmd-line-override("image-dir", image-dir)

#let announcement-glyph = cmd-line-override("announcement-glyph", announcement-glyph)
#let showcase-glyph = cmd-line-override("showcase-glyph", showcase-glyph)
#let glyph-winner-first = cmd-line-override("glyph-winner-first", glyph-winner-first)
#let glyph-winner-second = cmd-line-override("glyph-winner-second", glyph-winner-second)
#let glyph-winner-third = cmd-line-override("glyph-winner-third", glyph-winner-third)

#let announcement-ambi = cmd-line-override("announcement-ambi", announcement-ambi)
#let showcase-ambi = cmd-line-override("showcase-ambi", showcase-ambi)
#let ambi-winner-first = cmd-line-override("ambi-winner-first", ambi-winner-first)
#let ambi-winner-second = cmd-line-override("ambi-winner-second", ambi-winner-second)
#let ambi-winner-third = cmd-line-override("ambi-winner-third", ambi-winner-third)


//if "winners" is specified, generate all three subtypes
#let pos = none
#while (
  {
    pos = to-generate.position(x => x.ends-with("winners"))
    pos
  }
    != none
) {
  let val = to-generate.remove(pos)
  to-generate.insert(pos, val.replace("winners", "third"))
  to-generate.insert(pos, val.replace("winners", "second"))
  to-generate.insert(pos, val.replace("winners", "first"))
}


//oh god the copypaste part 2
#for type in to-generate {
  (
    if type == "glyph-announcement" {
      announcement.generate-glyph-announcement(
        announcement-glyph,
        current-week,
        announcement-start-date,
        announcement-end-date,
      )
    } else if type == "glyph-showcase" {
      showcase.generate-glyph-showcase(
        showcase-glyph,
        current-week - 1,
        showcase-start-date,
        showcase-end-date,
        image-dir,
      )
    } else if type == "glyph-first" {
      hall-of-fame.generate-glyph-winner-display(current-week - 2, glyph-winner-first, 1, image-dir)
    } else if type == "glyph-second" {
      hall-of-fame.generate-glyph-winner-display(current-week - 2, glyph-winner-second, 2, image-dir)
    } else if type == "glyph-third" {
      hall-of-fame.generate-glyph-winner-display(current-week - 2, glyph-winner-third, 3, image-dir)
    } else if type == "ambigram-announcement" {
      announcement.generate-ambi-announcement(announcement-ambi, announcement-start-date, announcement-end-date)
    } else if type == "ambigram-showcase" {
      showcase.generate-ambi-showcase(showcase-ambi, showcase-start-date, showcase-end-date, image-dir)
    } else if type == "ambigram-first" {
      hall-of-fame.generate-ambi-winner-display(current-week - 2, ambi-winner-first, 1, image-dir)
    } else if type == "ambigram-second" {
      hall-of-fame.generate-ambi-winner-display(current-week - 2, ambi-winner-second, 2, image-dir)
    } else if type == "ambigram-third" {
      hall-of-fame.generate-ambi-winner-display(current-week - 2, ambi-winner-third, 3, image-dir)
    } else {
      panic("invalid output type in `to-generate`")
    },
  )
}.join(pagebreak())
