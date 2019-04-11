#' Create a Better Poster in HTML
#'
#' @return An R Markdown output format.
#' @export
poster_better <- function(
  ...,
  css = NULL,
  height = NULL,
  width = NULL,
  hero_background = NULL,
  hero_color = NULL,
  qrcode = NULL,
  logo = NULL,
  accent_color = NULL,
  mathjax = FALSE,
  pandoc_args = NULL
) {
  template <- pkg_resource("betterposter.html")

  if (!is.null(qrcode)) {
    if (inherits(qrcode, "list")) {
      if (!"color_background" %in% names(qrcode) && !is.null(hero_background)) {
        qrcode$color_background <- hero_background
      }
      if (!"color" %in% names(qrcode) && !is.null(hero_color)) {
        qrcode$color <- hero_color
      }
      qrcode <- do.call("qrcode_options", qrcode)
    } else if (is.character(qrcode) && length(qrcode) == 1) {
      qrcode <- qrcode_options(qrcode, color_background = hero_background)
    }
    if (!inherits(qrcode, "qrcode")) {
      stop("Please use qrcode_options() to set qrcode")
    }
  }

  pandoc_args <- c(pandoc_args, pandoc_arg(c(
    height = if (!is.null(height)) paste0(height, "in"),
    width = if (!is.null(width)) paste0(width, "in"),
    hero_background = hero_background,
    hero_color = hero_color,
    logo = logo,
    accent_color = accent_color
  )))

  if (mathjax) pandoc_args <- c(pandoc_args, "--mathjax")

  pagedown::poster_relaxed(..., css = css, template = template,
                           .dependencies = betterposter_dependencies(),
                           pandoc_args = c(pandoc_args, qrcode),
                           md_extensions = "-autolink_bare_uris",
                           number_sections = FALSE)
}

#' @export
qrcode_options <- function(
  text,
  color_background = "#00000000",
  color = "#FFFFFF",
  size = "250",
  as_yaml = FALSE
) {
  stopifnot(is.character(text))
  stopifnot(is.character(color_background))
  stopifnot(is.character(color))
  stopifnot(is.character(size))

  # if color_background is not a hex color then set to inherit
  color_background <- trimws(color_background)
  if (sub("#[a-fA-F0-9]{4,6}", "", color_background) != "") {
    warning("Ignoring non-hex QR code background in `color_background`")
    color_background <- "#00000000"
  }

  if (as_yaml) {
    x <- paste0(
      "\nqrcode:",
      '\n  text: "', text, '"',
      '\n  color_background: "', color_background, '"',
      '\n  color: "', color, '"',
      '\n  size: "', size, '"'
    )
    cat(x)
    return(invisible(x))
  }

  x <- pandoc_arg(c(
    "qrcode_text" = text,
    "qrcode_color_background" = color_background,
    "qrcode_color" = color,
    "qrcode_size" = size
  ))
  class(x) <- c("qrcode", class(x))
  x
}



# Utils -------------------------------------------------------------------
pkg_resource = function(...) {
  system.file('resources', ..., package = 'betterposter', mustWork = TRUE)
}

pandoc_arg <- function(values) {
  if (is.null(values) || length(values) == 0) return(NULL)
  stopifnot(!is.null(names(values)))
  ret <- c()
  for (name in names(values)) {
    ret <- c(
      ret,
      "--variable",
      paste0(name, "=", values[name])
    )
  }
  ret
}

betterposter_dependencies <- function() {
  list(
    htmltools::htmlDependency(
      "betterposter",
      packageVersion("betterposter"),
      src = pkg_resource(),
      stylesheet = "betterposter.css"
    ),
    htmltools::htmlDependency(
      "qrcode",
      "0.0.0",
      src = pkg_resource(),
      script = "qrcode.min.js"
    )
  )
}
