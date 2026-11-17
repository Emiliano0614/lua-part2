-- Demo 1: A cooperative task scheduler built from coroutines
-- Run:  lua demo1_scheduler.lua
--
-- Idea: the SAME five jobs run two ways.
--   (a) sequentially: each job waits, then the next job starts
--   (b) under our own scheduler: jobs yield while "waiting", so waits overlap
-- Time is a VIRTUAL clock, so output is instant and identical every run.

------------------------------------------------------------------
-- 1. The scheduler (this is the part we wrote ourselves)
------------------------------------------------------------------
local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
    return setmetatable({ clock = 0, tasks = {} }, Scheduler)
end

function Scheduler:spawn(name, body)
    table.insert(self.tasks, {
        name   = name,
        co     = coroutine.create(body),
        wakeAt = 0,
        done   = false,
    })
end

function Scheduler:run()
    while true do
        -- pick the unfinished task that wakes up soonest (ties: spawn order)
        local nextTask
        for _, t in ipairs(self.tasks) do
            if not t.done and (nextTask == nil or t.wakeAt < nextTask.wakeAt) then
                nextTask = t
            end
        end
        if nextTask == nil then break end          -- nothing left to run

        -- jump the virtual clock forward to that task's wake-up time
        self.clock = math.max(self.clock, nextTask.wakeAt)

        local ok, delay = coroutine.resume(nextTask.co)
        if not ok then
            error(nextTask.name .. " crashed: " .. tostring(delay))
        end

        if coroutine.status(nextTask.co) == "dead" then
            nextTask.done = true
            print(string.format("[t=%4.1fs] %-9s FINISHED", self.clock, nextTask.name))
        else
            nextTask.wakeAt = self.clock + delay   -- 'delay' came from coroutine.yield
        end
    end
    return self.clock
end

------------------------------------------------------------------
-- 2. The jobs: each is a list of steps, each step has a duration
------------------------------------------------------------------
local jobs = {
    { name = "Download", steps = { {"connect", 0.5}, {"fetch", 2.0},  {"verify", 0.5} } },
    { name = "Parse",    steps = { {"open",    0.5}, {"read",  1.5},  {"index",  0.5} } },
    { name = "Resize",   steps = { {"load",    1.0}, {"scale", 2.0},  {"encode", 1.0} } },
    { name = "Upload",   steps = { {"connect", 0.5}, {"send",  1.0} } },
    { name = "Email",    steps = { {"compose", 0.5}, {"send",  0.5} } },
}

-- One job body, written once. HOW it waits is injected:
--   wait(seconds) -> either "advance the clock" or "yield to the scheduler"
local function makeJob(job, wait, now, log)
    return function()
        for _, step in ipairs(job.steps) do
            log(string.format("[t=%4.1fs] %-9s %s", now(), job.name, step[1]))
            wait(step[2])
        end
    end
end

------------------------------------------------------------------
-- 3. Two runtimes for the same jobs
------------------------------------------------------------------
local function runSequential()
    local clock = 0
    local function wait(d) clock = clock + d end
    local function now() return clock end
    local function quiet() end                     -- don't print every step

    for _, job in ipairs(jobs) do
        makeJob(job, wait, now, quiet)()           -- run the whole job, blocking
        print(string.format("[t=%4.1fs] %-9s FINISHED", clock, job.name))
    end
    return clock
end

local function runScheduled()
    local sched = Scheduler.new()
    local function now() return sched.clock end

    for _, job in ipairs(jobs) do
        -- coroutine.yield IS the wait function: it hands control back to the scheduler
        sched:spawn(job.name, makeJob(job, coroutine.yield, now, print))
    end
    return sched:run()
end

------------------------------------------------------------------
-- 4. Compare
------------------------------------------------------------------
print("=== SEQUENTIAL (one job at a time) ===")
local seq = runSequential()

print()
print("=== SCHEDULED (jobs overlap their waiting) ===")
local con = runScheduled()

print()
print(string.format("Sequential: %.1fs | Scheduled: %.1fs | speedup: %.1fx", seq, con, seq / con))

-- Expected: Sequential 12.0s | Scheduled 4.0s | speedup 3.0x
-- Why 4.0? Everything overlaps, so total time = the longest job (Resize = 4.0s).
-- Honest caveat: this speeds up WAITING (I/O-like). Coroutines run on one
-- thread, so CPU-heavy work would not get faster.
