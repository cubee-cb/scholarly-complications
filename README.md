# Scholarly Complications
https://cubee.games/?rel=PICO-8&sub=scholarly_complications
A PICO-8 beat-em-up game about a bored teenager, her incredibly cool and underappreciated music teacher, and the sudden occurrence of a zombie apocalypse.

## Game data
```
beatem.p8 - The main gameplay code, music and sound effects.
beatem-title.p8 - Starts new games and loads old ones.
beatem-cutscenes.p8 - Plays cutscenes and handles loading the next area cart.
a#.p8 - Area carts. Includes the main source, and specific actor/stage data for an area.

beatem-init.p8l - Contains some common functions that all the carts can use.
beatem-data.p8l - Stats and sprite definitions for objects.
beatem-levels.p8l - Level storage.
beatem-gfx-maps.p8 - Stage graphics and flag data storage. Stage chunks are stored in the map.
beatem-gfx-actors.p8 - Graphics for the actors.


```

## Tools
```
beatem-editor.p8 - Level builder. Put its output strings into beatem-levels.p8l.
beatem-multispr-editor.p8 - For creating strings for use with the MULTISPR() function.
beatem-wobblepaint.p8 - A slightly modified version of zep's Wobblepaint.
beatem-packer.p8 - Compresses the beatem-gfx carts with zep's PX9 and writes them to the main cart, and additionally copies the map and flag data from the maps cart.
beatem-hiteffects.p8 - Small cart to build and view effects in.
font-snippet.p8 - Modified version of Zep's custom font snippet that uses less characters for the output string. Store font inside beatem-title.p8.
process.py - Removes empty lines and # comments from text, as well as removing all text between "--db" and "--dbe" comments. Called by shrinko8 when run via pack.bat
pack.bat - Bat script, runs shrinko-8 to combine and minify beatem, beatem-init, beatem-data, and beatem-levels into beatem-packed.p8.
```
