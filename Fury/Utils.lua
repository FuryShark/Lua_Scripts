local API = require("api")

local FuryUtils = {}
FuryUtils.__index = FuryUtils

--- Constructor for FuryUtils.
function FuryUtils.new()
    local self = setmetatable({}, FuryUtils)
    self.afk = os.time()
    self.randomTime = math.random(180, 280)
    return self
end

--- Checks if the player has been idle for a random amount of time and performs an idle action if true.
function FuryUtils:idleCheck()
    local timeDiff = os.difftime(os.time(), self.afk)
    if timeDiff > self.randomTime then
        API.PIdle2()
        self.afk = os.time()
        self.randomTime = math.random(180, 280)
    end
end

--- Sleeps until a given condition is true or a timeout is reached.
-- @param conditionFunc The function that returns true when the condition is met.
-- @param timeout The maximum time to wait for the condition to be true.
-- @param message The message to display if the timeout is reached.
-- @param callback The function to call while waiting for the condition to be true.
function FuryUtils:sleepUntil(conditionFunc, timeout, message, callback)
    timeout = timeout or 10  -- default timeout value
    message = message or "condition"  -- default message value
    local startTime = os.time()
    while not conditionFunc() do
        if os.difftime(os.time(), startTime) >= timeout then
            print("Stopped waiting for " .. message .. " after " .. timeout .. " seconds.")
            break
        end
        if not API.Read_LoopyLoop() then
            print("Script exited - breaking sleep.")
            break
        end
        if callback then
            callback()
        end
        API.RandomSleep2(100, 100, 100)
    end
    if conditionFunc() then
        print("Sleep condition met for " .. message)
    end
end

--- Checks if an NPC with the given ID exists within a specified distance.
-- @param npcId The ID of the NPC to check for.
-- @param distance (optional) The distance within which to check for the NPC.
-- @return true if the NPC exists within the specified distance, false otherwise.
function FuryUtils.npcExists(npcId, distance)
    distance = distance or 20  -- Default distance is 20 if not specified
    if type(npcId) == "table" then
        for _, id in ipairs(npcId) do
            if type(id) == "number" and id ~= -1 then
                local result = API.GetAllObjArrayInteract({id}, distance, 1)
                if #result > 0 then
                    return true
                end
            end
        end
        return false
    elseif type(npcId) == "number" and npcId ~= -1 then
        local result = API.GetAllObjArrayInteract({npcId}, distance, 1)
        return #result > 0
    else
        return false
    end
end

--- Checks if an object with the given ID exists within a specified distance.
-- @param objId The ID of the object to check for.
-- @param distance (optional) The distance within which to check for the object.
-- @return true if the object exists within the specified distance, false otherwise.
function FuryUtils.objExists(objId, distance)
    distance = distance or 20  -- Default distance is 20 if not specified
    if type(objId) == "table" then
        for _, id in ipairs(objId) do
            if type(id) == "number" and id ~= -1 then
                local result = API.GetAllObjArrayInteract({id}, distance, 0)
                if #result > 0 then
                    return true
                end
            end
        end
        return false
    elseif type(objId) == "number" and objId ~= -1 then
        local result = API.GetAllObjArrayInteract({objId}, distance, 0)
        return #result > 0
    else
        return false
    end
end

local instance = FuryUtils.new()
return instance
