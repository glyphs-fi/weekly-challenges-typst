#import "helpers.typ" as helpers
#import "global-config.typ" as global-config
#import "palette.typ" as palette

//generates the image corresponding to the given winner. always takes up 8cm of vertical space, with spacing added to make sure of this
#let generate-winner-image(path, max-image-width) = context {
  let (width: image-width, height: image-height) = measure(image(path))
  let min-scaling = calc.min(max-image-width / image-width, 8cm / image-height)
  (image-width, image-height) = (min-scaling * image-width, min-scaling * image-height)
  let img = image(path, width: image-width, height: image-height)
  let residual-height = 8cm - image-height
  helpers.spacing-block(image-width, residual-height / 2)
  helpers.drop-shadowed-box(height: image-height, img, shadow-gradient-diameter: 2mm)
  helpers.spacing-block(image-width, residual-height / 2)
}

#let generate-winner-nameplate(winner-name, pfp-dir) = {
  let pfp = box(width: 1.5cm, height: 1.5cm, radius: 1.5cm, clip: true, image(pfp-dir + "/" + winner-name + ".png"))
  box(
    height: 1.5cm,
    {
      pfp
      h(15pt)
      box(height: 1.5cm, align(horizon, text(
        winner-name,
        font: global-config.font-stack,
        fill: palette.white,
        size: 40pt,
        weight: "bold",
        style: "italic",
      )))
    },
  )
}

//generates a hall of fame image. submission is found using `path-template` (which should be something like `images/GlyphWinnerX"; X is replaced with First, Second, Third). `week-num` is the week num of the challenge, not of the week where we generate these (the week after the challenge). `pos` is 1, 2, or 3 for first, second, third.
//image-dir is the directory where profile images are stored
#let generate-winner-display(path-template, display-width, week-num, winner-name, pos, image-dir) = {
  let (pos-text, bg-color) = if pos == 1 {
    ("First", palette.next-week-bg(week-num))
  } else if pos == 2 {
    ("Second", palette.next-next-week-bg(week-num))
  } else if pos == 3 {
    ("Third", palette.last-week-bg(week-num))
  } else {
    panic("invalid position number; can only be 1, 2, 3 (first, second, third")
  }
  let image = generate-winner-image(image-dir + "/" + path-template.replace("X", pos-text), display-width - 2cm)
  let nameplate = generate-winner-nameplate(winner-name, image-dir + "/pfp")
  let foreground = {
    helpers.spacing-block(display-width, 1cm)
    align(
      center,
      image,
    )
    helpers.spacing-block(display-width, 0.5cm)
    align(
      center,
      nameplate,
    )
  }
  box(
    width: display-width,
    height: 12cm,
    fill: bg-color,
  )
  place(foreground)
}

#let generate-glyph-winner-display(week-num, winner-name, pos, image-dir) = {
  generate-winner-display("GlyphWinnerX", 16cm, week-num, winner-name, pos, image-dir)
}

#let generate-ambi-winner-display(week-num, winner-name, pos, image-dir) = {
  generate-winner-display("AmbiWinnerX", 18cm, week-num, winner-name, pos, image-dir)
}
