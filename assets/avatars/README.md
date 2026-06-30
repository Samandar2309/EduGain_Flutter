# Realistic avatar images (drop your renders here)

The Speaking screen shows a photoreal character per scenario when the matching
image exists here. If it's missing, the app falls back to the built-in
procedural avatar automatically — so the app always works.

## File names (one per scenario key)

| Scenario | base image (required) | mouth-open (optional, for lip-sync) |
|----------|-----------------------|-------------------------------------|
| Coffee Shop / Barista | `coffee.png` | `coffee_talk.png` |
| Airport | `airport.png` | `airport_talk.png` |
| Restaurant | `restaurant.png` | `restaurant_talk.png` |
| Hotel | `hotel.png` | `hotel_talk.png` |
| Job Interview | `interview.png` | `interview_talk.png` |
| Doctor | `doctor.png` | `doctor_talk.png` |
| IELTS | `ielts.png` | `ielts_talk.png` |
| Shopping | `shopping.png` | `shopping_talk.png` |
| (fallback for anything else) | `default.png` | `default_talk.png` |

## Image spec
- **Transparent PNG**, character bust (head + shoulders), centered.
- ~**900×900** px (square), the character filling ~80% of the frame.
- Same framing/scale between `X.png` and `X_talk.png` so they overlay cleanly.
- `X_talk.png` = the SAME render with the **mouth open** (talking). The app
  cross-fades base → talk with the live voice loudness, giving lip-sync.
- Generate with your image tool (the one that made the mockups) — e.g.
  "3D Pixar-style friendly barista, bust, transparent background, mouth closed".

After adding images, run the app again (they're bundled at build time).
