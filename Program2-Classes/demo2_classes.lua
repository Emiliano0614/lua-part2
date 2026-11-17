-- Demo 2: Building a class system from scratch with metatables
-- Run:  lua demo2_classes.lua
--
-- Lua has no `class` keyword. We write class() ourselves (about 20 lines),
-- then use it for:  Entity -> Hero
--                   Entity -> Enemy -> Boss
-- The same attack hits every character, and each reacts differently
-- (polymorphism) because each class overrides mitigate().

------------------------------------------------------------------
-- 1. The class() helper
------------------------------------------------------------------
-- Metamethods are looked up with a RAW access on the metatable, so __index
-- inheritance does NOT cover them. We copy them down to each subclass.
local INHERITED_METAMETHODS = { "__tostring", "__eq", "__lt" }

local function class(name, parent)
    local c = {}
    c.__index   = c          -- instances look up methods in the class
    c.className = name
    c.super     = parent
    for _, mm in ipairs(INHERITED_METAMETHODS) do
        if parent then c[mm] = parent[mm] end
    end
    setmetatable(c, {
        __index = parent,    -- class looks up missing methods in its parent
        __call  = function(cls, ...)       -- lets us write Enemy("Goblin", ...)
            local obj = setmetatable({}, cls)
            if cls.init then cls.init(obj, ...) end
            return obj
        end,
    })
    return c
end

------------------------------------------------------------------
-- 2. Base class: Entity
------------------------------------------------------------------
local Entity = class("Entity")

function Entity:init(name, hp)
    self.name, self.hp, self.maxHp = name, hp, hp
end

function Entity:mitigate(amount, kind)     -- polymorphic hook: subclasses override
    return amount
end

function Entity:takeDamage(amount, kind)
    local dealt = self:mitigate(amount, kind)          -- dynamic dispatch
    self.hp = math.max(0, self.hp - dealt)
    return dealt
end

function Entity:isAlive() return self.hp > 0 end

-- Operator overloading (define BEFORE creating subclasses so they get copies)
function Entity:__tostring()
    return string.format("%s the %s (HP %d/%d)", self.name, self.className, self.hp, self.maxHp)
end
function Entity.__eq(a, b) return a.name == b.name and a.className == b.className end
function Entity.__lt(a, b) return a.hp < b.hp end   -- used by table.sort

------------------------------------------------------------------
-- 3. Subclasses
------------------------------------------------------------------
local Hero = class("Hero", Entity)
function Hero:mitigate(amount, kind)        -- armor: -5 damage from everything
    return math.max(1, amount - 5)
end

local Enemy = class("Enemy", Entity)
function Enemy:init(name, hp, weakness)
    Entity.init(self, name, hp)             -- explicit "super" call
    self.weakness = weakness
end
function Enemy:mitigate(amount, kind)       -- double damage from its weakness
    if kind == self.weakness then return amount * 2 end
    return amount
end

local Boss = class("Boss", Enemy)
function Boss:mitigate(amount, kind)
    if kind == "fire" then return 0 end                -- immune to fire
    return Enemy.mitigate(self, amount, kind) // 2     -- armored: half damage
end
function Boss:takeDamage(amount, kind)     -- extend inherited behavior
    local dealt = Enemy.takeDamage(self, amount, kind)
    if not self.enraged and self.hp <= self.maxHp // 2 then
        self.enraged = true
        print("   !! " .. self.name .. " ENRAGES!")
    end
    return dealt
end
function Boss:__tostring()
    return "*** " .. Enemy.__tostring(self) .. " ***"
end

------------------------------------------------------------------
-- 4. Demonstration
------------------------------------------------------------------
local function lineage(cls)
    local names = {}
    while cls do names[#names + 1] = cls.className; cls = cls.super end
    return table.concat(names, " -> ")
end

print("Inheritance chain: " .. lineage(Boss))
print()

local hero   = Hero("Aria", 100)
local goblin = Enemy("Goblin", 60, "fire")
local drake  = Boss("Ember Drake", 100, "lightning")
local roster = { hero, goblin, drake }

for _, e in ipairs(roster) do print(e) end      -- __tostring
print()

local attacks = {
    { "Sword",     20, "physical"  },
    { "Fireball",  30, "fire"      },
    { "Lightning", 40, "lightning" },
}

for _, atk in ipairs(attacks) do
    print(string.format("--- %s (%d %s) hits everyone ---", atk[1], atk[2], atk[3]))
    for _, target in ipairs(roster) do
        if target:isAlive() then
            local dealt = target:takeDamage(atk[2], atk[3])
            print(string.format("  %-12s takes %3d -> HP %3d", target.name, dealt, target.hp))
            if not target:isAlive() then print("   (" .. target.name .. " is defeated)") end
        end
    end
end

print()
table.sort(roster)                              -- uses __lt
print("Sorted by HP (low to high):")
for _, e in ipairs(roster) do print("  " .. tostring(e)) end

print()
-- __eq: two DIFFERENT tables compare equal because we defined it that way
print("Same name & class == ?", Enemy("Goblin", 60, "fire") == Enemy("Goblin", 10, "ice"))
print("goblin == hero      ?", goblin == hero)

-- Expected damage table (HP after each hit in the middle column):
--   Sword 20:      Aria 15 (85) | Goblin 20 (40) | Drake 10 (90)
--   Fireball 30:   Aria 25 (60) | Goblin 60 (0, defeated) | Drake 0 (90)
--   Lightning 40:  Aria 35 (25) | (Goblin skipped)        | Drake 40 (50) -> ENRAGES
