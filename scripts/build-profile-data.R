#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
vault <- if (length(args) >= 1) args[[1]] else Sys.getenv("MONOA_VAULT", unset = "../..")
output <- if (length(args) >= 2) args[[2]] else "data/people.json"
corpus <- file.path(vault, "MonOA Hub", "Corpus")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The jsonlite package is required. Install it with install.packages('jsonlite').")
}

required <- c("roster.csv", "profiles.csv", "publications.csv", "profile_items.csv")
missing <- required[!file.exists(file.path(corpus, required))]
if (length(missing)) stop("Missing corpus files: ", paste(missing, collapse = ", "))

read_corpus <- function(name) {
  read.csv(file.path(corpus, name), stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

roster <- read_corpus("roster.csv")
profiles <- read_corpus("profiles.csv")
publications <- read_corpus("publications.csv")
items <- read_corpus("profile_items.csv")

clean <- function(x) ifelse(is.na(x), "", x)
first_non_empty <- function(x) {
  x <- clean(x)
  x <- x[nzchar(x)]
  if (length(x)) x[[1]] else ""
}
truncate_text <- function(x, limit = 240) {
  x <- clean(x)
  ifelse(nchar(x) > limit, paste0(substr(x, 1, limit - 1), "…"), x)
}

split_keywords <- function(x) {
  x <- first_non_empty(x)
  if (!nzchar(x)) return(character())
  # The portal exports a space-separated string. Preserve meaningful multiword phrases
  # when commas or semicolons are available; otherwise show the source string as one tag.
  if (grepl("[,;]", x)) trimws(strsplit(x, "[,;]")[[1]]) else x
}

pick_publications <- function(person, limit = 8) {
  rows <- publications[publications$person == person, , drop = FALSE]
  if (!nrow(rows)) return(list())
  rows$year_num <- suppressWarnings(as.numeric(rows$year))
  rows <- rows[order(-rows$year_num, rows$title, na.last = TRUE), , drop = FALSE]
  rows <- rows[!duplicated(tolower(trimws(rows$title))), , drop = FALSE]
  rows <- head(rows, limit)
  lapply(seq_len(nrow(rows)), function(i) {
    doi <- clean(rows$doi[[i]])
    urls <- clean(rows$source_urls[[i]])
    url <- if (nzchar(doi)) paste0("https://doi.org/", doi) else first_non_empty(strsplit(urls, ";\\s*")[[1]])
    list(
      title = clean(rows$title[[i]]),
      year = clean(rows$year[[i]]),
      journal = clean(rows$journal[[i]]),
      url = url
    )
  })
}

pick_items <- function(person, limit = 10) {
  rows <- items[items$person == person, , drop = FALSE]
  if (!nrow(rows)) return(list())
  priority <- match(rows$item_type, c("project", "activity", "press-media", "prize", "student-thesis"), nomatch = 99)
  rows <- rows[order(priority, rows$title), , drop = FALSE]
  rows <- head(rows, limit)
  lapply(seq_len(nrow(rows)), function(i) list(
    type = clean(rows$item_type[[i]]),
    title = clean(rows$title[[i]]),
    url = clean(rows$item_url[[i]]),
    details = truncate_text(rows$details[[i]])
  ))
}

people <- lapply(sort(unique(roster$person)), function(person) {
  r <- roster[roster$person == person, , drop = FALSE]
  p <- profiles[profiles$person == person, , drop = FALSE]
  profile_url <- if (nrow(p)) first_non_empty(p$profile_url) else ""
  orcid_url <- first_non_empty(r$orcid_url)
  scholar_url <- first_non_empty(r$scholar_url)
  list(
    name = person,
    role = if (nrow(p)) first_non_empty(p$roles) else "",
    organisation = if (nrow(p)) first_non_empty(p$organisations) else "",
    accepting_phd = if (nrow(p)) first_non_empty(p$accepting_phd) else "",
    biography = if (nrow(p)) first_non_empty(p$biography) else "",
    research_keywords = if (nrow(p)) as.list(split_keywords(p$research_keywords)) else list(),
    profile_url = profile_url,
    orcid_url = orcid_url,
    scholar_url = scholar_url,
    profile_retrieved = if (nrow(p)) substr(first_non_empty(p$retrieved_at), 1, 10) else "",
    publications_retrieved = substr(first_non_empty(publications$retrieved_at[publications$person == person]), 1, 10),
    publications = pick_publications(person),
    profile_items = pick_items(person)
  )
})

payload <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  evidence_boundary = "Public professional information from Monash Research Portal, ORCID and Google Scholar.",
  people = people
)

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
jsonlite::write_json(payload, output, pretty = TRUE, auto_unbox = TRUE, na = "null")
message("Wrote ", length(people), " people to ", output)

