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
L["Bind the keys under Key Bindings > AddOns > Forever Quiver. While a menu is open, keys 1-9 cast its entries."] = "Tasten unter Tastenbelegung > AddOns > Forever Quiver belegen. Bei offenem Menü wirken die Tasten 1-9 die Einträge."
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
