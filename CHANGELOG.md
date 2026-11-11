# Changelog

## 0.3.0

- `/fq shots` takes the screenshots for the gallery: the simulation frozen at one moment, a made-up character
  name, the rest of the interface hidden for the world picture. `/fq shots demo` shows the frozen simulation for
  pictures taken by hand.
- Quest arrow always points at the nearest open objective of all quests in the log (turn-in once done), from
  Questie's data. With TomTom installed, TomTom gets the target and shows its arrow. Ctrl-click in Questie still
  overrides it until you arrive.
- Spell menus on the action bar: drag a menu icon from the options (or the menu button) onto a slot; it
  creates a macro ("FQ Traps", "FQ Pet", "FQ Aspects") and the menu pops up at that slot,
  opening away from the screen edge (vertical bar on the right: to the left). The on-screen menu button hides
  while its macro is on a bar.

## 0.2.1

- `/qq` (Quiver's command) and `/quiver` open the options too.

## 0.2.0

- Own options window (sidebar with sections) instead of the Blizzard settings page.
- Simulation (options > General, or `/fq demo`): every display shows test data; combat ends it.
- Quiver options: colours for the Auto Shot timer, castbar and every range bracket (with reset), swap
  shoot/reload colours, Auto Shot bar from the left or from the middle, Tranq speech channel (none, party/raid,
  raid warning).
- Auto Shot timer shows "too close"/"too far" when Auto Shot can't reach the target.
- Range indicator measures distance with LibRangeCheck-3.0; melee spell range checks are unreliable on Forever.
- Spell menus show spells not learned yet greyed out; opening one menu closes the others.
- Key bindings in their own category; fixes for the secure menu buttons and for secret values.
- Tranq list and %t show full Forever names (first name and surname); the ammo raid warning no longer fires on
  every login or reload.

## 0.1.0

- First version: Auto Shot timer, castbar, range indicator, aspect tracker, Trueshot Aura alarm, Tranq Shot
  announcer, ammo warning, spell menus on one key, beast ability tooltip, Questie quest arrow.
