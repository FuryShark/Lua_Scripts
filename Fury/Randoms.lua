local API = require("api")

local FuryRandoms = {}
FuryRandoms.__index = FuryRandoms

function FuryRandoms.new()
    local self = setmetatable({}, FuryRandoms)
    self.lastMessage = nil

    -- You can edit this to add new items to check for. For example:
	-- self.rareItems = {"signet ring", "Orange halloween mask", "cosmetic ability scroll"}
    self.rareItems = {"signet ring"}
	

    return self
end

function FuryRandoms:checkForRandomEvents(webhookInstance)
    if not webhookInstance or type(webhookInstance.send) ~= "function" then
        print("Invalid webhook instance")
        return
    end

    API.DoRandomEvents()
    local chats = API.ChatGetMessages()
    if not chats or #chats < 2 then
        print("No chat messages available")
        return
    end

    local randomCheck = chats[2].text
    if self.lastMessage ~= randomCheck then
        self.lastMessage = randomCheck
        for _, item in ipairs(self.rareItems) do
            if string.find(randomCheck, item) then
                print("RARE ITEM FOUND")
                local splitPosition = randomCheck:find("you : ")
                if splitPosition then
                    local restOfString = randomCheck:sub(splitPosition + #"you : ")
                    print("LOOT " .. restOfString)
                    webhookInstance:send(restOfString)
                    print(restOfString)
                end
                break  -- Exit the loop once a rare item is found
            end
        end
    end
end

local instance = FuryRandoms.new()
return instance
