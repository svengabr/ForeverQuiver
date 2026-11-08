const fs = require('fs');
const src = fs.readFileSync(process.argv[2], 'utf8').split(/\r?\n/);
let cur = null, inCrs = false;
const npc = {}; const names = {}; const ranks = {};
for (const line of src) {
  let m = line.match(/recipeID\s*=\s*(\d+),\s*--\s*(.+?)\s*\[Rank (\d+)\]/);
  if (m) { cur = +m[1]; names[cur] = m[2]; ranks[cur] = +m[3]; inCrs = false; continue; }
  if (/crs\s*=\s*\{/.test(line)) { inCrs = true; continue; }
  if (inCrs && /^\s*\},/.test(line)) { inCrs = false; continue; }
  if (inCrs && cur) {
    m = line.match(/^\s*(\d+),\s*--\s*(.*)$/);
    if (m) { (npc[m[1]] = npc[m[1]] || []).push(cur); }
  }
}
let out = '-- Generated from AllTheThings (.contrib/.db/forever/character/hunter/beast training.lua).\n';
out += '-- Maps a tameable NPC ID to the Beast Training spell IDs (ability ranks) it teaches on WoW: Forever.\n';
out += '-- Regenerate with tools/gen_beast.js; do not edit by hand.\nlocal _, ns = ...\n\nns.BeastRank = { -- spellID = { rank, English name }\n';
for (const id of Object.keys(ranks).sort((a,b)=>a-b)) out += `\t[${id}] = { ${ranks[id]}, "${names[id]}" },\n`;
out += '}\n\nns.BeastAbilities = {\n';
for (const id of Object.keys(npc).sort((a,b)=>a-b)) out += `\t[${id}] = { ${npc[id].join(', ')} },\n`;
out += '}\n';
fs.writeFileSync(process.argv[3], out);
console.log(Object.keys(npc).length, 'npcs', Object.keys(ranks).length, 'ranks');
