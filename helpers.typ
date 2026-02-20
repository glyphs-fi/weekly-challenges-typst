//for rectangular drop shadows
#import "global-config.typ" as global-config

//ceil(x/y) with integer division because i have an irrational fear of floating point numbers
#let ceil-division(x, y) = {
  calc.quo(x, y) + int(calc.rem(x, y) > 0)
}

//empty block for spacing
#let spacing-block(width, height) = {
  block(
    width: width,
    height: height,
    fill: rgb(0, 0, 0, 0),
  )
}

#let display-date-range(start-date, end-date) = {
  let get-ordinal = day => if day in (1, 21, 31) {
    "st"
  } else if day in (2, 22) {
    "nd"
  } else if day in (3, 23) {
    "rd"
  } else {
    "th"
  }
  (
    start-date.display(
      "[day padding:none]"
        + get-ordinal(start-date.day())
        + if start-date.month() != end-date.month() { " [month repr:long]" }
        + if start-date.year() != end-date.year() { " [year]" }
        + " – ",
    )
      + end-date.display("[day padding:none]" + get-ordinal(end-date.day()) + " [month repr:long] [year]")
  )
}


/*
  returns something akin to a `par` (technically just a sequence of text objects with linebreaks between them), but with the bounding box being tight at the top and bottom (`v` is for `vertically`), and text wrapping at `max-width`

  if the `strict` flag is enabled then we early return `none` if the text ever fails to fit within `max-width` (because there's a word that's simply too long at the specified size). this is for optimisation purposes. moreover if `max-height` is also set then we try to return early if we're clearly going to exceed it.

  i made this because the only way to get a `par` like this is to set the text to `top-edge: "bounds"`, `bottom-edge: "bounds"`, but this also messes with the line spacing (because of how the `leading` property is used) -- there's no way to have text treated as "cap-height"/"baseline" for line spacing purposes but "bounds"/"bounds" for par bounding box purposes.

  so i implemented my own simple line wrapping algorithm for this use case, and then accidentally spent way too much time complexifying and optimising it even though it was fast enough anyway
*/

#let v-tight-par(str, max-width, leading, text-args, strict: false, max-height: none) = {
  //creating and measuring text are both rather "slow" operations (on the order of 0.1ms, which does add up to an appreciable number of ms over the course of this function), so the focus when optimising is to perform them as few times as possible
  let get-text = (str, ..extra-text-args) => text(..text-args, ..extra-text-args, str)
  let measure-text = (str, ..extra-text-args) => measure(get-text(str, ..extra-text-args))

  let words = str.split(" ")
  let num-words = words.len()

  //array for storing computed word widths between iterations
  let word-widths = (none,) * num-words

  //before anything, we measure the first word of the string so we can early return if it's already too big (as is often the case when this is called from `boxed-fitted-par`)
  let (first-word-width, first-word-height) = (none, none)
  if num-words > 0 {
    (width: first-word-width, height: first-word-height) = measure-text(
      words.at(0),
      top-edge: "bounds",
      bottom-edge: "bounds",
    )
    word-widths.at(0) = first-word-width
    if strict {
      if first-word-width > max-width {
        return none
      }
      if max-height != none {
        if first-word-height > max-height {
          return none
        }
      }
    }
  }
  let line-buf = ""
  let line-buf-width = 0pt
  let lines = ()

  /*
  the purpose of the following algorithm is to reduce the number of `text` and `measure` calls by trying to batch multiple words together (note that the runtime of `measure` doesn't significantly depend on the size of the text, it's mostly constant overhead)
  the basic algorithm is (assuming an input of "one two three four"):
   * try to add 3 words at once to the current line ("one two three")
   * if that doesn't fit, try to add 2 words at once ("one two"). regardless of whether this fits, note that by measuring the widths of "one two three" and "one two", we can deduce the width of "three" (this is why we also need to know the width of a space). we can thus store this and avoid measuring it again later
   * if 2 words doesn't fit, we have to add just one word ("one"). again we can deduce the size of "two" from what we've already measured, so we can now add all three words separately without any additional measuring
  in the worst-case, we measure 3 times ("one two three", "one two", "one"), which is no worse than the naive method (measuring "one", "two", "three"); in the best-case (all 3 words fit at once), we only have to measure once ("one two three"), so on the whole we are likely to reduce the number of measures in longer texts

  is this really necessary? absolutely not
  */
  let space-width = measure-text(" ").width
  let i = 0
  let max-chunk-size = 3

  while i <= num-words {
    //codepath for when we've reached the end of the array with stuff left in the line buffer
    if i == num-words {
      if line-buf != "" {
        //flush the line buffer
        lines += (line-buf,)
      }
      break
    }
    //space between words, unless beginning of a line
    let line-buf-spaced = line-buf + if line-buf != "" { " " }
    let line-buf-spaced-width = line-buf-width + if line-buf != "" { space-width }

    let word-width = word-widths.at(i)

    //codepath for when we've computed the width of the current word already as a byproduct of a previous iteraiton
    if word-width != none {
      let word = words.at(i)
      //if it fits on the line, add it and move on
      if line-buf-spaced-width + word-width < max-width {
        line-buf = line-buf-spaced + word
        line-buf-width = line-buf-spaced-width + word-width
        i += 1
      } else {
        //if it doesn't fit, and we were at the beginning of a line, then we just have to accept that this word isn't fitting and put it on its own line (note that if we're in `strict` mode then we've already exited by this point)
        if line-buf == "" {
          line-buf = word
          i += 1
        }
        //if we *weren't* at the beginning of a line (didn't hit the previous `if`), then we should flush the line buffer and try to fit the word again, this time on a fresh line. note that we don't increment `i` in this case so the next iteration will be the same word
        //either way, we're flushing the line buffer
        lines += (line-buf,)
        line-buf = ""
        line-buf-width = 0pt
      }
    } //
    //
    //main codepath, we'll try to push the current word and the next two words together
    else {
      let num-chunks = calc.min(max-chunk-size, num-words - i)
      let chunks = (none,) * num-chunks
      let chunk-widths = chunks
      //basically setting up the array ("one", "one two", "one two three") if you recall the earlier example
      let chunk-buf = ""
      for j in range(num-chunks) {
        chunk-buf += (if j != 0 { " " } + words.at(i + j))
        chunks.at(j) = chunk-buf
      }
      //iterate through the chunks backwards (largest to smallest)
      for chunk-size in range(num-chunks, 0, step: -1) {
        let chunk = chunks.at(chunk-size - 1)
        let chunk-width = measure-text(chunk).width
        chunk-widths.at(chunk-size - 1) = chunk-width
        if chunk-size < num-chunks {
          //calculate (for instance) `width("one")` from `width("one two three")` and `width("one two")`
          let calculated-width = chunk-widths.at(chunk-size - 1 + 1) - chunk-width - space-width
          word-widths.at(i + chunk-size) = calculated-width
          if strict {
            if calculated-width > max-width {
              return none
            }
          }
        }
        //if we're down to a one-word chunk then we've computed its width already
        if chunk-size == 1 {
          word-widths.at(i) = chunk-width
          if strict {
            if chunk-width > max-width {
              return none
            }
          }
        }
        //if the chunk fits on the line, add it
        if line-buf-spaced-width + chunk-width < max-width {
          line-buf = line-buf-spaced + chunk
          line-buf-width = line-buf-spaced-width + chunk-width
          i += chunk-size
          if chunk-size < num-chunks {
            //if we've added a chunk, but not the biggest chunk under consideration, then the biggest chunk didn't fit, so we definitely need to wrap (e.g. if we're adding "one two", then that means "one two three" didn't fit, so we know already that "three" won't fit on the same line)
            //so we flush the line buffer
            lines += (line-buf,)
            line-buf = ""
            line-buf-width = 0pt
          }
          break
        } else if chunk-size == 1 {
          //same logic as the precomputed `word-width` codepath, if one word doesn't fit then it won't fit no matter what we do, so chuck it on its own line
          //(that codepath could be merged into this one, but there's too much pointless overhead in using this codepath for one word)
          if line-buf == "" {
            line-buf = word
            i += 1
          }
          lines += (line-buf,)
          line-buf = ""
          line-buf-width = 0pt
        }
      }
    }
  }

  //now we combine the lines together into output

  //`linebreak` respects leading, so the line spacing will be just like a `par` with the same leading
  set text(size: text-args.size)
  set par(leading: leading)

  //the whole reason we're doing all this: the top line has `top-edge: "bounds"`, the bottom line has `bottom-edge: "bounds"`, everything else is "cap-height"/"baseline".
  text(
    ..text-args,
    top-edge: "bounds",
    bottom-edge: if lines.len() > 1 { "baseline" } else { "bounds" },
    lines.at(0),
  )
  //since creating text is slow, we batch together the similar ones into one text object
  if lines.len() > 2 {
    linebreak()
    text(
      ..text-args,
      top-edge: "cap-height",
      bottom-edge: "baseline",
      lines.slice(1, lines.len() - 1).join("\n"),
    )
  }
  if lines.len() > 1 {
    linebreak()
    text(
      ..text-args,
      top-edge: "cap-height",
      bottom-edge: "bounds",
      lines.at(lines.len() - 1),
    )
  }
}

/*
general function that takes a one-argument function (parameterised by size, returning content) and a maximum size, and does a binary search to find the largest size such that the output of the function fits within a box of the specified size; returns that function output
*/
#let find-largest(fn, max-size, target-width, target-height) = {
  let upper-bound = max-size
  let lower-bound = 0pt
  let current-size = upper-bound / 2
  while true {
    let output = fn(current-size)
    if (
      output != none
        and {
          let (width: width, height: height) = measure(output)
          width < target-width and height < target-height
        }
    ) {
      lower-bound = current-size
      if upper-bound - lower-bound <= 0.1pt {
        return output
      }
    } else {
      upper-bound = current-size
    }
    current-size = (upper-bound + lower-bound) / 2
  }
}


/*
returns a `box` containing a `par` (technically a `v-tight-par`) of the specified text, at the largest size it can be while fitting within the box

more complex than the most naive methods (e.g. rendering text at an arbitrary size on an infinite canvas and then scaling it to fit in the box) because it takes into account word wrapping
*/
#let boxed-fitted-par(box-args, text-args, text-str, margin: 0cm, leading: 0.5em, max-size: 200pt) = {
  //we use the strict flag, so this will be `none` if the text is a really bad fit
  let construct-par = size => v-tight-par(
    text-str,
    box-args.width - margin * 2,
    leading,
    text-args + (size: size),
    strict: true,
    max-height: box-args.height - margin * 2,
  )

  let optimal-par = find-largest(construct-par, max-size, box-args.width - margin * 2, box-args.height - margin * 2)

  box(
    ..box-args,
    optimal-par,
    //uncomment to display text bounding box for debug purposes
    //box(stroke: teal, inset: 0cm, optimal-par),
  )
}

/*
returns text that is as big as it can be while fitting into a circle of radius `radius` with `margin` on every side; text is usually just a single glyph and we don't handle word wrapping
*/
#let text-fitting-circ(text-str, radius, margin, text-args) = {
  //initial size is pretty arbitrary since we take the measurement assuming infinite width
  let initial-size = 30pt
  let dummy-measurement = measure(text(..text-args, size: initial-size, text-str))
  //half-diagonal of bounding box rectangle
  let circumradius = (
    1cm * calc.sqrt(calc.pow(dummy-measurement.width.cm(), 2) + calc.pow(dummy-measurement.height.cm(), 2)) / 2
  )
  let text-size = initial-size * ((radius - margin).cm() / circumradius.cm())

  text(..text-args, size: text-size, text-str)
}

//convert template like "image_X" to (e.g.) "image_1"
#let get-path(path-template, n) = {
  path-template.replace("X", str(n))
}

/*
returns a box overlaid atop a drop shadow, which sticks out on the right and bottom of the box. parameters are the same as `box` but with extra shadow parameters.

the shadow is the same size as the box (after correcting for the box's stroke), is rounded with radius `shadow-round-radius` and has colour `shadow-base-colour`, fading towards its edges (over a distance of `shadow-gradient-diameter`) to `shadow-base.colour.transparentize(shadow-max-transparency)`.

under the hood the shadow is rendered as a bitmap. `shadow-resolution` describes the dpi of this bitmap. it gets blurry-upscaled to the correct size in the document, which actually makes it look better in most cases since we need a gradient anyway, so it looks pretty good even with a relatively low internal dpi.

note that the bounding box of the output is not affected by the drop shadow.
*/
#let drop-shadowed-box(
  ..box-args,
  content,
  shadow-resolution: 72,
  shadow-round-radius: 1mm,
  shadow-gradient-diameter: 1mm,
  shadow-base-colour: black.lighten(30%),
  shadow-max-transparency: 100%,
) = context {
  //determine box size
  let (width: box-width, height: box-height) = measure(box(..box-args, content))

  //could make these arguments
  let shadow-dx = shadow-gradient-diameter
  let shadow-dy = shadow-gradient-diameter

  //STEP 1: render the image we use as drop shadow (as a fairly low-res bitmap with the right aspect ratio)

  //if there's a stroke, then we want to add half the stroke thickness to the width and height used for the shadow, so that the stroke doesn't cover the shadow
  let box-stroke = box-args.at("stroke", default: stroke(0pt)).thickness
  let shadow-width = box-width + box-stroke
  let shadow-height = box-height + box-stroke

  //convert lengths to px
  let (half-render-width, half-render-height, gradient-diameter, corner-radius) = (
    shadow-width / 2,
    shadow-height / 2,
    shadow-gradient-diameter,
    shadow-round-radius,
  ).map(x => int(calc.round(x.inches() * shadow-resolution)))
  //ensure width and height are even so we can split into quadrants
  let render-width = half-render-width * 2
  let render-height = half-render-height * 2

  //ensure correct colour space since we'll be working directly with the components
  let base-colour = rgb(shadow-base-colour)

  //we render the positive-positive (bottom-right) quadrant and duplicate the data for the remainder of the rectangle since it's symmetrical
  let br-quadrant-rows = for j in range(1, half-render-height + 1) {
    let vertical-distance = half-render-height - j
    //the following brackets create a one-element list representing one row; these will get amalgamated by the outer for loop
    (
      for i in range(1, half-render-width + 1) {
        let horizontal-distance = half-render-width - i

        //the distance we use for interpolation is based either on proximity to the edges (if we aren't close to the corner) or proximity to the circle that defines the rounded corner (if we are close to it)
        let distance = if horizontal-distance > corner-radius or vertical-distance > corner-radius {
          calc.min(horizontal-distance, vertical-distance)
        } else {
          //coordinates relative to the center of the circle
          let local-i = i - (half-render-width - corner-radius)
          let local-j = j - (half-render-height - corner-radius)
          corner-radius - calc.sqrt(local-i * local-i + local-j * local-j)
        }

        let interpolation-value = calc.clamp((gradient-diameter - distance) / gradient-diameter, 0, 1)

        let colour = base-colour.transparentize(shadow-max-transparency * interpolation-value)
        (colour.components().map(x => int(calc.round(float(x) * 255))),)
      },
    )
  }
  let bl-quadrant-rows = br-quadrant-rows.map(x => x.rev())
  let tl-quadrant-rows = bl-quadrant-rows.rev()
  let tr-quadrant-rows = br-quadrant-rows.rev()
  //now convert to a full bytes array covering all the pixels
  let data = bytes((tl-quadrant-rows.zip(tr-quadrant-rows) + bl-quadrant-rows.zip(br-quadrant-rows)).flatten())

  //STEP 2: produce our box

  box(
    width: box-width,
    height: box-height,
    {
      //image we just created, scaled to appropriate size and on an offset
      place(
        dx: shadow-dx - box-stroke / 2,
        dy: shadow-dy - box-stroke / 2,
        image(
          width: shadow-width,
          height: shadow-height,
          //smooth interpolation for free blurring
          scaling: "smooth",
          //due to rounding, the image's aspect ratio likely won't exactly match, but it should be relatively close. stretching the image therefore won't distort it all that much. (if we don't specify this then our image will automatically get cropped to fit, completely ruining the gradient)
          fit: "stretch",
          format: (
            encoding: "rgba8",
            width: render-width,
            height: render-height,
          ),
          data,
        ),
      )
      //box with background colour, overlaid above the drop shadow
      place(
        box(
          ..box-args,
          content,
        ),
      )
    },
  )
}


//global counter, explained further down
#let number-of-submissions-return = state("number-of-submissions-return", 0)

/*
for a path template (such as "images/Glyph-X"), returns the number of files that exist matching that specification ("images/Glyph-1", "images/Glyph-2", etc)

typst does not have any functionality for checking whether a file exists, nor does it have try-catch style error-handling, so we use a hacky workaround (basic idea adapted from https://sitandr.github.io/typst-examples-book/book/typstonomicon/try-catch.html) to simulate a try-catch.

typst evaluates code involving `query`s multiple times until they give a consistent result, since it's possible to write code that both depends on the result of a `query` and changes the result of the same `query`; we abuse this behaviour.
*/
#let number-of-submissions(path-template) = {
  let label-exists = label => query(label).len() > 0

  for i in range(1, global-config.LABEL-SEQUENCE.len() + 1) {
    let path = get-path(path-template, i)
    let path-label = label(path)

    context {
      //detects whether we are on the first evaluation of this code
      let first-time = query((context {}).func()).len() == 0

      /*
      on the first evaluation, we attempt to draw the image and attach a label:
      * if the file exists, then this is successful and a (zero-width) image is created and labelled;
      * if the file doesn't exist then we error, but this error is ignored for now since it might be fixed by the next evaluation.

      on the second evaluation, `first-time` is false, and `label-exists()` is only true if we successfully attached the label on the first evaluation. so:
      * if the file exists, then we again create the image and label
      * if the file doesn't exist then this time we skip this code entirely, avoiding the error
      */
      if first-time or label-exists(path-label) {
        [#image(path, width: 0pt)#path-label]
      }
    }

    //separate context ensures that this code only runs after the previous block has fully resolved
    context {
      /*
      now we can check whether the label exists after the previous block resolves

      we'd love to just do something like

        if not label-exists(path-label) {
          return i - 1
        }

      but this function already has a return (the zero-width image returned from the previous `context` block) and we have no way to suppress it (if we could create the image in code then it'd be fine, but currently labels can only be applied to actual rendered `content`) so returning anything here will just append it, returning an opaque blob of `content` to the caller

      instead we "return" via a global counter, using the `state` api
      */
      if label-exists(path-label) {
        number-of-submissions-return.update(x => x + 1)
      }
    }
  }
}
