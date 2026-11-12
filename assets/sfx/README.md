# Sound Effects (SFX) Assets

Expected audio files in `assets/sfx/`:
- `tap.mp3` - UI button click / tap feedback
- `slide.mp3` - Arrow escaping / sliding whoosh
- `error.mp3` - Blocked arrow buzzer / collision error
- `hint.mp3` - Hint chime
- `win.mp3` - Level victory jingle

Per specification (Section 13):
The audio service handles missing assets gracefully with `try/catch` and fails silently if sound assets are not present.
