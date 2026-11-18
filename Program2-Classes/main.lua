-- GRAPHICAL DEMO: THE SAME LUA RPG RUNNING IN LOVE2D
-- LÖVE calls love.load, love.draw, and input callbacks automatically.
-- Our gameplay still uses Lua tables, loops, branching and the SAME
-- character classes from Slide 8. No separate game engine language.
local C = require("classes")
local hero, enemies, stage, enemy, state, messages
local attacks = {{"Sword", 20}, {"Fireball", 30}, {"Lightning", 40}, {"Heal", 20}}
local buttons = {}
local font, titleFont

-- Reset creates fresh Hero/Enemy/Boss objects and game state.
-- 'local' keeps this helper private to this file (Lua scope).
local function reset()
    hero = C.Hero:new("Aria", 100)
    enemies = {C.Enemy:new("Goblin", 80), C.Boss:new("Drake", 100)}
    stage = 1
    enemy = enemies[stage]
    state = "playing"
    messages = {"A Goblin blocks your path!"}
end

-- Append recent messages to a Lua table; print also logs to console.
local function log(message)
    messages[#messages + 1] = message
    if #messages > 4 then table.remove(messages, 1) end
    print(message)
end

-- All attack buttons/number keys call the same combat function.
-- Notice the same :damage() call works for Goblin and Drake.
local function turn(choice)
    if state ~= "playing" then return end
    local attack = attacks[choice]
    if not attack then return end
    -- BRANCHING: Heal has special behavior; other choices deal damage.
    if choice == 4 then
        hero.hp = math.min(hero.maxHP, hero.hp + 20)
        log("Aria recovers health.")
    else
        local wasEnraged = enemy.enraged
        local damage = enemy:damage(attack[2], attack[1])
        log(attack[1] .. " deals " .. damage .. " damage to " .. enemy.name .. ".")
        if enemy.enraged and not wasEnraged then log("Drake ENRAGES!") end
    end
    -- More branching controls stage progression, victory and defeat.
    if enemy.hp == 0 then
        log(enemy.name .. " defeated!")
        stage = stage + 1
        if stage > #enemies then
            state = "victory"
            log("You escaped the dungeon!")
        else
            enemy = enemies[stage]
            log("Drake approaches. Fire will not hurt him!")
        end
    else
        local damage = hero:damage(enemy.enraged and 25 or 15, "Sword")
        log(enemy.name .. " strikes back for " .. damage .. ".")
        if hero.hp == 0 then state = "defeat" end
    end
end

-- LOVE2D CALLBACK #1: called once at game startup.
function love.load()
    love.window.setMode(900, 620)
    love.window.setTitle("Dungeon Duel - Lua RPG")
    font = love.graphics.newFont(16)
    titleFont = love.graphics.newFont(32)
    love.graphics.setBackgroundColor(0.07, 0.08, 0.13)
    -- ITERATIVE LOOP: create the same button layout for each attack.
    for i, attack in ipairs(attacks) do
        buttons[i] = {x = 26 + (i - 1) * 215, y = 530, w = 203, h = 60, label = attack[1]}
    end
    reset()
end

local function color(r,g,b) love.graphics.setColor(r,g,b) end
local function rect(x,y,w,h,r,g,b)
    color(r,g,b)
    love.graphics.rectangle("fill", x,y,w,h,6,6)
end
-- Draw either character's health bar from shared fields (hp, maxHP).
local function healthBar(character,x,y,r,g,b)
    rect(x,y,250,19,0.19,0.21,0.28)
    rect(x,y,250 * character.hp / character.maxHP,19,r,g,b)
    color(1,1,1)
    love.graphics.print(character.name .. "   " .. character.hp .. "/" .. character.maxHP, x,y-27)
end

-- LOVE2D CALLBACK #2: runs repeatedly to redraw the whole screen.
-- The nested for loops draw dungeon floor tiles; conditionals choose
-- the Goblin or Boss sprite. These are ordinary Lua control structures.
function love.draw()
    local g = love.graphics
    g.setFont(titleFont)
    color(0.98,0.83,0.44)
    g.printf("DUNGEON DUEL",0,18,900,"center")
    g.setFont(font)
    color(0.68,0.72,0.82)
    g.printf("ARCADE RPG  /  BATTLE " .. math.min(stage,2) .. " OF 2",0,61,900,"center")
    rect(26,95,848,300,0.11,0.13,0.20)
    -- NESTED ITERATIVE LOOPS: build rows and columns of dungeon tiles.
    for row=0,5 do
        for col=0,15 do
            color(0.15,0.17,0.24)
            g.rectangle("line",28+col*53,98+row*48,53,48)
        end
    end
    healthBar(hero,65,141,0.25,0.75,0.55)
    healthBar(enemy,585,141,0.90,0.31,0.33)
    -- Simple pixel-style hero and monster, drawn with shapes.
    rect(150,210,70,85,0.22,0.49,0.92)
    rect(163,180,44,42,0.86,0.68,0.47)
    rect(148,176,74,15,0.67,0.74,0.85)
    rect(157,295,22,42,0.32,0.34,0.48)
    rect(192,295,22,42,0.32,0.34,0.48)
    rect(232,215,10,85,0.85,0.87,0.96)
    rect(220,270,35,9,0.95,0.72,0.25)
    -- BRANCHING: choose the boss art instead of the regular enemy art.
    if enemy.className == "Boss" then
        rect(660,215,104,91,0.62,0.15,0.24)
        rect(685,184,78,48,0.82,0.23,0.29)
        color(0.78,0.25,0.32)
        g.polygon("fill",660,240,609,183,635,298)
        g.polygon("fill",760,240,815,183,785,298)
        rect(737,200,12,9,1,0.8,0.2)
    else
        rect(667,232,74,69,0.29,0.62,0.29)
        rect(653,189,102,58,0.52,0.78,0.34)
        rect(670,207,13,9,0.10,0.17,0.10)
        rect(727,207,13,9,0.10,0.17,0.10)
        rect(695,232,20,7,0.15,0.22,0.12)
    end
    color(1,1,1)
    g.printf("VS",390,245,120,"center")
    color(0.74,0.78,0.86)
    g.printf(enemy.enraged and "ENRAGED!" or (stage == 1 and "Weak to fire" or "Fire immune / Sword resistant"),550,355,310,"center")
    rect(26,407,848,110,0.13,0.15,0.22)
    for i, message in ipairs(messages) do
        color(0.85,0.88,0.94)
        g.print(message,42,417+(i-1)*23)
    end
    for i, button in ipairs(buttons) do
        rect(button.x,button.y,button.w,button.h,0.22,0.26,0.37)
        color(1,1,1)
        g.printf(i .. "  " .. button.label,button.x,button.y+8,button.w,"center")
        color(0.72,0.77,0.88)
        g.printf(attacks[i][2] .. (i==4 and " HP" or " damage"),button.x,button.y+32,button.w,"center")
    end
    if state ~= "playing" then
        rect(260,190,380,145,0.07,0.09,0.14)
        g.setFont(titleFont)
        color(1,0.83,0.44)
        g.printf(state == "victory" and "VICTORY!" or "GAME OVER",260,215,380,"center")
        g.setFont(font)
        color(1,1,1)
        g.printf("Press R to play again",260,277,380,"center")
    end
end

-- LOVE2D CALLBACK #3: player keyboard input (1-4, R, Escape).
function love.keypressed(key)
    if key == "escape" then love.event.quit()
    elseif key == "r" then reset()
    elseif tonumber(key) then turn(tonumber(key)) end
end

-- LOVE2D CALLBACK #4: mouse input; a loop finds the clicked button.
function love.mousepressed(x,y,button)
    if button ~= 1 then return end
    for i,b in ipairs(buttons) do
        if x >= b.x and x <= b.x+b.w and y >= b.y and y <= b.y+b.h then
            turn(i)
        end
    end
end
