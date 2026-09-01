# fetch_macro_timeseries.R
#
# Pulls multi-year CPI and GDP growth series from ugatsdb (MoFPED's official
# Uganda Time Series Database, https://mepd.finance.go.ug/apps.html) and
# writes them to data/macro_timeseries.json for the dashboard to read.
#
# This is NOT something the browser can do directly — ugatsdb is an R
# package that talks to a MySQL database, with no public REST/JSON endpoint.
# So this script runs on a schedule (see .github/workflows/update-macro.yml)
# and commits its JSON output, which the static site then fetches normally.
#
# Run locally with:  Rscript scripts/fetch_macro_timeseries.R

if (!requireNamespace("ugatsdb", quietly = TRUE)) install.packages("ugatsdb", repos = "https://cloud.r-project.org")
if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite", repos = "https://cloud.r-project.org")

library(ugatsdb)
library(jsonlite)

# --- 1. Discover the exact series codes you want ---------------------------
# Uncomment these to explore available series/datasources the first time you
# run this — then hardcode the codes you land on below, so scheduled runs
# don't need to re-search.
#
# print(datasources())
# print(datasets())
# print(series(dataset = "CPI"))       # adjust to whatever the real dataset id is
# print(series(dataset = "GDP"))

# --- 2. Pull the series ------------------------------------------------------
# Replace "CPI_HEADLINE" / "GDP_GROWTH" with the real series codes from
# series() above — ugatsdb's codes are specific and won't match these
# placeholders exactly.
cpi <- tryCatch(
  get_data(series_id = "CPI_HEADLINE"),
  error = function(e) { message("CPI pull failed: ", e$message); NULL }
)

gdp <- tryCatch(
  get_data(series_id = "GDP_GROWTH"),
  error = function(e) { message("GDP pull failed: ", e$message); NULL }
)

# --- 3. Shape into something the dashboard's JS can consume directly -------
to_series <- function(df, label) {
  if (is.null(df)) return(list(label = label, points = list()))
  list(
    label = label,
    points = lapply(seq_len(nrow(df)), function(i) {
      list(date = as.character(df$date[i]), value = as.numeric(df$value[i]))
    })
  )
}

out <- list(
  generated_at = as.character(Sys.time()),
  source = "ugatsdb (MoFPED Macro Data Portal, mepd.finance.go.ug)",
  series = list(
    cpi = to_series(cpi, "Headline CPI Inflation (%)"),
    gdp = to_series(gdp, "GDP Growth (%)")
  )
)

dir.create("data", showWarnings = FALSE)
write_json(out, "data/macro_timeseries.json", auto_unbox = TRUE, pretty = TRUE)

message("Wrote data/macro_timeseries.json")
