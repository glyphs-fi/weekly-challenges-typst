#import "helpers.typ" as helpers
#import "palette.typ" as palette
#import "global-config.typ" as global-config
#import "common.typ" as common

//configuration for the different announcement types

#let glyph-announcement-config = (
  announcement-width: 16cm,
  title-text: "Weekly Glyph Challenge",
  pangram-font-size: 20pt,
  announcement-text-weight: "regular",
  announcement-text-max-height: 3cm,
  /* set dynamically in `generate-glyph-announcement`
  primary-colour,
  background-colour,
  background-text-colour,
  */
)

#let ambi-announcement-config = (
  announcement-width: 22cm,
  title-text: "Weekly Ambigram Challenge",
  pangram-font-size: 20pt,
  announcement-text-weight: "bold",
  announcement-text-max-height: 2.5cm,
  primary-colour: palette.purple,
  background-colour: palette.purple,
  background-text-colour: palette.purplebg,
)



//produces the main rectangular (with a circle at the top) card with all the text, g&a icon and drop shadow
#let generate-announcement-card(card-width, announcement-text-str, start-date, end-date, config) = {
  let main-rectangle-height = 9cm

  let title-text-size = 30pt
  let title-text = text(
    weight: "bold",
    style: "italic",
    size: title-text-size,
    font: global-config.main-latin-font,
    fill: palette.pear,
    top-edge: "bounds",
    bottom-edge: "bounds",
    config.title-text,
  )

  let date-text-size = 16pt
  let date-text = text(
    weight: "bold",
    size: date-text-size,
    font: global-config.main-latin-font,
    fill: palette.orange,
    top-edge: "bounds",
    bottom-edge: "bounds",
    helpers.display-date-range(start-date, end-date),
  )

  //spacing will always be based on the same text, regardless of whether a particular date contains ascenders/descenders
  let date-dummy-text = text(
    weight: "bold",
    size: date-text-size,
    font: global-config.main-latin-font,
    top-edge: "bounds",
    bottom-edge: "bounds",
    "abcdefghijklmnopqrstuwvxzy0123456789",
  )
  let date-dummy-text-height = measure(date-dummy-text).height


  let announcement-text-box = {
    let announcement-text-args = (
      font: global-config.font-stack,
      fill: config.primary-colour,
      weight: config.announcement-text-weight,
    )

    let announcement-text-box-args = (
      width: card-width - 2cm,
      height: config.announcement-text-max-height,
    )

    helpers.boxed-fitted-par(
      announcement-text-box-args,
      announcement-text-args,
      announcement-text-str,
    )
  }

  let footer-text = text(
    weight: "bold",
    style: "italic",
    size: 14pt,
    font: global-config.main-latin-font,
    fill: palette.pear,
    top-edge: "bounds",
    bottom-edge: "bounds",
    //trailing space in this string is intentional, matches latex behaviour
    "Glyphs & Alphabets ",
  )
  let (width: footer-text-width, height: footer-text-height) = measure(footer-text)

  //when we `move` an object, according to the docs,
  //"the layout still 'sees' it at the original position"
  //therefore, typst 'sees' our text objects as being laid out on separate lines one after another, with bounding boxes flush to each other; the `dy` value for each text object positions it relative to this underlying position
  let title-text-dy = 1cm + global-config.tikz-inner-sep
  let date-text-dy = title-text-dy + 2 * global-config.tikz-inner-sep
  let announcement-text-dy = date-text-dy + 2 * global-config.tikz-inner-sep + 4cm - config.announcement-text-max-height

  let main-rectangle = box(
    width: card-width,
    fill: palette.white,
    height: main-rectangle-height,
    {
      align(
        center,
        move(
          dy: title-text-dy,
          title-text,
        ),
      )
      align(
        center,
        move(
          dy: date-text-dy,
          box(height: date-dummy-text-height, date-text),
        ),
      )
      align(
        center,
        move(
          dy: announcement-text-dy,
          announcement-text-box,
        ),
      )
      place(
        dx: card-width - 0.3cm - footer-text-width,
        dy: main-rectangle-height - 0.3cm - footer-text-height,
        footer-text,
      )
    },
  )

  let top-circle-radius = 1.45cm
  let ga-icon-radius = 0.9cm
  let top-circle = circle(
    fill: palette.white,
    radius: top-circle-radius,
  )

  box(
    width: card-width,
    height: main-rectangle-height + top-circle-radius,
    {
      place(
        dx: card-width / 2 - top-circle-radius,
        top-circle,
      )
      place(
        dy: top-circle-radius,
        helpers.drop-shadowed-box(width: card-width, height: main-rectangle-height, main-rectangle),
      )
      place(
        dx: card-width / 2 - ga-icon-radius,
        dy: top-circle-radius - ga-icon-radius,
        image(
          "GA_icon.pdf",
          width: ga-icon-radius * 2,
        ),
      )
    },
  )
}



//produces a full announcement complete with card, background and pangrams
#let generate-announcement(announcement-text-str, start-date, end-date, config) = context {
  let announcement-width = config.announcement-width

  //horizontal space on each side of the card
  let side-margin = 1cm

  //construct card, storing for later
  let card = generate-announcement-card(
    announcement-width - 2 * side-margin,
    announcement-text-str,
    start-date,
    end-date,
    config,
  )

  //construct foreground
  let foreground = {
    helpers.spacing-block(announcement-width, 0.55cm)

    block(
      width: announcement-width,
      align(
        center,
        card,
      ),
    )

    helpers.spacing-block(announcement-width, 1cm)
  }

  let (width: foreground-width, height: foreground-height) = measure(foreground)

  common.draw-foreground-over-pangrams(foreground, config)
}


//produces glyph announcement
#let generate-glyph-announcement(glyph, weeknum, start-date, end-date) = {
  let config = glyph-announcement-config
  config += (
    primary-colour: palette.this-week-fg(weeknum),
    background-colour: palette.this-week-fg(weeknum),
    background-text-colour: palette.this-week-bg(weeknum),
  )
  generate-announcement(glyph, start-date, end-date, config)
}

//produces ambigram announcement
#let generate-ambi-announcement(ambi, start-date, end-date) = {
  let config = ambi-announcement-config
  generate-announcement(ambi, start-date, end-date, config)
}
