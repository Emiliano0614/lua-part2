# Lua Part 2 - Team #8

Live demonstrations for our Lua presentation. Each program shows one of Lua's signature features.

| Folder | Program | Feature | Presenters |
|---|---|---|---|
| Program1-Scheduler | Cooperative task scheduler | Coroutines | Chris, Aaron |
| Program2-Classes | Class system (Entity, Hero, Enemy, Boss) | Metatables | Kasey, Alex |
| Program3-Embedded | C game engine with Lua rules | Embedding Lua in a C program | Emiliano |

## Setup
- macOS: `brew install lua`
- Windows: download LuaBinaries and add the folder to PATH
- Linux: `sudo apt install lua5.4`
- Verify: `lua -v`

## Run Programs 1 and 2
    lua Program1-Scheduler/demo1_scheduler.lua
    lua Program2-Classes/demo2_classes.lua

Expected: the scheduler prints Sequential 12.0s vs Scheduled 4.0s.

## Run Program 3 (needs a C compiler)
The C host embeds Lua and loads its game rules from a .lua file at run time.

    cd Program3-Embedded
    cc -o host host.c $(pkg-config --cflags --libs lua)
    ./host rules.lua
    ./host rules_hard.lua

Expected: `rules.lua` ends with "Game over after 19 turns", and `rules_hard.lua` adds a Lich and ends after 21 turns. Both runs use the same compiled program; only the Lua rules change, so no recompiling is needed.
