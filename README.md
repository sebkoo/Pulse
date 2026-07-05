# Pulse

**Pulse is a config-driven, white-label dashboard for iOS built over free, keyless public APIs — fork it, edit `Brand.json`, ship your own.** One JSON file controls the app's name, accent color, and which data modules render; the architecture is protocol-oriented so adding or swapping a data provider (weather, earthquakes, or your company's commercial API) requires zero UI changes. Offline-first by design: the last successful response is cached and served with its staleness, so the dashboard stays useful without a connection.

> ⚙️ **Workflow transparency:** built with an AI-assisted workflow (Claude as pair programmer — see the commit trailers); the architecture decisions, code review, and final call on every line are mine.

## Roadmap

- [x] docs: add README with project vision and roadmap
- [x] chore: add Swift/Xcode .gitignore
- [ ] chore: add MIT license
- [ ] feat: scaffold SwiftUI app target (iOS 17+)
- [ ] feat: add BrandConfig loader (Brand.json → name, accent, modules)
- [ ] feat: add DataProvider protocol with async fetch + cache hooks
- [ ] feat: add Open-Meteo weather provider (keyless) with unit tests
- [ ] feat: add USGS earthquake provider (keyless) with unit tests
- [ ] feat: render dashboard modules driven by config
- [ ] ci: add GitHub Actions workflow (build + test, macOS runner)
- [ ] docs: add architecture notes, rebrand-in-3-steps, screenshots
