-- Strings. Keys are English; deDE overrides below. Missing keys fall back to the key itself.
local _, ns = ...

local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

if GetLocale() ~= "deDE" then return end

L["Casting Tranq Shot"] = "Tranquilizing Shot auf %t"
L["*** MISSED Tranq Shot ***"] = "*** Tranquilizing Shot VERFEHLT ***"
L["Frames locked."] = "Rahmen gesperrt."
L["Frames unlocked. Drag them, then /fq lock."] = "Rahmen entsperrt. Verschieben, danach /fq lock."
L["Positions reset."] = "Positionen zurückgesetzt."

-- frame labels
L["Auto Shot"] = "Automatischer Schuss"
L["Castbar"] = "Zauberleiste"
L["Range"] = "Reichweite"
L["Aspect"] = "Aspekt"
L["Trueshot Aura"] = "Aura des Volltreffers"
L["Tranq Shot"] = "Tranq-Schuss"
L["Ammo"] = "Munition"
L["Traps"] = "Fallen"
L["Pet"] = "Begleiter"
L["Aspects"] = "Aspekte"
L["Quest arrow"] = "Questpfeil"

-- auto shot
L["too close"] = "zu nah"
L["too far"] = "zu weit"

-- range
L["Melee Range"] = "Nahkampf"
L["Dead Zone"] = "Tote Zone"
L["Scare Beast"] = "Wildtier ängstigen"
L["Scatter Shot"] = "Streuschuss"
L["Short Range"] = "Kurze Distanz"
L["Long Range"] = "Lange Distanz"
L["Hunter's Mark"] = "Mal des Jägers"
L["Out of Range"] = "Außer Reichweite"
L["Beast"] = "Wildtier"

-- ammo
L["Ammo: %d"] = "Munition: %d"
L["No ammo!"] = "Keine Munition!"
L["Ammo low: %d left"] = "Munition knapp: noch %d"

-- trueshot
L["missing"] = "fehlt"

-- beast lore
L["Beast Training:"] = "Wildtierausbildung:"
L["%s (Rank %d)"] = "%s (Rang %d)"
L["known"] = "bekannt"
L["new"] = "neu"

-- nav
L["Arrived"] = "Angekommen"
L["Other continent"] = "Anderer Kontinent"
L["Right-click to clear"] = "Rechtsklick zum Entfernen"
L["Usage: /fq way <x> <y> [title]"] = "Benutzung: /fq way <x> <y> [Titel]"
L["Waypoint set: %s"] = "Wegpunkt gesetzt: %s"

-- bindings
L["%s: you don't know any of these spells yet."] = "%s: Du kennst noch keinen dieser Zauber."
L["Open trap menu"] = "Fallen-Menü öffnen"
L["Open pet menu"] = "Begleiter-Menü öffnen"
L["Open aspect menu"] = "Aspekt-Menü öffnen"

-- options
L["Hunter utilities for WoW: Forever, inspired by Quiver (Turtle WoW)."] = "Jäger-Werkzeuge für WoW: Forever, nach dem Vorbild von Quiver (Turtle WoW)."
L["Unlock frames"] = "Rahmen entsperren"
L["Lock frames"] = "Rahmen sperren"
L["Reset positions"] = "Positionen zurücksetzen"
L["Auto Shot timer"] = "Auto-Shot-Timer"
L["Red = reloading, yellow = aiming (stand still)."] = "Rot = Nachladen, Gelb = Zielen (stillstehen)."
L["Width"] = "Breite"
L["Height"] = "Höhe"
L["Show seconds"] = "Sekunden anzeigen"
L["Castbar (Aimed Shot, Multi-Shot, Steady Shot)"] = "Zauberleiste (Gezielter Schuss, Mehrfachschuss, Zuverlässiger Schuss)"
L["Only hunter shots"] = "Nur Jägerschüsse"
L["Range indicator"] = "Reichweitenanzeige"
L["Aspect tracker"] = "Aspekt-Anzeige"
L["Hide while in"] = "Ausblenden bei"
L["Size"] = "Größe"
L["Trueshot Aura alarm"] = "Volltreffer-Aura-Alarm"
L["Warn when less than (seconds)"] = "Warnen unter (Sekunden)"
L["Tranq Shot announcer"] = "Tranq-Schuss-Ansage"
L["Announce in party/raid"] = "In Gruppe/Schlachtzug ansagen"
L["Show hunters' Tranq cooldowns"] = "Tranq-Abklingzeiten aller Jäger zeigen"
L["Cast message (%t = target)"] = "Nachricht beim Wirken (%t = Ziel)"
L["Miss message"] = "Nachricht bei Verfehlen"
L["Ammo warning"] = "Munitionswarnung"
L["Warn below"] = "Warnen unter"
L["Play sound"] = "Ton abspielen"
L["Spell menus (one key opens a drop-down)"] = "Zaubermenüs (eine Taste öffnet ein Drop-down)"
L["Bind the keys under Key Bindings > Forever Quiver. While a menu is open, keys 1-9 cast its entries."] = "Tasten unter Tastenbelegung > Forever Quiver belegen. Bei offenem Menü wirken die Tasten 1-9 die Einträge."
L["Show menu buttons on screen"] = "Menü-Knöpfe auf dem Bildschirm zeigen"
L["Open upwards"] = "Nach oben öffnen"
L["Beast ability tooltip"] = "Wildtier-Fähigkeiten im Tooltip"
L["Shows which pet ability a tameable beast teaches."] = "Zeigt, welche Begleiterfähigkeit ein zähmbares Wildtier lehrt."
L["Only abilities you don't know yet"] = "Nur Fähigkeiten, die du noch nicht kennst"
L["Also for other classes"] = "Auch für andere Klassen"
L["Quest arrow (Questie)"] = "Questpfeil (Questie)"
L["Ctrl-click a Questie map icon or quest in the tracker to point the arrow there."] = "Strg-Klick auf ein Questie-Kartensymbol oder eine Quest im Tracker richtet den Pfeil dorthin."
L["Show arrow"] = "Pfeil zeigen"
L["Also set the game's map pin"] = "Zusätzlich die Karten-Markierung des Spiels setzen"
L["Some changes to menus apply after combat."] = "Manche Änderungen an Menüs greifen erst nach dem Kampf."
L["None"] = "Keiner"

-- options window
L["%d s"] = "%d s"
L["General"] = "Allgemein"
L["Frames"] = "Rahmen"
L["Positions"] = "Positionen"
L["While unlocked, every frame shows a green box you can drag."] = "Entsperrt zeigt jeder Rahmen einen grünen Kasten, den du verschieben kannst."
L["/fq opens this window, /fq lock and /fq unlock move frames, /fq debug prints range data."] = "/fq öffnet dieses Fenster, /fq lock und /fq unlock zum Verschieben, /fq debug gibt Reichweitendaten aus."
L["Bar direction"] = "Richtung der Leiste"
L["Left to right"] = "Links nach rechts"
L["Both sides"] = "Von der Mitte aus"
L["Shooting"] = "Zielen"
L["Reloading"] = "Nachladen"
L["Shoot / Reload"] = "Zielen / Nachladen"
L["Swap colours"] = "Farben tauschen"
L["Aimed Shot, Multi-Shot and Steady Shot. Off: every cast with a cast time."] = "Gezielter Schuss, Mehrfachschuss und Zuverlässiger Schuss. Aus: jeder Zauber mit Zauberzeit."
L["Casting"] = "Zaubern"
L["Aspects & Trueshot"] = "Aspekte & Volltreffer"
L["Warn when less than"] = "Warnen unter"
L["Tranq speech"] = "Tranq-Ansage"
L["Party / raid"] = "Gruppe / Schlachtzug"
L["Raid warning"] = "Schlachtzugswarnung"
L["Raid warning needs raid lead or assist; otherwise it falls back to the raid channel."] = "Schlachtzugswarnung braucht Leiter- oder Assistentenrechte, sonst geht die Ansage in den Schlachtzugskanal."
L["Cast message"] = "Nachricht beim Wirken"
L["%t is replaced with your target's name."] = "%t wird durch den Namen deines Ziels ersetzt."
L["Needs the combat log, which this client may keep from addons."] = "Braucht das Kampflog, das dieser Client Addons eventuell vorenthält."
L["Yellow below the threshold, red below a quarter of it."] = "Gelb unter der Schwelle, rot unter einem Viertel davon."
L["Spell menus"] = "Zaubermenüs"
L["Menu opens"] = "Menü öffnet"
L["Upwards"] = "Nach oben"
L["To the right"] = "Nach rechts"
L["Beast abilities"] = "Wildtier-Fähigkeiten"
L["Reset to default"] = "Auf Standard zurücksetzen"
L["Options"] = "Optionen"
L["Open options window"] = "Optionsfenster öffnen"

-- simulation
L["Simulation"] = "Simulation"
L["Start simulation"] = "Simulation starten"
L["Stop simulation"] = "Simulation beenden"
L["All displays show test data, so you can look at colours and sizes. Combat ends it. Also /fq demo."] = "Alle Anzeigen zeigen Testdaten, damit du Farben und Größen ansehen kannst. Kampf beendet sie. Auch per /fq demo."
L["Simulation ended (combat)."] = "Simulation beendet (Kampf)."
L["Demo target"] = "Testziel"
