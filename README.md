# Soapy Water

A Project Zomboid Build 42 mod: clean blood and grime without bleach.

- **Add soap**: right-click a container holding only water (clean or tainted) and choose *Add soap*. Each started litre costs 1 soap use; soap is taken from the emptiest bars first, including bars in bags. Not enough soap: the option is greyed out and says how much you need.
- **Clean Stains (Soapy Water)**: with a vanilla cleaning tool (mop, broom, sponge, towel, dish cloth, grill or toilet brush) and at least 0.5 L of soapy water, pick stained tiles like with bleach. Each tile uses 0.5 L.
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
