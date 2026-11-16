# Game ideas

Ideas for more games and tools on the dual-screen core, plus what comes next for the three that exist. Each idea
says what each screen does, the hook that only works on two screens, which assets it can use, what it reuses, and a
size (S: a weekend, M: a week or two, L: more).

What the hardware gives us (RG DS, AYN Thor): two touch screens, a real gap between them (the throw demo crosses it in
real time), a gamepad, gyroscope and accelerometer, vibration. The top screen faces the table when the device lies open
on it, so the top can be the "players" screen and the bottom the "GM" screen.

## Assets on hand

| Pack | What | Licence |
|---|---|---|
| Raven Fantasy (Clockwork Raven Studios) | ~20 500 icons at 16 px (weapons, armour, potions, herbs, food, fishing, monsters, UI), 19 tilesets (dungeon, forest, village, farm, beach, cave, interiors, underworld, craft stations) | paid: copy only what a game uses, check before a public repo |
| The Roguelike (Backterria) | 16 px characters, items, spells in ten themes | unchecked |
| UI assets pack 2 | cooking and book UI (pots, knobs, cards) | unchecked |
| KayKit Board Game Bits | 3D dice, tray, pawns, cards | CC0 |

## Ideas

### Fishing at the hinge (S)

- Top: the water, a float bobbing, fish shadows moving under it.
- Bottom: the rod and the reel. Cast by flicking up (the line crosses the gap), reel by circling a finger.
- Hook: the line really passes between the screens; a bite is a vibration, then a short timing game.
- Assets: Raven fishing and sea icons, beach tileset.
- Reuses: `StirPad` from Potion Brew as the reel, the throw from the gap demo.

### Potion Shop (M)

- Top: the shop counter. Customers (roguelike characters) walk in and ask for a potion, sometimes with a twist ("cold",
  "no mushrooms").
- Bottom: the Potion Brew workbench as it is now.
- Hook: you hand the bottle over by flicking it up to the customer.
- Assets: roguelike characters, Raven potions and herbs, UI pack.
- Reuses: all of Potion Brew. This is the natural next step for that game: it gives the brewing a reason, and it is
  where an inventory starts to make sense.

### Fog of war map for the table (M)

- Top (facing the players): the dungeon map with fog. Only revealed rooms show.
- Bottom (GM): the full map. Tap a room to reveal it, drag tokens, mark traps.
- Hook: one device, two views of the same map. No laptop screen to hide behind.
- Assets: Raven green dungeon, miner's cave, underworld tilesets; Raven monster icons as tokens.
- Reuses: shared World2D (one world, two cameras, like `two_cameras`).

### Initiative and HP tracker (S)

- Top (players): turn order with portraits, whose turn, conditions as icons.
- Bottom (GM): add monsters from a list, HP buttons, conditions, next turn.
- Hook: players watch the top screen during combat; the turn timer from DM Dice drives it.
- Assets: Raven attributes and states icons (conditions), monster hunting icons.
- Reuses: `Table` turn and round counter from DM Dice. Could be a third tab in DM Dice instead of a new game.

### Mothership panic tools (S)

- Top: stress and the result of a panic roll, the panic table entry in large text.
- Bottom: crew list with stress, saves, a d100 with the under/over rule.
- Hook: the panic roll is thrown in the 3D tray like the other dice.
- Reuses: DM Dice systems (d100, custom faces) and the tray. A "Mothership" preset plus a panic table data file may
  be enough.

### Tone catcher (S)

- Top: syllables in pinyin (or hanzi) fall from the top of the top screen.
- Bottom: four baskets, one per tone. The syllable falls through the gap; slide the right basket under it.
- Hook: things fall across the hinge with the real gap delay.
- Reuses: Hanzi Cards collections and `HanziRules.tones`. Good warm-up mode before a study session.

### Brush dojo (M) (built: Hanzi Cards > Write)

- Top: the character, stroke order animated stroke by stroke.
- Bottom: write it with a finger; each stroke is checked for direction and order.
- Hook: the writing pad is the size of a real practice sheet square.
- Needs: stroke data (Make Me a Hanzi, free licence) for the characters in the collections.
- Reuses: Hanzi Cards collections. Already in the Hanzi Cards TODO as the writing pad.

### Hinge pinball (M)

- Top: the upper table with bumpers and targets.
- Bottom: flippers on the shoulder buttons, the plunger.
- Hook: the ball travels through the gap, with the gap time from the device profile. Classic dual-screen game.
- Reuses: `use_physical_world_2d`, physics rules from the throw demo (velocity steering, speed clamp).

### Card duel (L)

- Top: the board, the opponent's cards.
- Bottom: your hand. Play a card by flicking it up through the gap.
- Assets: Raven skills and spells icons as card art, UI pack card frames.
- Reuses: card physics from Hanzi Cards.

### Cozy garden (L) (started: repo `cozy-garden`)

- Top: the garden through the seasons.
- Bottom: tools and seeds; plant by dragging, water by holding.
- Hook: what grows here are Potion Brew ingredients (a shared save later).
- Assets: Raven farmlands, cozy home, places and seasons icons, herbs.

## Next for the existing games

### Potion Brew

- Potion Shop (above), then an inventory of brewed potions.
- Recipe discovery: unknown recipes show as "???" until brewed once by accident.
- Sound: bubbling grows with heat, a plop when an ingredient lands, a stir swish.
- Matching the Android 12 launch screen background colour to the boot splash.

### Hanzi Cards

- Writing pad (Brush dojo).
- Audio from Anki media.
- Stats over days (cards known per day) on the library top screen.

### DM Dice

- Remove a single die from the pool (tap its icon in the pool row).
- 3D preview in the editor.
- Initiative tracker tab.
- Value labels in the tray can sit under the timer list; move the timers or shrink the labels.

## Home screen widgets (experiment)

Android widgets are drawn by the launcher, not by the app: a few view types (text, images, buttons, lists), no
OpenGL. Godot cannot run inside one. What works:

- The widget is Kotlin in the Android plugin (an `AppWidgetProvider`, a layout XML, a widget info XML), merged into
  the app by the plugin's manifest.
- The game sends it data, or a picture it rendered itself (viewport `get_image()`, saved as PNG), through a plugin
  call. The widget shows that.
- Updates: whenever the game pushes them; when the game is closed, at most every 30 minutes, or from a WorkManager job.
- Tapping the widget opens the game, possibly on a given scene (an intent extra the plugin reads at start).

The RG DS home screen is Launcher3, which supports widgets. Not checked yet: whether the Anbernic screen on the other
display does.

First experiment, on a branch in Hanzi Cards: "character of the day" (hanzi, pinyin, meaning, box colour), tap to
study. Then a DM Dice widget with a d20 button that rolls in Kotlin without opening the game.
