//used for static elements like banner title and background pangrams
#let main-latin-font = "Stix Two Text"

//regex that matches the given unicode scripts (and the Common script)
#let scripts(..names) = {
  regex({
    "["
    for name in (("Common",) + names.pos()).dedup() {
      "\p{"
      name
      "}"
    }
    "]"
  })
}

//used for glyph/ambigram display
#let font-stack = {
  let font-stack = (
    //the following comments use [] to identify blocks and {} to identify scripts
    "Common",
    (
      "Noto Sans Symbols",
    ), // a lot of {Common} will be covered by various other fonts, so we don't seek full coverage here
    "Latin",
    (
      "Stix Two Text", //all of [Basic Latin], [Latin Extended-A]; basic IPA; some misc Latin
      "Noto Serif", //all of [Latin Extended-{B,C,E,F}], [Phonetic Extensions{, Supplements}]; most of [Latin Extended-{D,G}]
      "FreeSerif", //roman numerals in [Number Forms]
      "Adwaita Mono", //most of remaining part of [Latin Extended-D]
      "Plangothic P2", //remaining part of [Latin Extended-G]
      "Noto Sans CJK TC", //fullwidth latin chars in [Halfwidth and Fullwidth Forms]
    ), //script complete except for U+A7D2 LATIN CAPITAL LETTER DOUBLE THORN, U+A7D4 LATIN CAPITAL LETTER DOUBLE WYNN (from [Latin Extended-D])
    "Greek",
    (
      "Noto Serif", //all of {Greek} except Ancient Greek numbers + musical symbols
      "Noto Sans Symbols 2", //Ancient Greek numbers
      "Noto Music", //Ancient Greek musical symbols
    ), //script complete
    "Cyrillic",
    (
      "Noto Serif", //all of {Cyrillic} except [Cyrillic Extensions-D]
      "Iosevka", //all of [Cyrillic Extensions-D]
    ), //script complete
    "Han",
    (
      "Noto Sans CJK TC", //all of [CJK Unified Ideographs{, Extension A}] + misc
      "Plangothic P1", //all of [CJK Unified Ideographs Extension {B,C,D,E,F,I}]
      "Plangothic P2", //all of [CJK Unified Ideographs Extension {G,H,J}]
    ), //script complete
    "Tangut",
    (
      "唐兀銀川", //"Tangut Yinchuan"; everything
    ), //script complete
    "Syriac",
    (
      "Noto Sans Syriac", //supports everything except [Syriac Supplement]
      "Plangothic P2", //gotta love comprehensive fonts
    ), //script complete
    "Runic",
    (
      "Babelstone Runic",
    ), //script complete
    "Tamil",
    (
      "Noto Sans Tamil",
      "Noto Sans Tamil Supplement", //they put [Tamil Supplement] in a different font for some reason
    ), //script complete
    "Glagolitic",
    (
      "Noto Sans Glagolitic", //everything except literally two characters (U+2C2F, U+2C5F)
      "Plangothic P2", //to the rescue again
    ), //script complete
  )

  //scripts that are fully supported by a Noto Sans font with the script in its name
  let noto-sans-supports = (
    "Yi",
    "Pahawh Hmong",
    "Phoenician",
    "Tagalog",
    "Coptic",
    "Khmer",
    "Osmanya",
    "Vai",
    "Canadian Aboriginal",
  )
  //scripts that are fully supported by a Noto Serif font with the script in its name
  let noto-serif-supports = ("Georgian", "Makasar")
  for script in noto-sans-supports {
    font-stack.push(script)
    font-stack.push(("Noto Sans " + script,))
  }
  for script in noto-serif-supports {
    font-stack.push(script)
    font-stack.push(("Noto Serif " + script,))
  }

  //ridiculous codegolf version of the below code that i couldn't resist writing
  //font-stack.fold((),(a,x)=>(a+=if""in x{(x,)}else{x.map(((..a,x)=a)+f=>(name:f,covers:scripts(x)))})+a)

  //we reverse and then take elements from the back with .pop(), so we end up taking them in the correct order
  font-stack = font-stack.rev()
  while font-stack.len() > 0 {
    let (script-name, font-names) = (font-stack.pop(), font-stack.pop())
    for font-name in font-names {
      ((name: font-name, covers: scripts(script-name)),)
    }
  }
}

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
