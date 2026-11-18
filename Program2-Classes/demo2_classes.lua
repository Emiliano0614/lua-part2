-- SLIDE 8 LIVE DEMO (ALEX): Run with: lua demo2_classes.lua
-- This file USES the class system defined in classes.lua.
-- It demonstrates inheritance, polymorphism, and operator overloading.
local C = require("classes")  -- require loads our reusable Lua module.
-- Create three different class instances with the same :new() pattern.
local aria = C.Hero:new("Aria", 100)
local goblin = C.Enemy:new("Goblin", 80)
local drake = C.Boss:new("Drake", 100)
local roster = {aria, goblin, drake}

-- Walk up the parent links to SHOW the inheritance hierarchy.
-- The while loop ends when the parent becomes nil (a sentinel).
local chain = {}
local current = C.Boss
while current do
    chain[#chain + 1] = current.className
    current = current.parent
end
print("Inheritance: " .. table.concat(chain, " -> "))

-- Iterative loops: try each attack against every living character.
-- One method call (target:damage) gives different outcomes by class.
local attacks = {{"Sword", 20}, {"Fireball", 30}, {"Lightning", 40}}
for _, attack in ipairs(attacks) do
    print("\n" .. attack[1] .. " (" .. attack[2] .. ")")
    for _, target in ipairs(roster) do
        if target.hp > 0 then
            local wasEnraged = target.enraged
            -- POLYMORPHISM: Lua resolves this method at runtime.
            local damage = target:damage(attack[2], attack[1])
            local message = target.name .. " takes " .. damage .. " damage."
            -- BRANCHING: report death or an enrage event only if triggered.
            if target.hp == 0 then message = message .. " DEFEATED!" end
            if target.enraged and not wasEnraged then message = message .. " ENRAGES!" end
            print(message)
        end
    end
end

print("\nRoster sorted by HP:")
-- OPERATOR OVERLOADING: table.sort uses our __lt method (HP).
table.sort(roster)
for _, target in ipairs(roster) do print(target) end

-- Two distinct tables can compare equal via __eq (same name and HP).
-- rawequal ignores metamethods; == uses our custom __eq method.
local copy = C.Hero:new(aria.name, aria.hp)
print("\nDifferent tables: " .. tostring(not rawequal(aria, copy)))
print("Equal using __eq: " .. tostring(aria == copy))
