-- SLIDE 8: BUILDING CLASSES WITH METATABLES
-- Lua has no built-in 'class' keyword. Here we create class-like behavior
-- using tables (to hold data/methods) and metatables (to control lookups).
-- KASEY: Start your walkthrough here; this is the class() helper.
local function class(parent)
    local c = {}  -- A class is simply a Lua table.
    -- An instance's metatable will be c. If a method is missing on the
    -- instance, __index tells Lua to look for it on its class table.
    c.__index = c
    c.parent = parent  -- Keep the parent reference for our hierarchy demo.
    if parent then
        -- Special methods (metamethods) are looked up on the object's
        -- immediate metatable; they do not automatically follow __index.
        -- Copy inherited metamethods so each subclass can use them.
        for _, name in ipairs({"__tostring", "__eq", "__lt"}) do
            c[name] = parent[name]
        end
    end
    -- Give the CLASS a metatable too: a missing class method can be
    -- found on its parent (Boss -> Enemy -> Entity).
    setmetatable(c, {__index = parent})
    -- Colon syntax passes the table as the first argument ('self').
    -- ... forwards any number of constructor arguments to init().
    function c:new(...)
        local object = setmetatable({}, c)  -- Make an instance of this class.
        object:init(...)
        return object
    end
    return c
end

-- ENTITY: common fields and behavior shared by all combatants.
local Entity = class()
Entity.className = "Entity"
function Entity:init(name, hp)
    self.name = name
    self.hp = hp
    self.maxHP = hp
end
-- Base damage logic; subclasses can override this same method.
function Entity:damage(amount, kind)
    self.hp = math.max(0, self.hp - amount)
    return amount
end
-- Operator-like behavior through metamethods:
-- __tostring controls tostring(character) and print(character).
function Entity:__tostring()
    return self.name .. " (HP: " .. self.hp .. ")"
end
-- __eq customizes ==: compare character VALUES, not table identities.
function Entity:__eq(other)
    return self.name == other.name and self.hp == other.hp
end
-- __lt customizes <: table.sort uses it to order characters by HP.
function Entity:__lt(other)
    return self.hp < other.hp
end

-- HERO inherits Entity fields but overrides damage to reduce hits by 5.
local Hero = class(Entity)
Hero.className = "Hero"
function Hero:damage(amount, kind)
    return Entity.damage(self, math.max(0, amount - 5), kind)
end

-- ENEMY also inherits Entity, but Fireballs are twice as effective.
local Enemy = class(Entity)
Enemy.className = "Enemy"
function Enemy:damage(amount, kind)
    if kind == "Fireball" then amount = amount * 2 end
    return Entity.damage(self, amount, kind)
end

-- BOSS inherits Enemy -> Entity but replaces damage rules again.
-- This is POLYMORPHISM: calling target:damage(...) works on all three
-- character types, yet each type responds differently.
local Boss = class(Enemy)
Boss.className = "Boss"
function Boss:damage(amount, kind)
    -- Branching gives the boss resistance to swords and immunity to fire.
    if kind == "Sword" then
        amount = amount / 2
    elseif kind == "Fireball" then
        amount = 0
    end
    local damage = Entity.damage(self, amount, kind)
    -- A conditional changes the boss's state once its HP is low enough.
    if self.hp > 0 and self.hp <= self.maxHP / 2 then
        self.enraged = true
    end
    return damage
end

-- Return a module table so other scripts can use require("classes").
return {class = class, Entity = Entity, Hero = Hero, Enemy = Enemy, Boss = Boss}
