# Decisions

One row per decision. Newest last.

| Date | Decision | Why |
|---|---|---|
| 2026-11-15 | Core is its own repo, every tool is a clone with core as `upstream` | Core fixes can be merged into each tool |
| 2026-11-15 | Base size per project (`dual_screen/screen/base_size`), default 320x240 at 2x | 4x fewer pixels than native on a weak GPU. 640x480 at 1x stays possible for text heavy tools |
| 2026-11-15 | Compatibility renderer (GLES3) only | Fits the Mali-G52, needed by the Android second-display plugin |
| 2026-11-15 | Font: Fusion Pixel 12px proportional, zh_hans build (OFL) | Pixel font with full CJK, about 1 MB |
| 2026-11-15 | A screen scene = one `DualScene` with two SubViewports | Both screens visible in the editor, F6 runs stacked, same shape on every backend |
| 2026-11-15 | RG DS: display 0 (where Godot runs) is the physical **bottom** screen, display 2 the top | Seen on device. `main_display_is_top=false` |
| 2026-11-15 | Android second screen transport: **GL** (Godot's viewport texture drawn on display 2 with Godot's EGL context). READBACK kept as fallback setting | Bench, 40 sprites per screen: GL 60/60 fps at ~55% CPU, READBACK 54-61 fps at ~120% CPU. GL + ON_CHANGE screen: ~34% CPU |
| 2026-11-15 | GL uses `RenderingServer.viewport_get_texture()`, not `get_texture().get_rid()` | The ViewportTexture RID is a proxy whose GL id is 0 |
| 2026-11-15 | Pointer input is touch only, mouse emulates touch | A viewport outside its container has no hover, mouse clicks never reach it |
| 2026-11-15 | Device profiles (`data/devices/*.tres`) replace the single base size setting; each screen has its own size | Devices differ (AYN Thor: 1920x1080 top, 1240x1080 bottom). Gap and offset are data, calibrated on the device |
| 2026-11-15 | Physical 2D world in millimetres shared by both screens, cameras placed like the real panels | A thrown object crosses the real hinge gap. RG DS check: 415 mm/s flick peaks 27 mm above the bottom screen, 79 ms in the 22 mm gap |
| 2026-11-15 | Grabbed physics bodies are steered by velocity, never frozen and moved | Moving a frozen RigidBody2D between physics steps was undone by the next step on the device (input arrives off-step) |
| 2026-11-15 | Containers over a touch area use `mouse_filter = IGNORE` | A full-width button row swallowed touches on the area under it |
| 2026-11-15 | First second of a 3D example drops to ~16-23 fps on the RG DS, then 60 | Shader compilation on first use (Mali). Measure fps after a warm-up |
| 2026-11-15 | `DualScene.pixel_scale`: a scene can render at 2x (native 640x480 on the RG DS) and keep base-size coordinates (`size_2d_override`) | Hanzi need the panel's real pixels. Pushed touch is scaled by hand: `push_input` does not apply the 2D override |
| 2026-11-15 | MSDF text is drawn with `texture_filter = LINEAR` on its node | Viewports default to nearest for pixel art; a nearest-sampled MSDF atlas gives staircase edges at large sizes |
| 2026-11-15 | Hanzi fonts: LXGW WenKai (kaiti, textbook stroke shapes) for hanzi, pinyin and meanings; Ma Shan Zheng (brush) as the alternative hanzi font. Both OFL, subset to the decks' characters | 26 MB + 6 MB down to 77 KB + 23 KB. Ma Shan Zheng has no tone-mark letters, so pinyin always uses WenKai |
| 2026-11-15 | Decks are TSV files (`data/hanzi/*.tsv`) turned into `.tres` by `tools/make_hanzi_deck.gd`; tones come from the pinyin marks (`HanziRules.tones`) | Editing a deck is editing a spreadsheet; no tone data to keep in sync |
