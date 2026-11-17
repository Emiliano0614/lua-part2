/* host.c - a tiny game engine written in C that EMBEDS Lua.
 *
 * C owns the engine: enemy HP, the turn loop, a random-number source.
 * Lua owns the rules: which enemies appear and how much damage a hit does.
 * The rules live in a .lua file that is read at run time, so changing the
 * game does NOT require recompiling this program.
 *
 * Build:  cc -o host host.c $(pkg-config --cflags --libs lua)
 * Run:    ./host rules.lua        (or ./host rules_hard.lua)
 */
#include <stdio.h>
#include <stdint.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* ---- functions the C host hands to Lua ---------------------------------- */

static uint32_t seed = 42;   /* fixed seed: identical output on every run */

/* host_random(n) -> integer in 1..n */
static int host_random(lua_State *L) {
    lua_Integer n = luaL_checkinteger(L, 1);
    seed = seed * 1103515245u + 12345u;
    lua_pushinteger(L, (lua_Integer)((seed >> 16) % (uint32_t)n) + 1);
    return 1;
}

/* host_log(text) -> prints a line tagged as coming from a Lua rule */
static int host_log(lua_State *L) {
    printf("    [rules.lua says] %s\n", luaL_checkstring(L, 1));
    return 0;
}

/* ---- the engine --------------------------------------------------------- */

int main(int argc, char **argv) {
    const char *rules = (argc > 1) ? argv[1] : "rules.lua";

    lua_State *L = luaL_newstate();      /* create the embedded Lua engine */
    luaL_openlibs(L);
    lua_register(L, "host_random", host_random);   /* expose C to Lua */
    lua_register(L, "host_log", host_log);

    if (luaL_dofile(L, rules) != LUA_OK) {         /* load the rules */
        fprintf(stderr, "could not load %s: %s\n", rules, lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }
    printf("C host loaded rules from %s\n", rules);

    int total_turns = 0;
    for (int wave = 1; ; wave++) {
        /* ask Lua: what appears in this wave?  -> name, hp (or nil = no more) */
        lua_getglobal(L, "spawn");
        lua_pushinteger(L, wave);
        if (lua_pcall(L, 1, 2, 0) != LUA_OK) {
            fprintf(stderr, "spawn() failed: %s\n", lua_tostring(L, -1));
            break;
        }
        if (lua_isnil(L, -2)) {                    /* Lua says: game over */
            lua_pop(L, 2);
            break;
        }
        char name[64];
        snprintf(name, sizeof name, "%s", lua_tostring(L, -2));
        int hp = (int)lua_tointeger(L, -1);        /* HP lives in C from here */
        lua_pop(L, 2);

        printf("\nWave %d: %s (HP %d)\n", wave, name, hp);

        while (hp > 0) {
            /* ask Lua: how much damage does a base-15 hit do to this enemy? */
            lua_getglobal(L, "hit");
            lua_pushstring(L, name);
            lua_pushinteger(L, hp);
            lua_pushinteger(L, 15);
            if (lua_pcall(L, 3, 1, 0) != LUA_OK) {
                fprintf(stderr, "hit() failed: %s\n", lua_tostring(L, -1));
                lua_close(L);
                return 1;
            }
            int dmg = (int)lua_tointeger(L, -1);
            lua_pop(L, 1);

            hp -= dmg;
            if (hp < 0) hp = 0;
            total_turns++;
            printf("  turn %2d: hit for %2d -> %s HP %d\n", total_turns, dmg, name, hp);
        }
        printf("  %s defeated\n", name);
    }

    printf("\nGame over after %d turns.\n", total_turns);
    lua_close(L);
    return 0;
}
