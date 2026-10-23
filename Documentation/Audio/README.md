# FantasiVen audio

All playback is bundled and offline. No attribution screen is required.

## CC0 interface effects
Source: Kenney, Interface Sounds
https://kenney.nl/assets/interface-sounds
https://kenney.nl/support
Download: https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip
Retrieved: 2026-10-23.
License: Creative Commons CC0 1.0; see Kenney-License.txt.
Selected originals: click_001/002/003, pluck_001/002, drop_001, confirmation_001.
Modifications: Ogg to 16-bit PCM WAV, short edge fades and peak normalization.
The Kenney name/logo is not used as app branding.

## Original music
music_garden, music_dream and music_workshop were generated specifically
for this project by tools/generate_audio.py. These are original programmed
compositions and synthesized instruments, without external recordings,
samples or pre-existing melodies. No third-party music credit is required.
They use 16-bar arrangements, stereo placement and circular delay tails.
Garden: 88 BPM, 43.64 s. Dream: 72 BPM, 53.33 s.
Workshop: 96 BPM, 40 s.

## Development
Install numpy and soundfile in your development Python environment.
Download the official archive above to tools/kenney_interface-sounds.zip.
Run python tools/generate_audio.py, then python tools/generate_project.py.
Neither Python nor these packages are part of the app.
SwiftPM processes Resources; Xcode explicitly bundles every Audio/*.wav.
Missing files fall back to the existing synthesized cues.
Music remains opt-in; existing saved preferences are preserved.
Device listening and Apple compilation have not been performed for this change.

## Contextual effects
Nine original Foley-inspired synthesized WAV effects are generated with tools/generate_foley.py (Python standard library). They contain no third-party samples and require no third-party credit. Pour flour/water/oil, mixing, oven, munch, bubble, fruit catch and bounce have distinct sounds.
