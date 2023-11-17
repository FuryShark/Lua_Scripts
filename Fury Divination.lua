local API, FuryWebhook, FuryRandoms, FuryGUI, FuryUtils = 
    require("api"), require("Fury.Webhook"), require("Fury.Randoms"), require("Fury.GUI"), require("Fury.Utils")

local gui = FuryGUI.new(API)

gui:startTrackingSkill("DIVINATION")
gui:startTrackingSkill("HUNTER")

-- Constants
local RIFT_TIMEOUT = 30
local ANIM_ID = 21228

local enrichedId = {}
local normalId = {}
local riftIds = {
    normal = 87306,
    cache = 93489
}
local chronicleIds = {
    normal = -1;
    enhanced = 51489
} 

nextChronicleRandom = math.random(10,20)

-- Define the wisp IDs for each type of wisp
local wispIds = {
    {normal = {18150, 18173}, enriched = {-1, -1}},    -- Pale Wisps
    {normal = {18151, 18174}, enriched = {18152, 18175}}, -- Flickering Wisps
    {normal = {18153, 18176}, enriched = {18154, 18177}}, -- Bright Wisps
    {normal = {18155, 18178}, enriched = {18156, 18179}}, -- Glowing Wisps
    {normal = {18157, 18180}, enriched = {18158, 18181}}, -- Sparkling Wisps
    {normal = {18159, 18182}, enriched = {18160, 18183}}, -- Gleaming Wisps
    {normal = {18161, 18184}, enriched = {18162, 18185}}, -- Vibrant Wisps
    {normal = {18163, 18186}, enriched = {18164, 18187}}, -- Lustrous Wisps
    {normal = {18165, 18188}, enriched = {18166, 18189}}, -- Brilliant Wisps
    {normal = {18167, 18190}, enriched = {18168, 18191}}, -- Radiant wisps
    {normal = {18169, 18192}, enriched = {18170, 18193}}, -- Luminous Wisps
    {normal = {18171, 18194}, enriched = {18172, 18195}}, -- Incandescent Wisps
    {normal = {13614, 13616}, enriched = {13615, 13617}}, -- Elder Wisps
}

local memoryIds = {
    29384, -- Pale Memory
    29385, 29396, -- Flickering Memory
    29386, 29397, -- Bright Memory
    29387, 29398, -- Glowing Memory
    29388, 29399, -- Sparkling Memory
    29389, 29400, -- Gleaming Memory
    29390, 29401, -- Vibrant Memory
    29391, 29402, -- Lustrous Memory
    29392, 29403, -- Brilliant Memory
    29393, 29404, -- Radiant Memory
    29394, 29405, -- Luminous Memory
    29395, 29406, -- Incandescent Memory
    31326, 31327, -- Elder Memory
}


-- Find wisps near you and set normalIds and enrichedIds
for _, ids in ipairs(wispIds) do
    if FuryUtils.npcExists(ids.normal) then
        normalId = ids.normal
        enrichedId = ids.enriched
        break
    end
end

-- Perform common checks such as random events, XP gain, and idle check
local function performCommonChecks()
    API.DoRandomEvent(18204)
    FuryRandoms:checkForRandomEvents(FuryWebhook)
    gui:updateTrackedSkills()
    FuryUtils:idleCheck()
end

-- Wait until the player is not animating or the enriched wisp spawns
local function waitUntilNotAnimating(lookForEnriched)
    local lastAnimationTime = 0
    local randomTime = math.random(3, 5)
    print("waiting until player not animating or enriched spawns")
    FuryUtils:sleepUntil(
        function()
            local currentTime = os.time()
            if API.ReadPlayerAnim() == ANIM_ID then
                lastAnimationTime = currentTime
                randomTime = math.random(3, 5)
            end
            return os.difftime(currentTime, lastAnimationTime) >= randomTime or (lookForEnriched and FuryUtils.npcExists(enrichedId))
        end,
        120,  -- 120 second timeout
        "animation to finish",
        performCommonChecks
    )
end

local function getRiftId()
    local currentRift = nil
    if FuryUtils.objExists(riftIds.cache) then
        print("Cache")
        currentRift = riftIds.cache
    elseif FuryUtils.objExists(riftIds.normal) then
        print("Rift")
        currentRift = riftIds.normal
    end
    return currentRift
end

-- Convert memories at the rift
local function convertMemories()
    print("Converting memories...")
    local currentRift = getRiftId()
    if API.DoAction_Object1(0xc8, API.OFF_ACT_GeneralObject_route0, { currentRift }, 50) then
        FuryUtils:sleepUntil(
            function() return API.InvItemFound2(memoryIds) == false end,
            RIFT_TIMEOUT,
            "deposit into rift",
            performCommonChecks
        )
        API.RandomSleep2(1000, 500, 1500)
    end
end

-- Harvest a wisp
local function harvest(id)
    print("Harvesting wisps with IDs:", table.concat(id, ", "))
    if API.DoAction_NPC(0xc8, API.OFF_ACT_InteractNPC_route,  id , 50) then
        API.RandomSleep2(2000, 1000, 3000)
        waitUntilNotAnimating(id ~= enrichedId)
    end
end

if normalId == -1 then
    print("No wisps found. Stopping script")
    API.Write_LoopyLoop(false)
end

while API.Read_LoopyLoop() do
    if API.InvFull_() then
        convertMemories()
    elseif API.InvStackSize(chronicleIds.enhanced) >= 10 then
        if API.DoAction_Object1(0x29, 160, { getRiftId() }, 50) then
            FuryUtils:sleepUntil(function() return API.InvStackSize(chronicleIds.enhanced) < 10 end, 10, "empower rift")
        end
    elseif FuryUtils.npcExists(enrichedId) then
        harvest(enrichedId)
    elseif FuryUtils.npcExists(normalId) then
        harvest(normalId)
    end
    API.RandomSleep2(300, 300, 300)
end
