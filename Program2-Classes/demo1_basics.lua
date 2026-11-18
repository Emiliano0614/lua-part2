-- DEMO 1: FUNDAMENTAL SYNTAX & CONTROL STRUCTURES
-- Covers console I/O, for loops, sentinel-controlled while loops,
-- and if / elseif / else branching in a playable turn-based battle.
local C = require("classes")  -- Reuse the class system instead of duplicating code.
print("=== DUNGEON DUEL ===")
-- CONSOLE I/O: io.write displays a prompt; io.read receives user text.
io.write("Enter your hero's name: ")
local name = io.read()
if not name then return end
-- BRANCHING: use a default name when the player enters nothing.
if name == "" then name = "Aria" end
local hero = C.Hero:new(name, 100)
local enemies = {C.Enemy:new("Goblin", 80), C.Boss:new("Drake", 100)}
-- Lua tables work like flexible arrays: each attack stores a name
-- and a damage number; indices start at 1, not 0.
local attacks = {{"Sword", 20}, {"Fireball", 30}, {"Lightning", 40}}
local choice = ""

-- ITERATIVE FOR LOOP: visit enemies in order using ipairs().
for _, enemy in ipairs(enemies) do
    print("\nA " .. enemy.name .. " appears!")
    -- SENTINEL WHILE LOOP: the player entering "0" stops the game;
    -- the loop also stops when either combatant reaches zero HP.
    while choice ~= "0" and hero.hp > 0 and enemy.hp > 0 do
        print(tostring(hero) .. " vs " .. tostring(enemy))
        -- Another FOR LOOP prints the numbered choices automatically.
        for i, attack in ipairs(attacks) do
            print(i .. ". " .. attack[1] .. " (" .. attack[2] .. ")")
        end
        print("4. Heal (20 HP)\n0. Quit")
        io.write("Choose: ")
        choice = io.read() or "0"
        -- tonumber converts typed text to a number; or 0 handles
        -- invalid text without crashing the lookup.
        local attack = attacks[tonumber(choice) or 0]
        local acted = false
        -- IF / ELSEIF / ELSE-style branching decides which action to run.
        if attack then
            print(enemy.name .. " takes " .. enemy:damage(attack[2], attack[1]) .. " damage!")
            acted = true
        elseif choice == "4" then
            hero.hp = math.min(hero.maxHP, hero.hp + 20)
            print("You healed!")
            acted = true
        elseif choice ~= "0" then
            print("Invalid choice.")
        end
        -- A living enemy counterattacks only after a valid player action.
        if acted and enemy.hp > 0 then
            local damage = enemy.enraged and 25 or 15
            print(hero.name .. " takes " .. hero:damage(damage, "Sword") .. " damage!")
        end
    end
    if choice == "0" or hero.hp == 0 then break end
    print(enemy.name .. " defeated!")
end
-- Final branching selects the ending based on player choice and HP.
if choice == "0" then print("You left the dungeon.")
elseif hero.hp == 0 then print("Game over!")
else print("Victory!") end
