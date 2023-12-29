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
        return true
    end
    return false
end

--- Checks if an NPC with the given ID exists within a specified distance.
-- @param npcId The ID of the NPC to check for.
-- @param distance (optional) The distance within which to check for the NPC.
-- @return true if the NPC exists within the specified distance, false otherwise.
function FuryUtils:npcExists(npcId, distance)
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
function FuryUtils:objExists(objId, distance)
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

function FuryUtils:randomSleep(minMilliseconds, maxMilliseconds)
    local randomDelay = math.random(minMilliseconds, maxMilliseconds)
    local start = os.clock()
    local target = start + (randomDelay / 1000)
    while os.clock() < target and API.Read_LoopyLoop() do
        API.RandomSleep2(100, 0, 0)
    end
end


--- Banks all items in the inventory except for those specified in the provided table.
-- This function iterates through the player's inventory and banks each unique item
-- unless its ID matches one of the IDs listed in the exclusion table.
-- Requires Bank Transfer button to be set to "All"
-- @param itemIds table Either an array or a key-value table of item IDs to exclude from banking.
--                  If it's an array, use the item IDs directly.
--                  If it's a key-value table, the values should be the item IDs.
-- @usage
--      local ITEM_IDS = {
--          rottenEgg = 53100,
--          goodEgg = 53099,
--          sharpShellShard = 53093
--      }
--      FuryUtils:BankAllExcept(ITEM_IDS) -- Will bank all items except for rottenEgg, goodEgg, and sharpShellShard.
function FuryUtils:BankAllExcept(itemIds)
    local invArray = API.FetchBankInvArray()
    
    if not invArray or #invArray == 0 then
        print("Inventory is empty or nil.")
        return
    end

    local excludeMap = {}
    for _, itemId in pairs(itemIds) do
        excludeMap[itemId] = true
    end

    local uniqueItemIDs = {}

    for _, item in ipairs(invArray) do
        if item.itemid1 and not uniqueItemIDs[item.itemid1] and not excludeMap[item.itemid1] then
            uniqueItemIDs[item.itemid1] = true
            print("Banking item with ID: " .. tostring(item.itemid1))
            if API.DoAction_Interface(0xffffffff, item.itemid1, 1, 517, 15, item.id3, 5376) then
                FuryUtils:randomSleep(100,200)
            end
        end
    end
end

--- Generates a random point within a specified rectangular area.
-- @param x1 number The x-coordinate of the first corner of the rectangle.
-- @param y1 number The y-coordinate of the first corner of the rectangle.
-- @param x2 number The x-coordinate of the opposite corner of the rectangle.
-- @param y2 number The y-coordinate of the opposite corner of the rectangle.
-- @return WPOINT A random point within the specified rectangular area.
function FuryUtils:getRandomPointInArea(x1, y1, x2, y2)
    local minX = math.min(x1, x2)
    local maxX = math.max(x1, x2)
    local minY = math.min(y1, y2)
    local maxY = math.max(y1, y2)
    
    local z = API.PlayerCoord().z

    local randomX = math.random(minX, maxX)
    local randomY = math.random(minY, maxY)
    return WPOINT.new(randomX, randomY, z)
end


--- Checks if the player is within a specified area.
-- This function can handle both rectangular and polygonal areas.
-- For a rectangle, the area is defined by two opposite corners as four numbers {x1, y1, x2, y2}.
-- For a polygon, the area is defined as a table of points, each point being a table with 'x' and 'y' keys.
-- @param area table The area definition. Can be either {x1, y1, x2, y2} for a rectangle,
--                    or an array of points for a polygon.
-- @return boolean True if the player is within the specified area, False otherwise.
-- @usage 
--      -- Example for a rectangle
--      local rectangleArea = {3020, 3234, 3022, 3239}
--      local inRectangle = FuryUtils:playerInArea(rectangleArea)
--      print("Player is in rectangle area: ", inRectangle)
--
--      -- Example for a polygon:
--      local polygonArea = {
--          {x = 3020, y = 3234},
--          {x = 3022, y = 3234},
--          {x = 3022, y = 3239},
--          {x = 3020, y = 3239}
--      }
--      local inPolygon = FuryUtils:playerInArea(polygonArea)
--      print("Player is in polygon area: ", inPolygon)
function FuryUtils:playerInArea(area, floor)
    floor = floor or 0
    local point = API.PlayerCoord()
    if point.z ~= floor then
        return false
    end

    -- Normalize area format
    if #area == 4 and type(area[1]) == "number" then
        -- Rectangle format: {x1, y1, x2, y2}
        local x1, y1, x2, y2 = area[1], area[2], area[3], area[4]
        area = {
            {x = x1, y = y1},
            {x = x2, y = y1},
            {x = x2, y = y2},
            {x = x1, y = y2}
        }
    elseif type(area[1]) == "table" and #area[1] == 2 then
        -- Array of arrays format: {{x1, y1}, {x2, y2}, ...}
        for i, point in ipairs(area) do
            area[i] = {x = point[1], y = point[2]}
        end
    end

    local count = 0
    local n = #area
    for i = 1, n do
        local j = (i % n) + 1
        local vertex1 = area[i]
        local vertex2 = area[j]
        if ((vertex1.y > point.y) ~= (vertex2.y > point.y)) and
            (point.x < (vertex2.x - vertex1.x) * (point.y - vertex1.y) / (vertex2.y - vertex1.y) + vertex1.x) then
            count = count + 1
        end
    end

    -- Point is inside the polygon if count is odd
    return (count % 2) == 1
end



local instance = FuryUtils.new()
return instance
