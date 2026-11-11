# Forever Quiver

Hunter utilities for **WoW: Forever**, modelled on [Quiver](https://github.com/SabineWren/Quiver) for Turtle WoW.
Written from scratch for the Forever client (modern API, Interface 16001); no Quiver code is reused.

Open the options window with `/fq` (or Settings → AddOns → Forever Quiver → Open options window). Colours,
sizes, bar direction and the Tranq speech channel can be changed there, as in Quiver.

## Features

- **Auto Shot timer** – red bar = reloading, yellow bar = aiming (stand still). Size adjustable, small by default.
- **Castbar** – Aimed Shot, Multi-Shot, Steady Shot (or every cast).
- **Range indicator** – melee, dead zone, Scare Beast, Scatter Shot, short/long range, Hunter's Mark, out of range.
  Uses spell range checks, no action bar setup needed.
- **Aspect tracker** – shows your aspect unless it is the one you chose to hide (Hawk by default); red border on
  Cheetah/Pack, faded reminder when no aspect is up.
- **Trueshot Aura alarm** – if talented: warns when the aura is missing or about to run out.
- **Tranq Shot announcer** – announces Tranquilizing Shot in party/raid and lists the Tranq cooldown of every
  hunter running Forever Quiver.
- **Ammo warning** – count on screen when ammo runs low, with a sound and raid warning once.
- **Spell menus on one key** – Traps, Pet and Aspects each get a button and a key binding
  (Key Bindings → Forever Quiver). The key opens the menu; keys 1–9 then cast its entries.
  Drag a menu icon from the options onto an action bar slot and the menu pops up at that slot (Blizzard bars;
  this creates the general macros "FQ Traps", "FQ Pet" and "FQ Aspects").
- **Beast ability tooltip** – mouse over a tameable beast to see which pet ability (and rank) taming it teaches,
  marked *new* or *known*. Data from AllTheThings' WoW: Forever beast training list.
- **Quest arrow for Questie** – always points at the nearest open objective of every quest in your log (the
  turn-in once a quest is done), using Questie's data. With TomTom installed, TomTom gets the target and its arrow
  shows the way. Ctrl-click a Questie map icon or tracker quest to send it somewhere else until you arrive;
  `/fq way 45.2 67.8 [title]` sets a waypoint by hand, `/fq clear` removes it.

## Commands

| Command | |
|---|---|
| `/fq`, `/qq`, `/quiver` | options window |
| `/fq unlock`, `/fq lock` | move frames |
| `/fq reset` | reset positions |
| `/fq demo` | simulation: all displays show test data |
| `/fq shots` | takes the gallery screenshots with the simulation frozen; `/fq shots demo` only freezes it |
| `/fq way <x> <y> [title]`, `/fq clear` | waypoint |

## Libraries

Embedded in `Libs/`: LibStub, CallbackHandler-1.0 and LibRangeCheck-3.0 (MIT, mitch0 and the WoWUIDev community),
used for distance brackets because melee spell range checks are unreliable on the Forever client.

## Known limits

- Tranq *miss* announcements need the combat log, which clients with secret restrictions don't give addons.
- "Known" in the beast tooltip relies on the client reporting learned Beast Training ranks as known spells.
