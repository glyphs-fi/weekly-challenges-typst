#import "showcase.typ" as showcase
#import "announcement.typ" as announcement
#import "global-config.typ" as global-config
#import "helpers.typ" as helpers
#import "palette.typ" as palette
#import "hall-of-fame.typ" as hall-of-fame

//same preamble as main.typ
#set page(width: auto, height: auto, margin: 0pt)
#set par(spacing: 0pt)
#set place(top + left)

#let draw-test-label = name => place(
  box(
    fill: white.transparentize(30%),
    text(
      top-edge: "bounds",
      bottom-edge: "bounds",
      fill: black,
      name,
    ),
  ),
)

#context {
  let test-glyphs = ("牛", "Æ", "﷽", "o̦")
  let test-ambis = (
    "short",
    "kinda long",
    "quite long with spaces",
    "quitelongwithnospaces",
    "very very excessively extremely long it just doesn't end it keeps going but at least it has spaces",
    "AAAAAAAAAAAAAAAAAAAAAAAAAAA",
  )
  let glyph-primary = palette.this-week-fg(200)
  let glyph-bg = palette.this-week-bg(200)
  let ambi-bg = palette.purple
  let test-date = datetime(year: 2069, month: 4, day: 20)

  /*box(
    inset: 1cm,
    fill: glyph-bg,
    helpers.drop-shadowed-box(20cm, 9cm, text("hello"), fill: none),
  )*/

  box(
    inset: 1cm,
    fill: glyph-bg,
    (
      for str in test-glyphs {
        (
          align(
            center,
            showcase.generate-banner(
              12cm,
              str,
              test-date,
              showcase.glyph-showcase-config + (primary-colour: glyph-primary),
            ),
          ),
        )
      }
    ).join(helpers.spacing-block(15cm, 1cm)),
  )
  draw-test-label("glyph-banner-test")
  pagebreak()

  box(
    inset: 1cm,
    fill: glyph-bg,
    (
      for str in test-glyphs {
        (
          align(
            center,
            announcement.generate-announcement-card(
              14cm,
              str,
              test-date,
              announcement.glyph-announcement-config + (primary-colour: glyph-primary),
            ),
          ),
        )
      }
    ).join(helpers.spacing-block(15cm, 1cm)),
  )
  draw-test-label("glyph-card-test")
  pagebreak()

  box(
    inset: 1cm,
    fill: ambi-bg,
    (
      for str in test-ambis {
        (
          align(
            center,
            showcase.generate-banner(
              14cm,
              str,
              test-date,
              showcase.ambi-showcase-config,
            ),
          ),
        )
      }
    ).join(helpers.spacing-block(15cm, 1cm)),
  )
  draw-test-label("ambi-banner-test")
  pagebreak()

  box(
    inset: 1cm,
    fill: ambi-bg,
    (
      for str in test-ambis {
        (
          align(
            center,
            announcement.generate-announcement-card(
              20cm,
              str,
              test-date,
              announcement.ambi-announcement-config,
            ),
          ),
        )
      }
    ).join(helpers.spacing-block(15cm, 1cm)),
  )
  draw-test-label("ambi-card-test")
  pagebreak()

  box(
    inset: 1cm,
    fill: glyph-bg,
    for challenge in ("Glyph", "Ambi") {
      (
        align(
          center,
          showcase.generate-image-grid(
            16cm,
            if (challenge == "Glyph") { showcase.glyph-showcase-config } else { showcase.ambi-showcase-config }
              + if challenge == "Glyph" { (primary-colour: glyph-primary) },
            "sample_images",
          ),
        ),
      )
    }.join(helpers.spacing-block(18cm, 1cm)),
  )
  draw-test-label("image-grid-test")
  pagebreak()

  box(
    inset: 1cm,
    fill: glyph-bg,
    for (display-width, challenge) in ((16cm, "Glyph"), (18cm, "Ambi")) {
      for (winner-name, pos) in (("the_uwuji", 1), ("nope", 2), ("狗", 3)) {
        (
          align(
            center,
            box(hall-of-fame.generate-winner-display(
              challenge + "WinnerX.png",
              display-width,
              0,
              winner-name,
              pos,
              "sample_images",
            )),
          ),
        )
      }
    }.join(helpers.spacing-block(18cm, 1cm)),
  )
  draw-test-label("hall-of-fame-test")
}
