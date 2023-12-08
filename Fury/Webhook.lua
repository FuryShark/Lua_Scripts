-- FuryWebhook.lua
local API = require("api")
local player = API.GetLocalPlayerName()

local FuryWebhook = {}
FuryWebhook.__index = FuryWebhook

function FuryWebhook.new()
    local self = setmetatable({}, FuryWebhook)
    -- Optional: set url for a default webhook
    self.url = "https://discord.com/api/webhooks/1137729932173267004/6EI5iSO_O4FcbOVXHZrJa7Fv3_ydWTaTQbi4-TRuTkoiRX_T8GkaBncVepzdhDELFn4Y"
    return self
end

function FuryWebhook:setUrl(newUrl)
    self.url = newUrl
end

function FuryWebhook:send(content)
    if self.url == "" then
        error("Webhook URL not set.")
    end

    content = "[" .. player .. "] " .. content
    local cmd = string.format('curl -X POST -H "Content-Type: application/json" -d "{\\"content\\": \\"%s\\"}" %s', content, self.url)
    os.execute(cmd)
end

return FuryWebhook.new()
