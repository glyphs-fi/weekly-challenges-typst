#import "helpers.typ" as helpers
#import "palette.typ" as palette
#import "global-config.typ" as global-config
#import "common.typ" as common


//configuration for the different showcase types

#let glyph-showcase-config = (
  showcase-width: 18cm,
  num-cols: 3,
  aspect-ratio: 1,
  path-template: "Glyph_X",
  title-text: "Weekly Glyph Challenge",
  pangram-font-size: 14.5pt,
  rectangular-badge: false,
  background-colour: palette.green,
  background-text-colour: palette.greenbg,
  badge-text-weight: "regular",
  /* set dynamically in `generate-glyph-showcase`
  primary-colour,
  */
)
#let ambi-showcase-config = (
  showcase-width: 22cm,
  num-cols: 3,
  aspect-ratio: 1.5,
  path-template: "Ambi_X",
  title-text: "Weekly Ambigram Challenge",
  pangram-font-size: 14.5pt,
  rectangular-badge: true,
  background-colour: palette.purple,
  background-text-colour: palette.purplebg,
  badge-text-weight: "bold",
  primary-colour: palette.purple,
)




//produces a grid of framed images together with their labels and a background rectangle
#let generate-image-grid(grid-width, config, image-dir) = {
  let full-path-template = image-dir + "/" + config.path-template
  //somewhat hacky code for finding number of submissions, needs to live in its own context for reasons
  context {
    helpers.number-of-submissions(full-path-template)
  }
  context {
    let num-items = helpers.number-of-submissions-return.get()
    helpers.number-of-submissions-return.update(0)
    let num-cols = config.num-cols
    let num-rows = helpers.ceil-division(num-items, num-cols)

    let label-square-length = 0.85cm
    let between-item-margin = 0.7cm
    let frame-stroke = 0.1cm

    let item-width = (grid-width - (num-cols + 1) * between-item-margin) / num-cols
    let between-item-width = item-width + between-item-margin

    let item-height = item-width / config.aspect-ratio
    let between-item-height = item-height + between-item-margin

    //construct all of the images, frames and labels, storing them for later
    let image-grid = for row in range(num-rows) {
      let items-in-row = calc.min(num-cols, num-items - (row * num-cols))

      //coordinates of the first image we draw
      let row-offset = (num-cols - items-in-row) / 2 * between-item-width + between-item-margin
      let column-offset = between-item-margin

      for col in range(items-in-row) {
        let item-num = (row * num-cols) + col + 1 //1-indexed
        let path = helpers.get-path(full-path-template, item-num)
        let path-label = label(path)

        let img = image(path)
        //will either be the image's natural dimensions, or (if too big) the largest dimensions it can render at within an `item-width` x `item-height` box
        let img-render-dimensions = measure(img, height: item-height, width: item-width)
        //scale up images that are too small to fit the box
        let scale-factor = calc.min(
          item-height / img-render-dimensions.height,
          item-width / img-render-dimensions.width,
        )
        let scaled-width = img-render-dimensions.width * scale-factor
        let scaled-height = img-render-dimensions.height * scale-factor
        //recreate image with new dimensions
        let img = image(
          path,
          width: img-render-dimensions.width * scale-factor,
          height: img-render-dimensions.height * scale-factor,
        )

        let img-box = box(
          height: item-height,
          width: item-width,
          stroke: frame-stroke + config.primary-colour,
          outset: (
            x: (frame-stroke - (item-width - scaled-width)) / 2,
            y: (frame-stroke - (item-height - scaled-height)) / 2,
          ),
          align(
            center + horizon,
            img,
          ),
        )

        let label-box = helpers.drop-shadowed-box(
          width: label-square-length,
          height: label-square-length,
          fill: config.primary-colour,
          align(
            center + horizon,
            text(
              fill: white,
              font: global-config.main-latin-font,
              size: 18pt,
              global-config.LABEL-SEQUENCE.at(item-num - 1),
              weight: "bold",
            ),
          ),
        )

        //coordinates of this image
        let item-xpos = row-offset + col * between-item-width
        let item-ypos = column-offset + row * between-item-height

        //draw image
        place(
          dx: item-xpos,
          dy: item-ypos,
          img-box,
        )

        //draw label
        place(
          dx: item-xpos - label-square-length / 2,
          dy: item-ypos - label-square-length / 2,
          label-box,
        )
      }
    }

    let grid-height = (num-rows) * between-item-height + between-item-margin

    //outputs the previously constructed grid with a drop-shadow background
    helpers.drop-shadowed-box(
      width: grid-width,
      height: grid-height,
      fill: palette.white,
      image-grid,
    )
  }
}




//produces a banner complete with title text, g&a logo, date and circular/rectangular badge with text inside
#let generate-banner(banner-width, badge-text-str, start-date, end-date, config) = {
  //we work with the half-height and half-width since it simplifies the circular badge case
  let (badge-half-height, badge-half-width) = (1.5cm, 1.5cm)
  let rect-badge-max-width = 5cm
  let badge-text-min-margin = 0.3cm

  let badge-text-args = (
    fill: config.primary-colour,
    weight: config.badge-text-weight,
    font: global-config.font-stack,
    /*
    if the badge is circular, we set the top and bottom edges to bounds/bounds. this means the text's bounding box will be tight at the top and bottom (aligning exactly with the visual bounds of the text) though not necessarily on the sides (because of bearings, can't do much about those since they're baked into the font). this results in (in my opinion) better automatic sizing and better centering within the circle.

    rectangular badges use the default top-edge/bottom-edge (capheight/baseline) but only because the text we put in to a rectangular badge might span multiple lines, and bounds/bounds messes with line spacing. however i kinda wrote a ridiculously complicated algorithm (`helpers.v-tight-par`) that sidesteps this problem by manually breaking text into lines and setting bounds/bounds only on the top and bottom lines, so we end up achieving the same effect in the end anyway
    */
    ..if not config.rectangular-badge { (top-edge: "bounds", bottom-edge: "bounds") },
  )

  //construct badge text, storing for later
  //how we calculate the size depends significantly on the badge shape
  let badge-text-box = if config.rectangular-badge {
    //rectangular badge
    let default-size = 30pt
    /*
    we first try horizontally resizing the badge to fit the text (rendered at `default-size`), and then resize the text to fit the badge. this results in three cases depending on how the text fits in the box at `default-size`:

    * sufficiently small text -> badge takes its minimal size, text is scaled up to fit
    * somewhat larger text -> badge is expanded to fit text without wrapping, text is `default-size`
    * sufficiently large text -> badge is expanded to maximum size, text is scaled down to fit and may wrap
    */

    let dummy-text = text(size: default-size, ..badge-text-args, badge-text-str)
    //width of our text assuming infinite space (so no word wrapping)
    let dummy-text-width = measure(dummy-text).width

    badge-half-width = calc.min(
      rect-badge-max-width / 2,
      calc.max(
        badge-half-height,
        dummy-text-width / 2 + badge-text-min-margin,
      ),
    )

    let badge-text-box-args = (
      width: badge-half-width * 2,
      height: badge-half-height * 2,
    )

    helpers.boxed-fitted-par(
      badge-text-box-args,
      badge-text-args,
      badge-text-str,
      margin: badge-text-min-margin,
    )
  } else {
    //circular badge
    box(helpers.text-fitting-circ(
      badge-text-str,
      badge-half-width,
      badge-text-min-margin,
      badge-text-args,
    ))
  }

  let badge-stroke = 0.2cm
  let badge-round-radius = if config.rectangular-badge {
    0.6cm
  } else {
    //make the corner radius big enough on a rounded rectangle and you get a circle
    //any value >= `badge-half-height` would generate a circle, but we need this specific value to make sure the stroke and the drop shadow are also circular (stroke can deal with too-big values, but my drop shadow implementation freaks out if we just pass a way-too-big number here)
    badge-half-height + badge-stroke / 2
  }
  //construct badge (including badge text from earlier), storing for later
  let badge = helpers.drop-shadowed-box(
    width: badge-half-width * 2,
    height: badge-half-height * 2,
    fill: palette.white,
    radius: badge-round-radius,
    shadow-round-radius: badge-round-radius,
    stroke: badge-stroke + config.primary-colour,
    ..if not config.rectangular-badge { (shadow-base-colour: black.lighten(30%).transparentize(30%)) },
    align(
      center + horizon,
      badge-text-box,
    ),
  )


  let icon-radius = 0.5cm
  let icon-offset = 0.14cm //distance between icon and right side of banner
  let ga-logo = image("ga_white.svg", width: 2 * icon-radius)

  //construct title text, storing for later
  let title-text = text(
    fill: palette.white,
    font: global-config.main-latin-font,
    size: 20pt,
    weight: "bold",
    style: "italic",
    config.title-text,
  )

  let colour-banner-height = 1.25cm

  //vertical distance between white and  banner
  let colour-banner-dy = 0.25cm

  //ridiculously complicated calculation to mimic the LaTeX version lmao
  let banner-text-dx = (
    (badge-half-width + banner-width - 2 * icon-radius - icon-offset - measure(title-text).width) / 2
  )

  //construct colour banner, storing for later
  let colour-banner = box(
    width: banner-width,
    height: colour-banner-height,
    fill: config.primary-colour,
    place(
      dx: banner-text-dx,
      dy: (colour-banner-height - measure(title-text).height) / 2,
      title-text,
    ),
  )

  let date-text-size = 10pt
  //construct date text, storing for later
  let date-text = text(
    fill: palette.orange,
    font: global-config.main-latin-font,
    size: date-text-size,
    weight: "bold",
    helpers.display-date-range(start-date, end-date),
  )

  //we measure the height of this text to figure out how to place the date; by measuring this text instead of the date itself, we make sure the date always ends up in the same place, regardless of whether it contains any ascenders/descenders
  let date-dummy-text = text(
    font: global-config.main-latin-font,
    size: date-text-size,
    weight: "bold",
    "abcdefghijklmnopqrstuvwxyz",
  )

  let white-banner-height = 2cm
  //construct white banner, storing for later
  let white-banner = box(
    width: banner-width,
    fill: palette.white,
    height: white-banner-height,
    place(
      dx: banner-text-dx,
      dy: (white-banner-height + colour-banner-dy + colour-banner-height - measure(date-dummy-text).height) / 2,
      date-text,
    ),
  )

  //draw everything
  box(
    width: banner-width + badge-half-width,
    height: 2 * badge-half-height + badge-stroke,
    {
      //draw the two banners and the icon, and apply drop shadow
      place(
        dx: badge-half-width,
        dy: badge-half-height - white-banner-height / 2,
        helpers.drop-shadowed-box(
          width: banner-width,
          height: white-banner-height,
          {
            place(
              white-banner,
            )
            place(
              dy: colour-banner-dy,
              colour-banner,
            )
            place(
              dx: banner-width - (2 * icon-radius + icon-offset),
              dy: colour-banner-dy + colour-banner-height / 2 - icon-radius,
              ga-logo,
            )
          },
        ),
      )
      //draw badge, including text + drop shadow
      place(
        badge,
      )
    },
  )
}




//produces a full showcase complete with banner, image grid and background
#let generate-showcase(badge-text-str, start-date, end-date, config, image-dir) = context {
  let rectangular-badge = config.rectangular-badge
  let showcase-width = config.showcase-width

  //horizontal space on each side of the image grid
  let side-margin = 1cm

  //construct banner, storing for later
  let banner = generate-banner(showcase-width / 2 + 3cm, badge-text-str, start-date, end-date, config)

  //construct image grid, storing for later
  let image-grid = generate-image-grid(
    showcase-width - 2 * side-margin,
    config,
    image-dir,
  )

  //construct foreground (banner + image grid with spacing in between), storing for later
  let foreground = {
    helpers.spacing-block(showcase-width, 0.5cm)

    //draw the banner
    block(
      width: showcase-width,
      align(
        center,
        banner,
      ),
    )

    helpers.spacing-block(showcase-width, 0.25cm)

    //draw the grid
    move(
      block(
        width: showcase-width,
        align(
          center,
          image-grid,
        ),
      ),
    )

    helpers.spacing-block(showcase-width, 1cm)
  }

  //draw everything
  common.draw-foreground-over-pangrams(foreground, config)
}



//produces glyph showcase
#let generate-glyph-showcase(glyph, weeknum, start-date, end-date, image-dir) = {
  let config = glyph-showcase-config
  config += (primary-colour: palette.this-week-fg(weeknum))
  generate-showcase(glyph, start-date, end-date, config, image-dir)
}

//produces ambigram showcase
#let generate-ambi-showcase(ambi, start-date, end-date, image-dir) = {
  generate-showcase(ambi, start-date, end-date, ambi-showcase-config, image-dir)
}
