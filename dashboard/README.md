# BlipRadius Dashboard

Flutter Web front end for the BlipRadius server. It shows the API dependency map, the blast radius of a spec change, the API hub and generated changelogs.

## Screens

| Screen | What it shows |
|---|---|
| Estate map (`graph_screen.dart`) | APIs, flows and consumers as a dependency graph, with impact paths highlighted |
| API hub (`api_hub_screen.dart`) | Every API in the estate, its consumers and freshness |
| Changelog (`changelog_screen.dart`) | Classified changes: breaking, added, changed, removed |
| Sources (`sources_screen.dart`) | Anypoint connection and repos to scan, with sync progress |

## Run

Start the server first (see the main [README](../README.md)), then:

```bash
flutter pub get
flutter run -d chrome     # talks to the server on http://localhost:8080
```

## Test

```bash
flutter test
```

The widget tests run against a fake API client, so they need no server.
