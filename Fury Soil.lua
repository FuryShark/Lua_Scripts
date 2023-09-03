print("Run Lua script Fury Soil.")

local API = require("api")

-- Constants
local BANK_STATE_TIMEOUT = 30
local ANIMATION_TIMEOUT = 20
local INTERFACE_OPEN_TIMEOUT = 5
local WITHDRAWAL_TIMEOUT = 5
local SLEEP_SHORT = {200, 200, 200}

-- bankers at the GE
local bankIds = { 3418, 24855, 2718, 24856 }

local soilBoxId = 49538
local astralsId = 9875

-- Change number to f-key you wish to use
local preset = 2


local preset_to_key = {
    [1] = 0x70,
    [2] = 0x71,
    [3] = 0x72,
    [4] = 0x73,
    [5] = 0x74,
    [6] = 0x75,
    [7] = 0x76,
    [8] = 0x77,
    [9] = 0x78,
}

local soilIds = { 49525, 49517, 49521, 49523, 49519, 50696}

local key = preset_to_key[preset]

function sleepUntil(conditionFunc, timeout, message)
    local startTime = os.time()
    while not conditionFunc() do
        local currentTime = os.time()
        if os.difftime(currentTime, startTime) >= timeout then
            print("Stopped waiting for " .. message .. " after " .. timeout .. " seconds.")
            break
        end
        print("Waiting for " .. message .. "...")
        API.RandomSleep2(table.unpack(SLEEP_SHORT))
    end
end

function waitForBankToBeOpen(open)
    sleepUntil(function() return API.BankOpen2() == open end, BANK_STATE_TIMEOUT, "bank status change")
end

function waitForInterfaceToOpen()
    sleepUntil(function() return API.GetG2874Status() ~= 0 end, INTERFACE_OPEN_TIMEOUT, "interface to open")
end

function isBankOpen()
    return API.VB_FindPSett(2874, 0).state == 24
end

function bankContainsSoil() 
    local soilStacks = API.BankGetItemStack2(soilIds)
    for i, val in ipairs(soilStacks) do
        if val > 0 then
            return true
        end
    end
    return false
end

function withdrawFromBank()
    if (API.DoAction_Interface(0xffffffff,API.OFF_ACT_GeneralInterface_route2,8,517,15,0,6032)) then
        API.RandomSleep2(300,300,300)
        API.KeyboardPress2(key, 60, 100)
        waitForBankToBeOpen(false)
    end
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
::start_of_loop::
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    API.RandomEvents()

    if (API.InvStackSize(astralsId) < 2) then
        print("Out of astral runes")
        API.Write_LoopyLoop(false)
        goto start_of_loop
    end

    if (API.isProcessing()) then
        print("Processing")
        API.RandomSleep2(500, 100, 300)
        goto start_of_loop
    end

    -- if item production is open
    if (API.VB_FindPSett(2874, 0).state == 1310738) then
        API.KeyboardPress2(0x20, 60, 100)
        API.RandomSleep2(1000,500,500)
        goto start_of_loop
    end

    if (isBankOpen()) then
        if (bankContainsSoil()) then
            withdrawFromBank()
            API.RandomSleep2(300,300,300)
            goto start_of_loop
        else
            print("OUT OF SOIL")
            API.Write_LoopyLoop(false) 
        end
    end

    if (API.InvFull_()) then
        if (API.DoAction_NPC(0x5,API.OFF_ACT_InteractNPC_route,bankIds,50)) then
            waitForBankToBeOpen(true)
            API.RandomSleep2(300,300,300)
            goto start_of_loop
        end
    else 
        if (API.DoAction_Interface(0x2e,API.OFF_ACT_GeneralInterface_route,1,1430,64,-1,5392)) then
            waitForInterfaceToOpen()
            API.RandomSleep2(300,300,300)
            goto start_of_loop
        end
    end

API.RandomSleep2(300, 300, 300)
end----------------------------------------------------------------------------------
