# fetch_macro_timeseries.R
#
# Pulls multi-year CPI and GDP growth series from ugatsdb (MoFPED's official
# Uganda Time Series Database, https://mepd.finance.go.ug/apps.html) and
# writes them to data/macro_timeseries.json for the dashboard to read.
#
# Run locally with:  Rscript scripts/fetch_macro_timeseries.R

if (!requireNamespace("ugatsdb", quietly = TRUE)) install.packages("ugatsdb", repos = "https://cloud.r-project.org")
if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite", repos = "https://cloud.r-project.org")

library(ugatsdb)
library(jsonlite)

# --- Pull the series --------------------------------------------------------
# CPI_16: BoU headline "All Items" Consumer Price Index (2016/17=100), monthly.
# GDP_KP: UBOS "GDP at Market Prices, Constant 2016/17 Prices" (real GDP level,
#         UGX billion, quarterly). This is a LEVEL, not a growth rate — growth
#         is computed below as year-over-year % change.
cpi <- tryCatch(
  get_data(dsid = "BOU_CPI", series = "CPI_16", wide = FALSE, labels = FALSE),
  error = function(e) { message("CPI pull failed: ", e$message); NULL }
)

gdp_level <- tryCatch(
  get_data(dsid = "UBOS_GDP_KP", series = "GDP_KP", wide = FALSE, labels = FALSE),
  error = function(e) { message("GDP pull failed: ", e$message); NULL }
)

# --- Convert GDP level into year-over-year growth % ------------------------
compute_yoy_growth <- function(df, skip_periods = 8) {
  if (is.null(df) || nrow(df) < 5) return(NULL)
  df <- df[order(df$Date), ]
  n <- nrow(df)
  growth <- rep(NA_real_, n)
  for (i in 5:n) {
    prev <- df$Value[i - 4]
    if (!is.na(prev) && prev != 0) {
      growth[i] <- (df$Value[i] - prev) / prev * 100
    }
  }
  out <- data.frame(Date = df$Date, Value = growth)
  out <- out[!is.na(out$Value), ]
  # Drop the first `skip_periods` computed points — they sit right at UBOS's
  # 2016/17 rebase boundary (series starts 2008) and produce distorted,
  # implausible growth figures (30%+) that reflect rebase-year data
  # instability, not real economic growth. Later points are reliable.
  if (nrow(out) > skip_periods) out <- out[-(1:skip_periods), ]
  out
}

gdp <- compute_yoy_growth(gdp_level)

# --- Shape into JSON the dashboard's JS can consume directly ---------------
to_series <- function(df, label) {
  if (is.null(df) || nrow(df) == 0) return(list(label = label, points = list()))
  list(
    label = label,
    points = lapply(seq_len(nrow(df)), function(i) {
      list(date = as.character(df$Date[i]), value = as.numeric(df$Value[i]))
    })
  )
}

out <- list(
  generated_at = as.character(Sys.time()),
  source = "ugatsdb (MoFPED Macro Data Portal, mepd.finance.go.ug)",
  series = list(
    cpi = to_series(cpi, "Headline CPI Inflation, 2016/17=100 (BoU)"),
    gdp = to_series(gdp, "GDP Growth, Year-over-Year % (constant 2016/17 prices, UBOS)")
  )
)

dir.create("data", showWarnings = FALSE)
write_json(out, "data/macro_timeseries.json", auto_unbox = TRUE, pretty = TRUE)

message("Wrote data/macro_timeseries.json")