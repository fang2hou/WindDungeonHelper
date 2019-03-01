local AddOnName, WDH = ...
local L, B, C, DB = WDH.L, WDH.Base, WDH.Config, WDH.DataBase
local gsub, format, pairs, select = string.gsub, string.format, pairs, select
local SA = WDH:NewModule("SpellAnnouncer", "AceHook-3.0", "AceEvent-3.0")

DB.defaults.profile.modules.SpellAnnouncer = {
    enable = true,
    interrupt = {
        enable = true,
        personal = true,
        channel = {
            instance = true,
            raidw = false,
            raid = true,
            party = true,
            yell = true,
            say = true,
            print = true,
        },
        custom = {
            enable = false,
            msg = L["I interrupted %target%\'s %target_spell%."],
        },
    }
}

C.ModulesOrder.SpellAnnouncer = 30
C.ModulesOption.SpellAnnouncer = {
    name = L["Spell Announcer"],
	type = "group",
	childGroups = "tree",
    args = {
        debugtext = {
            type = "description",
            name = function() return SA:debugShow() end,
        }
    }
}

function SA:OnInitialize()
    self.features = { "interrupt" }
    self.channel = {}
    self.output = {}
    self.db = DB.profile.modules.SpellAnnouncer

    self.playerUser = GetUnitName("player", false)

    self:SetOutputText()
    self:SetChatChannel()
end

function SA:OnEnable()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function SA:OnDisable()
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function SA:debugShow()
    return "test"
end

function SA:SetChatChannel()
    -- for better experience, module will cache output channel
    -- refresh all channel setting after zone or group changed.
    for _, feature in pairs(self.features) do
        self.channel[feature] = self:GetChatChannel(self.db[feature].channel)
    end
end

function SA:GetChatChannel(configdb)
    -- Instance > Raid Warning (Assistant) > Raid > Party > Yell > Say > Self
    -- If any of them has been changed to disable, module should call this method to generate new channel for announcement.
    if configdb.instance and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif configdb.raidw and IsInRaid(LE_PARTY_CATEGORY_HOME) and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or IsEveryoneAssistant()) then
        return "RAID_WARNING"
    elseif configdb.raid and IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return "RAID"
    elseif configdb.party and IsInGroup() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "PARTY"
    elseif configdb.yell then
        return "YELL"
    elseif configdb.say then
        return "SAY"
    elseif configdb.print then
        return "PRINT"
    end
end

function SA:SetOutputText()
	self.output.interrupt = self.db.interrupt.custom.enable and self.db.interrupt.custom.msg or L["I interrupted %target%\'s %target_spell%."]
end

function SA:GenerateInterruptOutput(str, player, spell, target, target_spell)
    local output = str
    output = gsub(output, "%%player%%", player)
	output = gsub(output, "%%spell%%", spell)
	output = gsub(output, "%%target%%", target)
	output = gsub(output, "%%target_spell%%", target_spell)
	return output
end

function SA:AnnounceInterrupt(...)
    local _, _, _, sourceGUID, sourceName, _, _, _, destName, _, _, _, mySpellId, _, targetSpellID = ...

    if not (mySpellId and targetSpellID) then return end
    
    if sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("pet") then
        local outputText = self:GenerateInterruptOutput(self.output.interrupt, sourceName, GetSpellLink(mySpellId), destName, GetSpellLink(targetSpellID))

        if self.channel.interrupt == "PRINT" then
            print(outputText)
        elseif self.channel.interrupt ~= nil then
            SendChatMessage(outputText, self.channel.interrupt)
        end
    end
end


function SA:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local type = select(2, CombatLogGetCurrentEventInfo())
    --timestamp, type, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags
    
    -- Interrupt
    if type == "SPELL_INTERRUPT" then
        self:AnnounceInterrupt(CombatLogGetCurrentEventInfo())
    end
end