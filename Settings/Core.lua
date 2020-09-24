local ns = select(2, ...)
local W, F, L = unpack(ns)
local ADB = LibStub("AceDB-3.0")

ns[4] = {
    enable = true,
    minimapIcon = {
        hide = false
    }
}

function W:BuildDatabase()
    self.Database = ADB:New("WindDungeonHelperDB", {profile = ns[4]})
    self.db = self.Database.profile
end
