local API = require("api")
local FuryGUI = {}
FuryGUI.__index = FuryGUI

local ALL_SKILLS = {
    "ATTACK",
    "STRENGTH",
    "RANGED",
    "MAGIC",
    "DEFENCE",
    "CONSTITUTION",
    "PRAYER",
    "SUMMONING",
    "DUNGEONEERING",
    "AGILITY",
    "THIEVING",
    "SLAYER",
    "HUNTER",
    "SMITHING",
    "CRAFTING",
    "FLETCHING",
    "HERBLORE",
    "RUNECRAFTING",
    "COOKING",
    "CONSTRUCTION",
    "FIREMAKING",
    "WOODCUTTING",
    "FARMING",
    "FISHING",
    "MINING",
    "DIVINATION",
    "INVENTION",
    "ARCHAEOLOGY",
    "NECROMANCY"
}

local SKILL_COLORS = {
    ATTACK = ImColor.new(135, 62, 60),           -- Red
    STRENGTH = ImColor.new(9, 87, 22),          -- Green
    RANGED = ImColor.new(13, 84, 21),         -- Sea green
    MAGIC = ImColor.new(58, 95, 207),            -- Blue
    DEFENCE = ImColor.new(61, 112, 159),         -- light blue
    CONSTITUTION = ImColor.new(189, 0, 0),       -- Crimson
    PRAYER = ImColor.new(52, 101, 138),          -- pale blue
    SUMMONING = ImColor.new(156, 183, 210),       -- Light blue
    DUNGEONEERING = ImColor.new(215, 117, 57),    -- Burnt orange
    AGILITY = ImColor.new(41, 59, 136),           -- Dark blue
    THIEVING = ImColor.new(156, 76, 142),       -- Mauve
    SLAYER = ImColor.new(135, 0, 7),             -- Dark red
    HUNTER = ImColor.new(171, 190, 131),           -- Light olive 
    SMITHING = ImColor.new(130, 154, 103),         -- olive green
    CRAFTING = ImColor.new(237, 232, 165),          -- Light beige
    FLETCHING = ImColor.new(0, 126, 151),         -- Deep teal
    HERBLORE = ImColor.new(51, 206, 70),           -- bright green
    RUNECRAFTING = ImColor.new(255, 158, 40),     -- orangey
    COOKING = ImColor.new(110, 49, 144),          -- deep purple
    CONSTRUCTION = ImColor.new(141, 121, 90),     -- muted brown
    FIREMAKING = ImColor.new(232, 107, 5),       -- Fiery orange
    WOODCUTTING = ImColor.new(154, 205, 50),       -- Forest green
    FARMING = ImColor.new(49,147,62),          -- Vibrant green
    FISHING = ImColor.new(115,177,230),          -- Dark blue
    MINING = ImColor.new(148, 165, 138),            -- Mud brown
    DIVINATION = ImColor.new(145, 107, 255),     -- Light cyan
    INVENTION = ImColor.new(254,252,80),      -- Metallic blue-gray
    ARCHAEOLOGY = ImColor.new(110,90,70),      -- Sienna brown
    NECROMANCY = ImColor.new(89,1,150)         -- Dark purple
}

local SECONDS_IN_HOUR = 3600
local SECONDS_IN_DAY = 86400
local SECONDS_IN_MINUTE = 60
local XP_GAIN_TIMEOUT = 600  -- 10 minutes

-- Utility functions kept private
local function formatElapsedTime(start)
    local elapsed = os.difftime(os.time(), start)
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60
    return string.format("[%02d:%02d:%02d]", hours, minutes, seconds)
end

local function formatNumber(value)
    if value >= 1000000 then
        return string.format("%.2fm", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.2fk", value / 1000)
    else
        return tostring(value)
    end
end

function FuryGUI.new(API)
    local self = setmetatable({}, FuryGUI)
    self.API = API
    self.startTime = os.time()
    self.startXps = {}
    self.skillsTracked = {}
    self.IGPs = {}
    self.currentXps = {}
    self.xpGains = {}
    self.xpPHs = {}
    self.timeToLevelUp = {}
    self.lastXpGainTime = {}
    self.previousXps = {} 
    return self
end

-- Utility function to format time in hours to a readable string
local function formatTime(hours)
    if hours == nil or hours == "N/A" then
        return "N/A"
    end
    local hoursNum = tonumber(hours)
    if hoursNum == nil then
        return "N/A"
    end
    local totalSeconds = hoursNum * 3600  -- Convert hours to seconds
    local days = math.floor(totalSeconds / 86400)
    local remainingSecondsAfterDays = totalSeconds % 86400
    local hours = math.floor(remainingSecondsAfterDays / 3600)
    local remainingSecondsAfterHours = remainingSecondsAfterDays % 3600
    local minutes = math.floor(remainingSecondsAfterHours / 60)
    local seconds = math.floor(remainingSecondsAfterHours % 60)  -- Round seconds to the nearest integer

    if days > 0 then
        return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
    else
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end
end

function math.round(num)
    return math.floor(num + 0.5)
end

-- Update GUI string
function FuryGUI:updateGUIString(skill)
    self:refreshData(skill)
    local IGP = self.IGPs[skill]
    IGP.radius = self:calcProgressPercentage(skill, self.currentXps[skill]) / 100
    local ttl = self.timeToLevelUp[skill]
    if ttl == nil then
        ttl = "N/A"  -- Replace with a default value or placeholder string
    end
    IGP.string_value = string.format(
        "%s | %s: %d | XP: %s | XP/Hr: %s | TTL: %s",
        self.time,
        skill,
        self.API.XPLevelTable(self.currentXps[skill]),
        formatNumber(self.xpGains[skill]),
        formatNumber(self.xpPHs[skill]),
        formatTime(ttl)
    )
end

-- Draw progress bar
function FuryGUI:drawProgressBar(skill)
    DrawProgressBar(self.IGPs[skill])
end

-- Calculate progress percentage
function FuryGUI:calcProgressPercentage(skill, currentExp)
    local currentLevel = self.API.XPLevelTable(currentExp)
    if currentLevel == 120 then return 100 end
    local nextLevelExp = XPForLevel(currentLevel + 1)
    local currentLevelExp = XPForLevel(currentLevel)
    return math.floor((currentExp - currentLevelExp) / (nextLevelExp - currentLevelExp) * 100)
end


-- Refresh data values
function FuryGUI:refreshData(skill)
    if not self.startXps[skill] then
        -- New skill being tracked
        self.startXps[skill] = self.API.GetSkillXP(skill)
        self.skillsTracked[#self.skillsTracked + 1] = skill

        -- Create a new progress bar for this skill
        local newIGP = self.API.CreateIG_answer()
        newIGP.box_start = FFPOINT.new(5, 5 + (#self.skillsTracked - 1) * 30, 0) -- Stacking bars vertically
        newIGP.box_name = "PROGRESSBAR_" .. skill
        newIGP.colour = SKILL_COLORS[skill] or ImColor.new(100, 100, 100)  -- default to a grey if no color is defined
        self.IGPs[skill] = newIGP
    end

    local currentXp = self.API.GetSkillXP(skill)
    if currentXp == nil then
        print("Error: currentXp is nil for skill " .. skill)
        return
    end

    local elapsedMin = (os.time() - self.startTime) / 60
    local xpGain = currentXp - self.startXps[skill]

    self.currentXps[skill] = currentXp
    self.xpGains[skill] = xpGain
    self.xpPHs[skill] = math.floor((xpGain * 60) / elapsedMin)
    self.time = formatElapsedTime(self.startTime)

    local nextLevelExp = self.API.XPForLevel(self.API.XPLevelTable(currentXp) + 1)
    local xpToNextLevel = nextLevelExp - currentXp
    if self.xpPHs[skill] == 0 then
        self.timeToLevelUp[skill] = nil
    else
        local timeToLevelUpMinutes = xpToNextLevel / self.xpPHs[skill]
        self.timeToLevelUp[skill] = timeToLevelUpMinutes
    end
end

function FuryGUI:startTrackingSkill(skill)
    if not self.startXps[skill] then
        -- New skill being tracked
        self.startXps[skill] = self.API.GetSkillXP(skill)
        self.skillsTracked[#self.skillsTracked + 1] = skill

        -- Create a new progress bar for this skill
        local newIGP = self.API.CreateIG_answer()
        newIGP.box_start = FFPOINT.new(5, 5 + (#self.skillsTracked - 1) * 30, 0) -- Stacking bars vertically
        newIGP.box_name = "PROGRESSBAR_" .. skill
        newIGP.colour = SKILL_COLORS[skill] or ImColor.new(100, 100, 100)  -- default to a grey if no color is defined
        self.IGPs[skill] = newIGP
    end

    self:updateAndDrawGUI(skill)  -- Automatically update and draw the GUI
end


function FuryGUI:updateTrackedSkills()
    for _, skill in ipairs(self.skillsTracked) do
        --local currentXp = self.API.GetSkillXP(skill)
        --if currentXp ~= self.currentXps[skill] then
            self:refreshData(skill)
            self:updateAndDrawGUI(skill)
        --end
    end
end

-- Update and draw GUI
function FuryGUI:updateAndDrawGUI(skill)
    self:updateGUIString(skill)
    self:drawProgressBar(skill)
end

return FuryGUI
