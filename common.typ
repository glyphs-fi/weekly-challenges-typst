#import "global-config.typ" as global-config

//function common to both showcase and announcement logic
//assumes `config` contains keys `background-colour`, `background-text-colour`, `pangram-font-size`
#let draw-foreground-over-pangrams(foreground, config) = {
  let (width: foreground-width, height: foreground-height) = measure(foreground)

  //i don't like magic constants so i'll define these here
  //the exact values don't really matter, but `pangram-box-dy` has been chosen to make sure the top of the rectangular badge in the ambigram showcase overlaps a line of background text (otherwise, because the badge stroke and background colour are the same, it blends in unpleasantly)
  let pangram-box-extra-width = 4cm
  let pangram-box-extra-height = 2cm
  let pangram-box-dx = -1.1cm
  let pangram-box-dy = -1.72cm

  //construct pangram text, storing for later
  let pangram-text-box = box(
    //give space for the text to go offscreen
    width: foreground-width + pangram-box-extra-width,
    height: foreground-height + pangram-box-extra-height,
    par(
      leading: 0.8em,
      text(
        fill: config.background-text-colour,
        font: global-config.main-latin-font,
        style: "italic",
        weight: "bold",
        size: config.pangram-font-size,
        global-config.pangrams * 3,
      ),
    ),
  )

  //draw the pangrams and background colour
  box(
    width: foreground-width,
    height: foreground-height,
    clip: true,
    fill: config.background-colour,
    move(
      //start drawing the pangrams from an offscreen position
      dx: pangram-box-dx,
      dy: pangram-box-dy,
      pangram-text-box,
    ),
  )

  //draw the foreground on top
  place(
    box(
      width: foreground-width,
      height: foreground-height,
      {
        foreground
      },
    ),
  )
}
