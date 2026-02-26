//used for static elements like banner title and background pangrams
#let main-latin-font = "Stix Two Text"

//regex that matches the given unicode scripts (and the Common script)
#let scripts-regex(..names, include-common: true) = {
  regex({
    "["
    for name in (if include-common { ("Common",) } + names.pos()).dedup() {
      "\p{"
      name
      "}"
    }
    "]"
  })
}

//vertical scripts that we support (in a basic way, not suitable for text that might line break)
#let vertical-scripts = ("Mongolian", "Phags Pa")
#let vertical-scripts-regex = scripts-regex(..vertical-scripts, include-common: false)
#let has-vertical-script = str => str.match(vertical-scripts-regex) != none

//all the info about the fonts we're using; used to generate multiple lists. the final format of this will be a list of dicts with keys `name`, `src`, `covers`.
#let fonts-info = {
  /*
  first, manually entered info. the general format here is (script, font-list, script, font-list, ...). in a font list, each font is specified by either just a string (its name) or a dict (with keys `name` and `src`). `src` is itself either a string OR a list (can be read like a rust enum; first entry (a string) specifies the type, further entries specifies additional information if that is needed) OR a list of lists, each of which is of the previously mentioned format (for multiple sources).

  specifically, the src types are:
   * "gfonts" (google fonts; url will be inferred from family name. optionally a second string can be given which specifies the family name that should be used for the url, just in case this is different from the name we refer to it by)
   * "gitlab" (second string is a full url, since gitlab can be self-hosted so we can't assume the domain. optionally, a list of strings each of which is a path (possibly including globs) can be provided as a third argument, which specifies what we want to keep from the download
   * "url" (second string is url to a direct download. a list of paths can also be given as above).
   * "proxy" (i couldn't think of a better name for this option; it means that instead of specifying a source for this font, we specify another font name whose source should be used instead. the motivating example is Source Han Sans; it's distributed as a set of `.ttc` files, which are font "collections" that contain multiple fonts, so that multiple font names share the same source).

  if we use the same font multiple times in the list, we don't need to specify the src every time (hence why we can just give a string). at least one occurrence of a font should have a src specified
  */
  let fonts-info = (
    //the following comments use [] to identify blocks and {} to identify scripts
    //TODO: there are some fonts we could rename here if https://github.com/typst/typst/issues/7468 is fixed
    "Common",
    (
      (name: "Noto Sans Symbols", src: "gfonts"), //[Alchemical Symbols], [Enclosed Alphanumerics], some [Miscellaneous Symbols]
      (name: "Noto Sans Symbols 2", src: "gfonts"), //[Yijing Hexagram Symbols], lots of numerals, [Mahjong Tiles], [Chess Symbols], many more things
      (
        name: "Twitter Color Emoji",
        src: (
          "archive",
          "https://github.com/13rac1/twemoji-color-font/releases/download/v15.1.0/TwitterColorEmoji-SVGinOT-15.1.0.zip",
          ("LICENSE*", "*.ttf"),
        ),
      ), //[Miscellaneous Symbols and Pictographs], [Emoticons], [Supplemental Symbols and Pictographs], [Symbols and Pictographs Extended-A], wow unicode could really come up with better names
      (name: "Noto Music", src: "gfonts"), //[Byzantine Musical Symbols], [Musical Symbols], [Ancient Greek Musical Notation]
      (name: "Noto Sans Math", src: "gfonts"), //[Arrows], [Mathematical Operators], [Geometric Shapes], [Miscellaneous Mathematical Symbols-{A,B}], [Supplemental Arrows-{A,B}], [Mathematical Alphanumeric Symbols], [Arabic Mathematical Alphabetic Symbols]
    ), //note that every other font in the list is also used for {Common} chars, so anything not supported by the above may be supported by something below
    "Latin",
    (
      (name: "STIX Two Text", src: "gfonts"), //all of [Basic Latin], [Latin Extended-A]; basic IPA; some misc Latin
      (name: "Noto Serif", src: "gfonts"), //all of [Latin Extended-{B,C,E,F}], [Phonetic Extensions{, Supplements}]; most of [Latin Extended-{D,G}]
      (
        name: "FreeSerif",
        src: (
          "archive",
          "https://ftp.gnu.org/gnu/freefont/freefont-otf-20120503.tar.gz",
          ("FreeSerif*.otf", "COPYING", "README"),
        ),
      ), //roman numerals in [Number Forms]
      (name: "Adwaita Mono", src: ("gitlab", "https://gitlab.gnome.org/adwaita-fonts", ("mono/*.ttf", "LICENSE"))), //most of remaining part of [Latin Extended-D]
      "Plangothic P2", //remaining part of [Latin Extended-G]
      "思源黑體", //"Source Han Sans TC"; fullwidth latin chars in [Halfwidth and Fullwidth Forms]
    ), //script complete except for U+A7D2 LATIN CAPITAL LETTER DOUBLE THORN, U+A7D4 LATIN CAPITAL LETTER DOUBLE WYNN (from [Latin Extended-D]), a couple others
    "Greek",
    (
      "Noto Serif", //all of {Greek} except Ancient Greek numbers + musical symbols
      "Noto Sans Symbols 2", //Ancient Greek numbers
      "Noto Music", //Ancient Greek musical symbols
    ), //script complete
    "Cyrillic",
    (
      "Noto Serif", //all of {Cyrillic} except [Cyrillic Extensions-D]
    ), //script complete except for some mostly modifier letters in [Cyrillic Extensions-D]
    "Han",
    (
      (
        name: "思源黑體",
        src: (
          ("url", "https://github.com/adobe-fonts/source-han-sans/blob/release/OTC/SourceHanSans-Regular.ttc"),
          ("url", "https://github.com/adobe-fonts/source-han-sans/blob/release/OTC/SourceHanSans-Bold.ttc"),
        ),
      ), //"Source Han Sans TC"; all of [CJK Unified Ideographs{, Extension A}] + misc
      (
        name: "Plangothic P1",
        src: (
          "url",
          "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/latest/download/PlangothicP1-Regular.ttf",
        ),
      ), //all of [CJK Unified Ideographs Extension {B,C,D,E,F,I}]
      (
        name: "Plangothic P2",
        src: (
          "url",
          "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/latest/download/PlangothicP2-Regular.ttf",
        ),
      ), //all of [CJK Unified Ideographs Extension {G,H,J}]
    ), //script complete
    "Hiragana",
    (
      (name: "Noto Serif JP", src: "gfonts"), //bit of a waste for just the kana; we could subset but i don't really know how
      (name: "Noto Serif Hentaigana", src: "gfonts"),
    ), //pretty much everything, nobody cares about U+1B11F HIRAGANA LETTER ARCHAIC WU
    "Katakana",
    (
      "Noto Serif JP",
      "Noto Serif Hentaigana", //for some reason there are a couple katakana in this font?
    ), //everything but the taiwanese tone stuff and some small letters
    "Bopomofo",
    (
      "思源黑體", //"Source Han Sans TC"
    ), //missing a few charas in [Bopomofo Extended] but i don't wanna pull another font just for them
    "Hangul",
    (
      (name: "Source Han Sans K", src: ("proxy", "思源黑體")),
    ), //script complete
    "Tangut",
    (
      (name: "唐兀銀川", src: ("url", "https://www.babelstone.co.uk/Fonts/Download/TangutYinchuan.ttf")), //"Tangut Yinchuan"
    ), //script complete
    "Syriac",
    (
      (name: "Noto Sans Syriac", src: "gfonts"), //supports everything except [Syriac Supplement]
      "Plangothic P2", //gotta love comprehensive fonts
    ), //script complete
    "Runic",
    (
      (name: "Babelstone Runic", src: ("url", "https://www.babelstone.co.uk/Fonts/Download/BabelStoneRunic.ttf")),
    ), //script complete
    "Tamil",
    (
      (name: "Noto Sans Tamil", src: "gfonts"),
      (name: "Noto Sans Tamil Supplement", src: "gfonts"), //they put [Tamil Supplement] in a different font for some reason
    ), //script complete
    "Glagolitic",
    (
      (name: "Noto Sans Glagolitic", src: "gfonts"), //everything except literally two characters (U+2C2F, U+2C5F)
      "Plangothic P2", //to the rescue again
    ), //script complete
    "Egyptian Hieroglyphs",
    (
      (name: "Noto Sans EgyptHiero", src: ("gfonts", "Noto Sans Egyptian Hieroglyphs")), //(currently) missing [Egyptian Hieroglyphs Extended-A]
    ),
    "Nko",
    (
      (name: "Noto Sans NKo", src: "gfonts"),
    ),
  )

  //scripts that are fully supported by a Noto Sans font with the script in its name
  let noto-sans-supports = (
    "Yi",
    "Arabic", //minus some obscure stuff in [Arabic Presentation Forms A], [Arabic Extended-C] that i don't have a single font for
    "Tifinagh",
    "Bamum",
    "Sinhala",
    "Javanese",
    "Ethiopic",
    "Soyombo",
    "Pahawh Hmong",
    "Phoenician",
    "Tagalog",
    "Coptic",
    "Khmer",
    "Lepcha",
    "Thaana",
    "Osmanya",
    "Vai",
    "Canadian Aboriginal",
    "Osage",
    "Mongolian",
    "Cuneiform",
    "Devanagari",
    "Oriya",
    "Cherokee",
    "Kharoshthi",
    "Linear A",
    "Linear B",
    "Ol Chiki",
    "Cham",
    "Manichaean",
    "Saurashtra",
    "Old Hungarian",
    "Armenian",
    "New Tai Lue",
    "Inscriptional Parthian",
    "Nushu",
    "Palmyrene",
    "Lao",
    "Gurmukhi",
    "Limbu",
    "Tai Viet",
    "Kannada", //technically missing one archaic char
    "Telugu", //ditto
    "Balinese", //missing U+1B4E, U+1B4F, U+1B7F. i don't have fonts for them
    "Vai",
    "Shavian",
    "Deseret",
    "Adlam",
    "Gothic",
    "Grantha",
  )
  //scripts that are fully supported by a Noto Serif font with the script in its name
  let noto-serif-supports = ("Georgian", "Makasar", "Tibetan")
  for script in noto-sans-supports {
    fonts-info.push(script)
    fonts-info.push(((name: "Noto Sans " + script, src: "gfonts"),))
  }
  for script in noto-serif-supports {
    fonts-info.push(script)
    fonts-info.push(((name: "Noto Serif " + script, src: "gfonts"),))
  }

  //anything we want to insert after everything else, so that it has the lowest priority in the font stack
  let final-insertions = (
    "Common",
    (
      (
        name: "Fairfax HD",
        src: (
          "archive",
          "https://github.com/kreativekorp/open-relay/releases/latest/download/FairfaxHD.zip",
          ("FairfaxHD.ttf", "OFL.txt"),
        ),
      ), //supports [Symbols for Legacy Computing{, Supplement}], [Tags], [Supplemental Arrows-C] and lots of other things. actually it supports *too* many things, so we'd like it to have low priority. for instance, it supports ⁂ (U+2042 ASTERISM from [General Punctuation], script {Common}) but with a poor glyph; we'd rather Noto Serif picks this up instead
    ),
    "Private Use",
    (
      //mostly (U)CSUR fonts here
      (
        name: "Alcarin Tengwar",
        src: (
          ("url", "https://github.com/Tosche/Alcarin-Tengwar/blob/main/Fonts%20Static/AlcarinTengwar-Regular.ttf"),
          ("url", "https://github.com/Tosche/Alcarin-Tengwar/blob/main/Fonts%20Static/AlcarinTengwar-Bold.ttf"),
        ),
      ), //tengwar
      "Fairfax HD", //bascially everything else in UCSUR, incl. sitelen pona, D'ni, Standard Galactic Alphabet, etc
    ),
  )
  fonts-info += final-insertions


  //we reverse and then take elements from the back with .pop(), so we end up taking them in the correct order
  fonts-info = fonts-info.rev()
  while fonts-info.len() > 0 {
    let (script-name, font-list) = (fonts-info.pop(), fonts-info.pop())
    for font-data in font-list {
      (
        if type(font-data) == str { (name: font-data) } else { font-data } + (covers: scripts-regex(script-name)),
      )
    }
  }
}

//helper function to strip unnecessary keys from dictionaries
#let filter-keys(dict, to-keep) = {
  for key in dict.keys() {
    if key not in to-keep {
      //suppress return value
      let _ = dict.remove(key)
    }
  }
  dict
}

//used to pick what font we use for what script
#let font-stack = fonts-info.map(x => filter-keys(x, ("name", "covers")))

#let generate-gfonts-link = name => {
  let encoded = name.replace(" ", "+")
  "https://fonts.googleapis.com/css2?family=" + encoded + ":ital,wght@0,400;0,700;1,700"
}

#let generate-github-link = path => {
  "https://github.com/" + path
}

//used for the dart download script
#let fonts-download-json = (
  fonts-info
    .map(x => filter-keys(x, ("name", "src"))) //keep only the keys we need
    .sorted(key: x => (x.name, -x.keys().len())) //sort alphabetically for aesthetics, and simultaneously sort duplicate entries in descending order by number of keys. if a font is specified multiple times and only one instance has a `src`, this will put that instance first
    .dedup(key: x => x.name) //keep only the first instance of a font name. thanks to the previous step, this is the one that has a src
    .map(x => {
      //pre-processing step: replace "proxy" type sources with dummy entries that have only a name. if the font is specified elsewhere in the list (which it should be) then this dummy entry will be removed by the second `dedup` we do after this step. otherwise, we will get a font with no `src` making it to the final processing step, which will be caught and create an error there. this is how we error-check the "proxy" field
      if "src" in x.keys() {
        if type(x.src) == array {
          if x.src.at(0) == "proxy" {
            return (name: x.src.at(1))
          }
        }
      }
      x
    })
    .sorted(key: x => (x.name, -x.keys().len())) //sort and dedup again...
    .dedup(key: x => x.name) //because the previous step can create duplicates
    .map(x => {
      //final pre-processing step: split multi-source entries into multiple entries. after this stage, there will actually be intentional duplicates in the list, so we don't dedup again
      if "src" in x.keys() {
        let src = x.src
        if type(src.at(0)) == array {
          //array of arrays; split it into multiple entries
          return for y in src {
            ((name: x.name, src: y),)
          }
        }
      }
      x
    })
    .flatten() //separate the multiple entries created by the previous step
    .map(x => //add a url to the font, determined from its `src` info
    (
      x
        + {
          let name = x.name
          if "src" in x.keys() {
            let src = x.src
            if type(src) == str {
              //only one string specified; currently there is only one case where this is valid
              if src == "gfonts" {
                (url: generate-gfonts-link(name))
              } else {
                panic("Invalid `src` for font " + name + ": `" + src + "`.")
              }
            } else if type(src) == array {
              let src-type = src.at(0)
              (
                if src.len() < 2 {
                  panic("Invalid `src` for font " + name + "; array given but second argument missing.")
                } else {
                  let data = src.at(1)
                  if src-type == "gfonts" {
                    (url: generate-gfonts-link(data))
                  } else if src-type == "github" {
                    (url: generate-github-link(data))
                  } else if src-type in ("url", "gitlab", "archive") {
                    (url: data)
                  } else {
                    panic("Invalid source type for font " + name + ": " + src-type + ".")
                  }
                }
                  + if src.len() >= 3 {
                    //if a third argument is given, it should be a list of files to keep
                    if type(src.at(2)) == array {
                      (keep: src.at(2))
                    } else {
                      panic("Invalid keep value for font " + name + ": " + src.at(2))
                    }
                  }
              )
            } else {
              panic("Invalid data type for `src` for font " + name + ".")
            }
          } else {
            panic("Missing `src` for font " + name + ".")
          }
        }
    ))
    .map(
      //we don't need detailed `src` info anymore, so just keep the src type
      x => {
        if "src" in x.keys() {
          if type(x.src) == array {
            return x + (src: x.src.at(0))
          }
        }
        x
      },
    )
)
#metadata(fonts-download-json) <fonts-download-json>

//drop shadow config
#let drop-shadow-size = 0.1cm
#let drop-shadow-offset = (x: 0.075cm, y: 0.0375cm)
#let drop-shadow-colour = rgb(0, 0, 0, 50%)

/*
tikz (used in the latex version of this code) automatically creates a margin around the bounding box of any text you place in a node, and this is its default size.
in order to pixel-perfectly match the latex version's placement of some text, it's sometimes necessary to account for this; in this case we set the text in question to `top-edge: "bounds"`, `bottom-edge: "bounds"` to reflect the latex behaviour.
*/
#let tikz-inner-sep = 0.3333em

//sequence used when labelling glyph/ambigram submissions on the voting image
#let LABEL-SEQUENCE = (
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
  "Æ",
  "Þ",
  "ẞ",
  "Ø",
  "Ð",
  "Ŋ",
  "Ĳ",
  "Ł",
  "Γ",
  "Δ",
  "Θ",
  "Λ",
  "Ξ",
  "Π",
)

//background text for many of our images
#let pangrams = "The quick brown fox jumps over a lazy doggo. Zəfər, jaketini də papağini da götür, bu axşam hava çox soyuq olacaq. Съешь ещё этих мягких французских булок да выпей же чаю. Příliš žluťoučký kůň úpěl ďábelské ódy. Høj bly gom vandt fræk sexquiz på wc. À noite, vovô Kowalsky vê o ímã cair no pé do pingüim queixoso e vovó põe açúcar no chá de tâmaras do jabuti feliz. Ταχίστη αλώπηξ βαφής ψημένη γη, δρασκελίζει υπέρ νωθρού κυνός. Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich. Voix ambiguë d'un cœur qui au zéphyr préfère les jattes de kiwis. Под южно дърво, цъфтящо в синьо, бягаше малко пухкаво зайче. Jó foxim és don Quijote húszwattos lámpánál ülve egy pár bűvös cipőt készít. Dzigbe zã nyuie na wò, ɣeyiɣi didi aɖee nye sia no see, ɣeyiɣi aɖee nye sia tso esime míeyi suku. Ex-sportivul își fumează jucăuș țigara bând whisky cu tequila. Широкая электрификация южных губерний даст мощный толчок подъёму сельского хозяйства. Portez ce vieux whisky au juge blond qui fume. Ìwò̩fà ń yò̩ séji tó gbojúmó̩, ó hàn pákànpò̩ gan-an nis̩é̩ rè̩ bó dò̩la. Kæmi ný öxi hér, ykist þjófum nú bæði víl og ádrepa. D'fhuascail Íosa Úrmhac na hÓighe Beannaithe pór Éava agus Ádhaimh. Pranzo d'acqua fa volti sghembi. Törkylempijävongahdus. Cem vî feqoyê pîs zêdetir ji çar gulên xweşik hebûn. On sangen hauskaa, että polkupyörä on maanteiden jokapäiväinen ilmiö. Љубазни фењерџија чађавог лица хоће да ми покаже штос. Stróż pchnął kość w quiz gędźb vel fax myjń. Benjamín pidió una bebida de kiwi y fresa. Noé, sin vergüenza, la más exquisita champaña del menú. Do bạch kim rất quý nên sẽ dùng để lắp vô xương. Pijamalı hasta yağız şoföre çabucak güvendi. Įlinkdama fechtuotojo špaga sublykčiojusi pragręžė apvalų arbūzą. Ѕидарски пејзаж: шугав билмез со чудење џвака ќофте и кељ на туѓ цех. Nechť již hříšné saxofony ďáblů rozezvučí síň úděsnými tóny waltzu, tanga a quickstepu. Parciais fy jac codi baw hud llawn dŵr ger tŷ Mabon. Ο καλύμνιος σφουγγαράς ψιθύρισε πως θα βουτήξει χωρίς να διστάζει. Жебракують філософи при ґанку церкви в Гадячі, ще й шатро їхнє п'яне знаємо. Skarzhit ar gwerennoù-mañ, kavet e vo gwin betek fin ho puhez."
