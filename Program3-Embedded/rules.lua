-- rules.lua : the game design. The C host never changes; this file does.

local enemies = {
    { name = "Goblin",   hp = 30  },
    { name = "Skeleton", hp = 45  },
    { name = "Orc",      hp = 60  },
    { name = "Dragon",   hp = 100 },
}

-- Called by the host at the start of each wave.
-- Return name, hp  -- or nothing at all to end the game.
function spawn(wave)
    local e = enemies[wave]
    if not e then return nil end
    host_log("wave " .. wave .. ": " .. e.name .. " appears")
    return e.name, e.hp
end

-- Called by the host on every attack. Return the damage dealt.
function hit(name, hp, base)
    local dmg = base + host_random(10)      -- host_random is a C function
    if name == "Dragon" then
        dmg = dmg // 2                      -- armored: half damage
    end
    return dmg
end
