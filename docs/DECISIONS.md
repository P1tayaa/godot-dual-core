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
