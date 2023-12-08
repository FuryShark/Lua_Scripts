local API, FuryWebhook, FuryRandoms, FuryGUI, FuryUtils = 
    require("api"), require("Fury.Webhook"), require("Fury.Randoms"), require("Fury.GUI"), require("Fury.Utils")

local gui = FuryGUI.new(API)

gui:startTrackingSkill("HERBLORE")

local NPC_IDS = {
    26454, 26453,  26451, 26449, 26452, 26450, 26455
}

local finished = false

local function FindHl(objects, maxdistance, highlight)
    local objObjs = API.GetAllObjArray1(objects, maxdistance, 1)
    local hlObjs = API.GetAllObjArray1(highlight, maxdistance, 4)

    for _, obj in ipairs(objObjs) do
        for _, hl in ipairs(hlObjs) do
            if math.abs(obj.Tile_XYZ.x - hl.Tile_XYZ.x) < 0.1 and math.abs(obj.Tile_XYZ.y - hl.Tile_XYZ.y) < 0.1 then
                return obj
            end
        end
    end

    return nil
end

local function checkForPoints()
    local chats = API.ChatGetMessages()
    if not chats or #chats < 1 then
        print("No chat messages available")
        return
    end

    local messagesToCheck = math.min(10, #chats)

    for i = 1, messagesToCheck do
        local chatMessage = chats[i].text
        if string.find(chatMessage, "100/100 points") then
            print("Message with '100/100 points' found: " .. chatMessage)
            finished = true
        end
    end
end

local function performCommonChecks()
    checkForPoints()
    FuryRandoms:checkForRandomEvents(FuryWebhook)
    gui:updateTrackedSkills()
    FuryUtils:idleCheck()
end

while API.Read_LoopyLoop() do

    performCommonChecks()

    if finished then
        API.DoAction_Object1(0x34, API.OFF_ACT_GeneralObject_route0, {113884}, 50)
        API.Write_LoopyLoop(false)
    end

    local greenNpc = FindHl(NPC_IDS, 50, {7237})
    if greenNpc then
        local xpBefore = API.GetSkillXP("HERBLORE")
        if API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, { greenNpc.Id }, 50) then
            FuryUtils:sleepUntil(function() return API.ReadPlayerMovin2() end, 2, "started walking")
            FuryUtils:sleepUntil(function() return API.GetSkillXP("HERBLORE") > xpBefore or not API.ReadPlayerMovin2() end, 15, "gained XP or stopped walking")
        end
    end
end