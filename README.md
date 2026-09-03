# AEY Terminal — Uganda Market Dashboard

A static, TradingView-inspired dashboard for Ugandan markets: USE equities, macro
indicators, fixed income, and agriculture spot prices. Built with vanilla HTML,
Tailwind CDN, and [Lightweight Charts](https://github.com/tradingview/lightweight-charts).

## Deploy on GitHub Pages

1. Push this folder (`index.html` + `data/`) to a repo.
2. Repo Settings → Pages → Deploy from branch → `main` / root.
3. Done — no build step needed.

## What's actually live vs. manual — read this before you present it to anyone

This is the honest part, and it matters for a finance-adjacent product:

| Data | Status | Why |
|---|---|---|
| USD/UGX | **Can be live** | [AllRatesToday](https://allratestoday.com) has a genuine free API tier (no card required). Add your free key in `index.html` → `fetchLiveUsdUgx()` → `API_KEY`. Until you do, it falls back to a manual mock value, clearly tagged "MANUAL" in the ticker. |
| CBR, CPI, 10-Year Bond Yield | **Manual only** | Bank of Uganda publishes these in PDFs/press releases, not a public API. Edit `data/macro_indicators.json` by hand when BoU updates. |
| USE equities (MTNU, SBU, UMEME, DFCU, etc.) | **Manual only** | The Uganda Securities Exchange has no free public price API. Edit `data/stocks_daily.json` from the USE daily bulletin. |
| Agriculture spot prices | **Manual only, illustrative** | No free Ugandan commodity API exists. Treat `data/agriculture_spot.json` as placeholder numbers until you source a real feed (e.g. a market-info service or your own data entry). |
| Candlestick chart history | **Synthetic** | Generated client-side around each instrument's last known price, seeded per ticker so it's stable on reload. It is not historical trading data. Replace `generateCandles()` with a real OHLC fetch once you have a data source. |

**If you plan to show this to real users as if it were a live trading terminal,
it isn't one yet** — it's a well-built shell with one live price feed and
everything else on a manual-update cadence. That's a legitimate MVP for an
internal tool, a pitch demo, or a client deliverable that's labeled clearly (which
this build does, via the "MANUAL" tags and the sidebar/README notes) — just don't
strip those labels out and call it real-time, because the underlying data sources
genuinely don't support that for the Ugandan instruments involved.

## Extending with real data

- **USE prices**: no clean API; your realistic options are (a) manual entry from
  the daily bulletin PDF, (b) a scraper you run yourself against USE's published
  bulletin and commit the JSON, or (c) a paid data vendor if this becomes a real
  product. There is no shortcut here.
- **Bond yields / CBR / CPI**: same — manual entry from BoU releases, or a
  scraper against BoU's publications page if you want it semi-automated.
- **Chart history**: once you have real OHLC data, swap `generateCandles()`'s
  output for fetched data in the same `{ time, open, high, low, close }` shape
  that `series.setData()` expects — Lightweight Charts needs no other changes.

## File structure

```
index.html                    # entire app — layout, styles, chart, logic
data/macro_indicators.json    # CBR, CPI, bond yield (manual)
data/stocks_daily.json        # USE watchlist (manual)
data/agriculture_spot.json    # commodity spot prices (manual, illustrative)
```

