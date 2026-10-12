# Third-party notices

Data, artwork, and libraries shipped in AirRaid that require attribution. The in-app licenses screen
must show the credits below.

## Map data

| What | Where | Source | License |
|---|---|---|---|
| Oblast boundaries | `AirRaid/Resources/Map/ukraine-oblasts.geojson` | Union of the raion boundaries below (Kyiv and Sevastopol from the same dataset) | [CC BY-IGO 3.0](https://creativecommons.org/licenses/by/3.0/igo/) — credit "OCHA, Ukraine Subnational Administrative Boundaries" |
| Raion boundaries | `AirRaid/Resources/Map/ukraine-raions.geojson` | [OCHA — Ukraine Subnational Administrative Boundaries](https://data.humdata.org/dataset/cod-ab-ukr) (COD-AB, ADM2, v05, valid on 2025-09-01), simplified (topology-preserving, 0.004°); Kyiv and Sevastopol moved to the oblast file; the Chornobyl exclusion zone (UA3200) merged into Vyshhorod raion (UA3210), which it belongs to administratively | [CC BY-IGO 3.0](https://creativecommons.org/licenses/by/3.0/igo/) — credit "OCHA, Ukraine Subnational Administrative Boundaries" |
| Regional centers | `AirRaid/Resources/Map/ukraine-regional-centers.json` | Compiled for AirRaid (names and approximate coordinates) | — |
| Base map tiles and style | Loaded at runtime from `tiles.openfreemap.org` | [OpenFreeMap](https://openfreemap.org), OpenMapTiles schema, OpenStreetMap data | Credit "OpenFreeMap © OpenMapTiles Data from OpenStreetMap" (shown by the map's ⓘ button) |

## Artwork

| What | Where | Source | License |
|---|---|---|---|
| Shahed silhouette | `AirRaid/Assets.xcassets/Threats/threat-shahed.imageset` | Traced from [Shahed-136-350-250draw.svg](https://commons.wikimedia.org/wiki/File:Shahed-136-350-250draw.svg) by Alexpl; reduced to a simplified silhouette | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| Other threat silhouettes | `AirRaid/Assets.xcassets/Threats/` | Original artwork for AirRaid | — |

## Fonts

| What | Where | Source | License |
|---|---|---|---|
| Manrope (variable, weights 200–800) | `AirRaid/Resources/Fonts/Manrope-Variable.ttf` | [google/fonts — ofl/manrope](https://github.com/google/fonts/tree/main/ofl/manrope), Copyright 2018 The Manrope Project Authors | [SIL OFL 1.1](https://openfontlicense.org) — license text shipped as `AirRaid/Resources/Fonts/Manrope-OFL.txt` |

## Libraries

| Library | License |
|---|---|
| [MapLibre Native](https://github.com/maplibre/maplibre-native) | BSD 2-Clause |
