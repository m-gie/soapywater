# Soapy Water

A Project Zomboid Build 42 mod: clean blood and grime without bleach.

- **Add soap**: right-click a container holding water (clean, tainted or carbonated, or water already mixed with soapy water) and choose *Add soap*. It works in your inventory, on the floor, in crates and on shelves, and on rain collectors and barrels; the container stays where it is. Each started litre of plain water costs 1 soap use; soap is taken from the emptiest bars first, including bars in bags. Short on soap: as much water turns soapy as your soap covers (1 L per use), and the option says how much.
- **Soapy water mixes with water**, so rain into a soapy barrel and pouring water into soapy water both work. It doesn't mix with anything else.
- **Clean Stains (Soapy Water)**: with a vanilla cleaning tool (mop, broom, sponge, towel, dish cloth, grill or toilet brush) and at least 0.5 L of water that is at least half soapy, pick stained tiles like with bleach. Each tile uses 0.5 L.
- Drinking soapy water makes you sick.

Bleach and cleaning liquid keep working as in vanilla. Lua and script files only, no Java. Both the server and every player need the mod. English and Polish.

Want to craft soap? See [Soapmaker](https://github.com/m-gie/soapmaker). The two mods don't depend on each other.

## Development

Offline tests run the pure Lua under Lua 5.1 through Python:

```
pip install lupa
python tests/run.py
```

`bash workshop.sh` stages the Workshop upload folder in `~/Zomboid/Workshop/SoapyWater`.
