# App vs TTS localization (TranZfort)

## When to use which ARB

| File | Purpose | Examples |
|------|---------|----------|
| `lib/l10n/app_en.arb` / `app_hi.arb` | On-screen UI labels, buttons, errors | Settings title, form labels, status chips |
| `lib/l10n/tts/tts_en.arb` / `tts_hi.arb` | Spoken-only phrases (TTS / read-aloud) | Load card summaries, booking notification speech |

**Rule:** Do not put long spoken sentences in `app_*.arb`. Do not put short UI chrome in `tts_*.arb`.

## Codegen

After editing either set:

```powershell
cd TranZfort
powershell -ExecutionPolicy Bypass -File tool\gen_tts_l10n.ps1
```

This regenerates both `AppLocalizations` and `TtsLocalizations`.

## Wiring pattern

1. Build utterance in `lib/src/features/tts/data/*_tts_builder.dart` using `TtsLocalizations`.
2. Pass localized **display** labels from `AppLocalizations` into builders when needed.
3. Use `TtsCardSpeakerButton` on cards; respect `ttsAudioLanguageProvider` for spoken language.

See [TTS-29-may.md](./TTS-29-may.md) for architecture and phases.
