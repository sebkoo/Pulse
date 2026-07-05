# Pulse

![CI](https://github.com/sebkoo/Pulse/actions/workflows/ci.yml/badge.svg)

**Pulse is a config-driven, white-label dashboard for iOS built over free, keyless public APIs — fork it, edit `Brand.json`, ship your own.** One JSON file controls the app's name, accent color, and which data modules render; the architecture is protocol-oriented so adding or swapping a data provider (weather, earthquakes, or your company's commercial API) requires zero UI changes. Offline-first by design: the last successful response is cached and served with its staleness, so the dashboard stays useful without a connection.

> ⚙️ **Workflow transparency:** built with an AI-assisted workflow (Claude as pair programmer — see the commit trailers); the architecture decisions, code review, and final call on every line are mine.

## One codebase, three brands

| Pulse (default) | Acme Field Ops | Marina Weather |
| --- | --- | --- |
| ![Pulse default brand](docs/screenshots/pulse-default.png) | ![Acme Field Ops brand](docs/screenshots/acme-field-ops.png) | ![Marina Weather brand](docs/screenshots/marina-weather.png) |

Every column is the same code with a different `Brand.json` — name, accent color, and module set/order all come from config. Images are rendered from the real SwiftUI views with fixed sample data (`swift run pulse-screenshots`); the earthquakes card is deliberately shown stale so the offline chip is visible.

## City search

Type a city, get its weather. The search field debounces keystrokes with **Combine** (`CitySearchModel`), queries Open-Meteo's keyless geocoder, and a pick reuses the **same** `WeatherCard` and `ModuleModel` the dashboard renders — so search and dashboard can't drift apart.

| Debounced search | Picked city |
| --- | --- |
| ![City search results for "San"](docs/screenshots/city-search.png) | ![Current weather for the picked city](docs/screenshots/city-search-weather.png) |

This is where the Observation/Combine boundary shows up in code: view-model **state** stays on Observation, while the **stream** of keystrokes uses Combine's `debounce` — see [Decisions](#decisions). Both screens render from the real `CitySearchContentView` with fixed sample data, same pipeline as the brand gallery.

## Fork & rebrand in 3 steps

1. **Fork** this repo.
2. **Edit `Brand.json`** — name, accent color, and which modules render, in what order:
   ```json
   { "appName": "Acme Field Ops", "accentColorHex": "#E05910", "modules": ["earthquakes", "weather"] }
   ```
3. **Ship.** No code changes. To swap in your commercial data source, implement `DataProvider`
   (one file), add one entry to the module catalog, and put its id in `Brand.json` — `DashboardView`
   never changes. That swap path is the whole point of the architecture.

## Architecture

```
Brand.json ──► BrandConfig ─────────────┐  (name, accent, module order)
                                        ▼
 DataProvider (protocol) ──► ModuleModel (@Observable) ──► DashboardView
   ├── OpenMeteoProvider        │ loading / loaded / failed     │ renders whatever
   └── USGSQuakesProvider       ▼                               ▼ descriptors it gets
                          PayloadCache (actor) ──► ProviderResult(fetchedAt, isStale)
                          offline-first, corruption-as-miss     └► StalenessChip (honesty in the UI)
```

- **PulseCore** — config, provider contract, caching. UI-free, unit-testable anywhere.
- **PulseProviders** — concrete keyless-API providers; each normalizes its wire shape at one boundary.
- **PulseUI** — SwiftUI + Observation; a pure function of config and payloads.

## Decisions

| Decision | Why |
| --- | --- |
| **Observation for state, Combine for streams** | View-model state uses Observation — no `AnyCancellable` bookkeeping, compile-time observed properties, the direction Apple is investing in for iOS 17+. The one genuine *stream*, debounced city search, uses Combine's `debounce` — exactly what it's built for (`CitySearchModel`). Matching the tool to state-vs-stream beats forcing one framework everywhere. |
| **Actor cache over locks/queues** | Data-race safety by construction; the compiler enforces what a `DispatchQueue` convention only suggests. |
| **Cache exposes age, not a TTL** | "Too stale" is a product decision that differs per module and per customer; storage shouldn't decide it. |
| **Config-over-code white-labeling** | A fork-and-ship customer edits data, not Swift. Per-field decode defaults mean a broken brand file downgrades instead of crashing. |
| **Keyless public APIs** | Any reviewer can clone → build → test with zero setup. Reproducibility is a feature. |
| **SPM package, no .xcodeproj** | `swift build && swift test` works headlessly — locally and in CI — and Xcode opens the package directly. |

## Data source licensing

- **Open-Meteo** is free for **non-commercial** use ([terms](https://open-meteo.com/en/terms)). A company shipping Pulse commercially swaps in its licensed weather provider — implement `DataProvider`, register it in the catalog, done (see *Fork & rebrand*).
- **USGS** earthquake feeds are U.S. government **public domain**.

## Roadmap

- [x] docs: add README with project vision and roadmap
- [x] chore: add Swift/Xcode .gitignore
- [x] chore: add MIT license
- [x] feat: scaffold modular package targets — Core / Providers / UI (iOS 17+)
- [x] feat: add BrandConfig loader (Brand.json → name, accent, modules)
- [x] feat: add DataProvider protocol with async fetch + cache hooks
- [x] feat: add Open-Meteo weather provider (keyless) with unit tests
- [x] feat: add USGS earthquake provider (keyless) with unit tests
- [x] feat: render dashboard modules driven by config
- [x] ci: add GitHub Actions workflow (build + test, macOS runner)
- [x] docs: add multi-brand screenshots rendered from the real views
- [x] docs: add architecture notes + rebrand-in-3-steps + decisions log
