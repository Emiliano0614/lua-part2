-- rules_hard.lua : same C host, different rules. No recompiling.

local enemies = {
    { name = "Goblin",   hp = 30  },
    { name = "Orc",      hp = 60  },
    { name = "Dragon",   hp = 80  },
    { name = "Lich",     hp = 60  },   -- a new enemy, added without touching C
}

function spawn(wave)
    local e = enemies[wave]
    if not e then return nil end
    host_log("wave " .. wave .. ": " .. e.name .. " appears")
    return e.name, e.hp
end

function hit(name, hp, base)
    local dmg = base + host_random(10)
    if name == "Dragon" then dmg = dmg // 2 end
    if name == "Lich" then
        dmg = dmg // 2                      -- resists most damage
    end
    return dmg
end
