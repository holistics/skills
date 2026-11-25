## [0.4.1](https://github.com/holistics/skills/compare/holistics-reporting-v0.4.0...holistics-reporting-v0.4.1) (2026-11-24)

### Bug Fixes

* **plugins.development,plugins.reporting:** list proposal choices as numbered options ([de82057](https://github.com/holistics/skills/commit/de820576e0a4eab86a5c0317df64dd051ecd67c8))

## [0.4.0](https://github.com/holistics/skills/compare/holistics-reporting-v0.3.4...holistics-reporting-v0.4.0) (2026-11-18)

### Features

* **native.system,plugins.reporting:** make a creative look the build-data-app default ([b7b840b](https://github.com/holistics/skills/commit/b7b840b5cea1b04476c2aafaf1aab895adbd8a4b))
* **native.system,plugins.reporting:** mirror the new build-data-app flow in Holistics AI ([901c538](https://github.com/holistics/skills/commit/901c5389c7cd4e76a9e3d22377f235d91e656222))
* **native.system,plugins.reporting:** offer look and brand choices on the build-data-app proposal ([2376d57](https://github.com/holistics/skills/commit/2376d57118ab281a033b2f26c16487e0188cdfcd))
* **plugins.development,plugins.reporting:** add the Holistics icon to the plugin listings ([1faba75](https://github.com/holistics/skills/commit/1faba75e99fdb02f948da9ed7ec76669f6884c33))
* **plugins.reporting:** plan build-data-app around the Holistics tools and a wireframe ([c2fbe32](https://github.com/holistics/skills/commit/c2fbe32f8f5da8a4540dee721e94986c63afcf40))

### Bug Fixes

* **native.system,plugins.reporting:** address build-data-app review feedback from Hoa ([a122ffa](https://github.com/holistics/skills/commit/a122ffa505c18361b3aeae61bd0377b3f6cefa65))
* **native.system,plugins.reporting:** cap build-data-app rows with pageSize, not AQL limit ([33f088f](https://github.com/holistics/skills/commit/33f088f4a649925bd9397894a4585e5f8703aa0c))
* **native.system,plugins.reporting:** draw a build-data-app sidebar without nested blocks ([76db452](https://github.com/holistics/skills/commit/76db4523b90e7522f91a95c3d9f80cd90ee0378e))
* **native.system,plugins.reporting:** draw build-data-app maps from a fetched GeoJSON ([d4e5129](https://github.com/holistics/skills/commit/d4e51294af2cc02a188e6dd1db9b9f5259568513))
* **native.system,plugins.reporting:** drop the workspace from the build-data-app proposal ([6e889a7](https://github.com/holistics/skills/commit/6e889a765568443019334d46e18a8afda5162561))
* **native.system,plugins.reporting:** keep the build-data-app wireframe colors fixed ([05ded6f](https://github.com/holistics/skills/commit/05ded6f8483fe8454698314065835f7db0884c9d))
* **native.system,plugins.reporting:** match build-data-app font choices to the hash rule ([157638b](https://github.com/holistics/skills/commit/157638bb41165a7bc00623cf6202cebbf7b626a5))
* **native.system,plugins.reporting:** scope build-data-app's limit rule to Data Apps ([8a60ba8](https://github.com/holistics/skills/commit/8a60ba82ee0bea10295337f7619b203d7f420e2c))
* **plugins.common,plugins.development,plugins.reporting:** rename .upstream notes to UPSTREAM.md ([809b26c](https://github.com/holistics/skills/commit/809b26c55b7a0a774b3c2f1d2fec49eeb716abdd))
* **plugins.development,plugins.reporting:** drop fixed choices from the authoring_mode setting ([13406fe](https://github.com/holistics/skills/commit/13406fe609899dd15b1e330bbb1534efa02c7346))
* **plugins.reporting:** call Claude Dashboards Claude Data dashboards ([6de03d8](https://github.com/holistics/skills/commit/6de03d82eff7139a34ca2103183601ff10559080))
* **plugins.reporting:** give build-data-app's proposal a plain-text fallback ([fc60e4b](https://github.com/holistics/skills/commit/fc60e4b8142d08b3bd0bf12a1d5ebee878b7a942))
* **plugins.reporting:** run build-data-app queries and stop when create_data_app is missing ([e6847e9](https://github.com/holistics/skills/commit/e6847e93309bf05015f42d984bfcde15bba50f9a))
* **plugins.reporting:** ship the build-data-app example as Markdown ([41f7923](https://github.com/holistics/skills/commit/41f792363423f77ef7156e9b745f0ac026fccd69))
* **plugins.reporting:** spell out which build-data-app steps a conversion skips ([099de3b](https://github.com/holistics/skills/commit/099de3b825fc4a5740a63ef18876fc39cefef007))

## [0.3.4](https://github.com/holistics/skills/compare/holistics-reporting-v0.3.3...holistics-reporting-v0.3.4) (2026-11-09)

### Bug Fixes

* **plugins.common,plugins.development,plugins.reporting:** drop Endorsed tags from AML examples ([fd493c9](https://github.com/holistics/skills/commit/fd493c9e4182663259c38501cfebe3cc3925b459))

### Performance Improvements

* **plugins.reporting:** trim build-data-app repetition to cut its context size ([8f9b4fa](https://github.com/holistics/skills/commit/8f9b4fa29bef527246c97c56c735e331a688cd82))

## [0.3.3](https://github.com/holistics/skills/compare/holistics-reporting-v0.3.2...holistics-reporting-v0.3.3) (2026-11-04)

### Bug Fixes

* **plugins.common,plugins.reporting:** rename sync-code to sync ([6e542d2](https://github.com/holistics/skills/commit/6e542d274f10766a56e5eddaa2508fca89634f11))

## [0.3.2](https://github.com/holistics/skills/compare/holistics-reporting-v0.3.1...holistics-reporting-v0.3.2) (2026-11-03)

### Bug Fixes

* filter on measures ([d0188b9](https://github.com/holistics/skills/commit/d0188b91c9715394ca35a5df64260841aa0fb184))

## [0.3.1](https://github.com/holistics/skills/compare/holistics-reporting-v0.3.0...holistics-reporting-v0.3.1) (2026-10-30)

### Features

* **plugins.reporting:** refuse to convert a plain HTML artifact ([2c53ba8](https://github.com/holistics/skills/commit/2c53ba84c75a63f714a9368d310f69634e1f1783))
* **plugins.reporting:** warn that an uploaded file converts as static data ([8e34c5f](https://github.com/holistics/skills/commit/8e34c5fc12d4f06953296c5c70eef2572c1b5309))

### Bug Fixes

* **plugins.reporting:** keep the dashboard's look when converting it to a Data App ([205b0ee](https://github.com/holistics/skills/commit/205b0ee8918de0d375d468de7598891f27423153))

## [0.3.0](https://github.com/holistics/skills/compare/holistics-reporting-v0.2.0...holistics-reporting-v0.3.0) (2026-10-27)

### Features

* **plugins.reporting:** add build-data-app skill ([9c5a4f9](https://github.com/holistics/skills/commit/9c5a4f92ef612b35e3d9385b5517c76ac721a145))

## [0.2.0](https://github.com/holistics/skills/compare/holistics-reporting-v0.1.2...holistics-reporting-v0.2.0) (2026-10-22)

### Features

* add skill to author viz ([1743d19](https://github.com/holistics/skills/commit/1743d19e184b0230e9cab11ba5592fcceb719c19))
* **plugins.development:** improving CLI calling ([50e23f5](https://github.com/holistics/skills/commit/50e23f5121a1e0a6dd4dc026fe94b0de13a8a67d))
* **plugins.development:** local aql skills ([04d5471](https://github.com/holistics/skills/commit/04d5471fc9bd484948de163122fd6ee3c888aa10))
* update AML definitions ([bd691f2](https://github.com/holistics/skills/commit/bd691f2b26192f1c66936821f2147b96f66f93e1))

### Bug Fixes

* **native.system,plugins.common,plugins.development:** split autorun into on_open and on_changes ([cbcdc37](https://github.com/holistics/skills/commit/cbcdc379f259c0c7bcc40e785ab8c01cfb188554))

## [0.1.2](https://github.com/holistics/skills/compare/holistics-reporting-v0.1.1...holistics-reporting-v0.1.2) (2026-06-19)

### Bug Fixes

* **plugins.common:** default AML field references to the new r() syntax ([f51b538](https://github.com/holistics/skills/commit/f51b5381595bea97cbd885663595cfcbf83ebce4))

## [0.1.1](https://github.com-holistics/holistics/skills/compare/holistics-reporting-v0.1.0...holistics-reporting-v0.1.1) (2026-06-04)

### Bug Fixes

* **plugins.common,plugins.development,plugins.reporting:** document search_docs question param ([8350777](https://github.com-holistics/holistics/skills/commit/8350777b5275be0e6f0f09c8605a2d184b5396be))

## [0.1.0](https://github.com/holistics/skills/compare/holistics-reporting-v0.0.4...holistics-reporting-v0.1.0) (2026-05-13)

### Features

* update mcp to use OAuth ([e559e34](https://github.com/holistics/skills/commit/e559e349365e2b0d19052378fe19ec9190ca2789))

## [0.0.4](https://github.com/holistics/skills/compare/holistics-reporting-v0.0.3...holistics-reporting-v0.0.4) (2026-04-27)

## 0.0.3 (2026-04-08)

### Features

* improve mcp setup ([168ea57](https://github.com/holistics/skills/commit/168ea57d6b25050af667cdaf91998a8b36e335db))

## 0.0.2 (2026-04-04)

### Features

* various improvements ([5ed2e38](https://github.com/holistics/skills/commit/5ed2e382a78dd7d8ccabe2aff78c0bd57966b860))
