# DataQuest v1.1 — Release Checklist

This checklist closes Expansion Item 11.

## Automated gates

The GitHub Actions release workflow must pass:
- `flutter analyze`
- the complete Flutter test suite
- accessibility tap-target checks
- content-asset budget checks
- debug APK build
- release Android App Bundle build
- ARM32, ARM64 and x86_64 split release APK builds
- release-size budgets
- artifact upload

## Manual Android QA

Before public distribution, install the ARM64 release APK on at least one representative physical Android phone and verify:
- first launch and offline startup,
- Home “what to do next” navigation,
- SQL, Spreadsheet/Cleaning, Pandas and Analytics labs,
- Daily Challenge and review queue,
- interview flow,
- Portfolio PDF generation/share,
- backup create/restore,
- reminders and notification deep links,
- dark/light themes,
- text scaling and screen rotation where supported,
- airplane-mode core learning.

For a 2 GB RAM target device, repeat the main labs after a cold launch and confirm no obvious memory-pressure restart loop.

## Production signing

Use the owner-controlled Android production keystore. Do not commit keystore files, passwords or signing properties. Build the Play artifact with:

`flutter build appbundle --release`

For direct APK distribution:

`flutter build apk --release --split-per-abi`

## Play Store readiness

Before upload:
- choose the permanent application ID,
- configure production signing,
- prepare privacy policy and Data Safety declarations,
- disclose optional account/cloud behavior,
- provide screenshots and store copy,
- confirm target SDK requirements in the current Play Console,
- upload to Internal Testing first,
- test install/update from Play,
- use staged rollout for production.

DataQuest must remain usable offline without Supabase or the remote weekly-case URL.
