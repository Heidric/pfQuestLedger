pfQuestLedger = CreateFrame("Frame", "pfQuestLedgerEventFrame", UIParent)

pfQuestLedger.version = "0.3.1"
pfQuestLedger.savedVariablesVersion = 2
pfQuestLedger.guildTargetedRequestCooldown = 15
pfQuestLedger.guildRefreshButtonTexture = "Interface\\AddOns\\pfQuestLedger\\assets\\guild_refresh.tga"
pfQuestLedger.guildButtonCooldown = 30 * 60
pfQuestLedger.guildAutoBroadcastInterval = 30 * 60
pfQuestLedger.guildAutoRequestInterval = 30 * 60
pfQuestLedger.guildAutoRequestOffset = 15 * 60
pfQuestLedger.guildAutoUnsafeRetry = 5 * 60
pfQuestLedger.guildAutoNoChangeDelay = 60 * 60
pfQuestLedger.guildAutoFreshRequestDelay = 60 * 60
pfQuestLedger.guildAutoRequestStaleAfter = 45 * 60
pfQuestLedger.guildAutoScheduleJitter = 300
pfQuestLedger.guildAutoReplyCooldown = 10 * 60
pfQuestLedger.guildAutoReplyJitter = 10
pfQuestLedger.guildAutoDirtyDebounce = 60
pfQuestLedger.guildAutoRequestMaxPerHour = 2
pfQuestLedger.questUpdateUIRefreshDebounce = 0.20
pfQuestLedger.questUpdateGuildDirtyDebounce = 0.75
pfQuestLedger.guildProtocolVersion = 2
pfQuestLedger.guildDebugLogLimit = 100
pfQuestLedger.guildRosterPruneInterval = 24 * 60 * 60
pfQuestLedger.msgSep = "~"
pfQuestLedger.appName = "pfQuestLedger"
pfQuestLedger.prefix = "PFLDG"
pfQuestLedger.tabOrder = { "QUESTS", "CHAINS", "ATTUNEMENTS", "GUILD" }
pfQuestLedger.tabLabels = {
  QUESTS = "Quests",
  CHAINS = "Chains",
  ATTUNEMENTS = "Attunements",
  GUILD = "Guild",
}
pfQuestLedger.statusOptions = { "COMPLETED", "IN_PROGRESS", "AVAILABLE", "BLOCKED", "NOT_COMPLETED" }
pfQuestLedger.chainStatusOptions = { "COMPLETED", "IN_PROGRESS", "AVAILABLE", "BLOCKED", "NOT_COMPLETED" }
pfQuestLedger.statusLabels = {
  COMPLETED = "Completed",
  IN_PROGRESS = "In progress",
  AVAILABLE = "Available",
  BLOCKED = "Blocked by prerequisites",
  NOT_COMPLETED = "Unavailable now",
}
pfQuestLedger.categoryOptions = { "GENERAL", "ATTUNEMENT", "CLASS", "PROF", "EVENT", "REPEATABLE", "PVP", "DUNGEON" }
pfQuestLedger.categoryLabels = {
  ATTUNEMENT = "Attunements",
  CLASS = "Class",
  PROF = "Profession",
  EVENT = "Event",
  REPEATABLE = "Repeatable",
  PVP = "PvP",
  DUNGEON = "Dungeon",
  GENERAL = "General",
}
pfQuestLedger.levelOptions = { "GREEN", "YELLOW", "ORANGE", "RED", "UNAVAILABLE" }
pfQuestLedger.levelLabels = {
  GREEN = "Green",
  YELLOW = "Yellow",
  ORANGE = "Orange",
  RED = "Red",
  UNAVAILABLE = "Unavailable",
}

pfQuestLedger.defaultQuestStatusFilters = {
  IN_PROGRESS = true,
  AVAILABLE = true,
}
pfQuestLedger.defaultChainStatusFilters = {
  IN_PROGRESS = true,
  AVAILABLE = true,
}
pfQuestLedger.defaultQuestCategoryFilters = {
  GENERAL = true,
  ATTUNEMENT = true,
  CLASS = true,
  PROF = true,
}
pfQuestLedger.defaultQuestLevelFilters = {
  GREEN = true,
  YELLOW = true,
}
pfQuestLedger.dungeonPatterns = {
  "dungeon", "instance", "5-man",
  "ragefire chasm", "wailing caverns", "the deadmines", "deadmines",
  "shadowfang keep", "blackfathom deeps", "the stockade", "stockade",
  "gnomeregan", "razorfen kraul", "scarlet monastery", "razorfen downs",
  "uldaman", "zul'farrak", "maraudon", "sunken temple", "temple of atal'hakkar",
  "blackrock depths", "lower blackrock spire", "upper blackrock spire",
  "dire maul", "stratholme", "scholomance",
}
pfQuestLedger.raidPatterns = {
  "raid", "40-man", "20-man", "10-man",
  "molten core", "onyxia", "blackwing lair", "zul'gurub",
  "ahn'qiraj", "ruins of ahn'qiraj", "temple of ahn'qiraj", "naxxramas",
}
pfQuestLedger.groupPatterns = {
  "group", "elite", "party", "suggested players", "group quest", "elite quest",
}
pfQuestLedger.filterMenuTitles = {
  status = "Status",
  chainStatus = "Chain status",
  category = "Tags",
  level = "Level",
}
pfQuestLedger.listPageSize = 14
pfQuestLedger.attunements = pfQuestLedger_Attunements or {}
pfQuestLedger.titleMap = {}
pfQuestLedger.normalizedTitleMap = {}
pfQuestLedger.questIndex = {}
pfQuestLedger.questRecordById = {}
pfQuestLedger.questData = {}
pfQuestLedger.questLocale = {}
pfQuestLedger.questParents = {}
pfQuestLedger.questChildren = {}
pfQuestLedger.chains = {}
pfQuestLedger.attByQuestId = {}
pfQuestLedger.questStarterCache = {}
pfQuestLedger.currentList = {}
pfQuestLedger.selection = { QUESTS = nil, CHAINS = nil, ATTUNEMENTS = nil, GUILD = nil }

local bitband = bit and bit.band

local function tcount(tbl)
  local count = 0
  if not tbl then return 0 end
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

local function ncmp(a, b)
  if a == b then return 0 end
  if a < b then return -1 end
  return 1
end

local function copyTableShallow(source)
  local copy = {}
  local key, value
  if not source then return copy end
  for key, value in pairs(source) do
    copy[key] = value
  end
  return copy
end

local function clampNumber(value, minValue, maxValue)
  value = tonumber(value) or 0
  if minValue ~= nil and value < minValue then value = minValue end
  if maxValue ~= nil and value > maxValue then value = maxValue end
  return value
end

local function deterministicNameJitter(name, modulo)
  local hash = 0
  local i
  name = tostring(name or "player")
  modulo = tonumber(modulo) or 180
  if modulo < 1 then modulo = 1 end

  for i = 1, string.len(name) do
    hash = math.mod(hash + (string.byte(name, i) * i), modulo)
  end

  return hash
end

function pfQuestLedger:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuestLedger: " .. (message or ""))
end

function pfQuestLedger:IsDebugEnabled()
  return pfQuestLedgerDB and pfQuestLedgerDB.profile and pfQuestLedgerDB.profile.debugEnabled and true or false
end

function pfQuestLedger:AddDebugEvent(kind, message)
  local entry, log
  if not pfQuestLedgerDB or not pfQuestLedgerDB.character then return end
  if not self:IsDebugEnabled() then return end

  pfQuestLedgerDB.character.debugLog = pfQuestLedgerDB.character.debugLog or {}
  log = pfQuestLedgerDB.character.debugLog
  entry = {
    at = time(),
    kind = tostring(kind or "info"),
    message = tostring(message or ""),
  }
  table.insert(log, entry)

  while table.getn(log) > (self.guildDebugLogLimit or 100) do
    table.remove(log, 1)
  end
end

function pfQuestLedger:DumpDebugLog()
  local log, i, entry, stamp, label
  log = pfQuestLedgerDB and pfQuestLedgerDB.character and pfQuestLedgerDB.character.debugLog or nil
  if not log or table.getn(log) == 0 then
    self:Print("Debug log is empty.")
    return
  end

  for i = 1, table.getn(log) do
    entry = log[i]
    stamp = entry.at and date("%H:%M:%S", entry.at) or "??:??:??"
    label = string.upper(tostring(entry.kind or "info"))
    self:Print("[DBG " .. stamp .. "][" .. label .. "] " .. tostring(entry.message or ""))
  end
end

function pfQuestLedger:ClearDebugLog()
  if not pfQuestLedgerDB or not pfQuestLedgerDB.character then return end
  pfQuestLedgerDB.character.debugLog = {}
end

function pfQuestLedger:ResetGuildCache()
  if not pfQuestLedgerDB then return end
  pfQuestLedgerDB.guild = pfQuestLedgerDB.guild or {}
  pfQuestLedgerDB.guild.members = {}
  pfQuestLedgerDB.guild.rosterMissingCounts = {}
  pfQuestLedgerDB.guild.lastPrunedAt = 0
  self:AddDebugEvent("guild", "Guild cache was reset.")
  if self.selection and self.selection.GUILD then
    self.selection.GUILD = nil
  end
  if self.frame and self.frame:IsShown() then
    self:Refresh()
  end
end

function pfQuestLedger:ResetGuildSyncState()
  local character
  if not pfQuestLedgerDB then return end
  pfQuestLedgerDB.character = pfQuestLedgerDB.character or {}
  character = pfQuestLedgerDB.character
  character.lastBroadcastAt = 0
  character.lastQuestSyncAt = 0
  character.lastGuildBroadcastClickAt = 0
  character.lastGuildRequestClickAt = 0
  character.lastPublishedGuildState = ""
  character.lastPublishedGuildStateAt = 0
  character.autoNextBroadcastAt = 0
  character.autoNextRequestAt = 0
  character.lastAutoRequestAt = 0
  character.guildStateDirty = false
  character.guildStateDirtyAt = 0
  character.pendingGuildReplies = {}
  character.lastGuildReplyByTarget = {}
  character.autoRequestHistory = {}
  character.lastTargetedGuildRequestAt = {}
  self.pendingGuildStateDirtyAt = nil
  self.pendingQuestUIRefreshAt = nil
  self:ClearDebugLog()
  self:EnsureAutoGuildSchedule(true)
  self:AddDebugEvent("sync", "Guild sync state was reset.")
  self:RefreshGuildActionButtons()
end

function pfQuestLedger:GetGuildRosterNameSet()
  local names, total, i, name
  names = {}

  if not GetGuildInfo or not GetGuildInfo("player") then
    return names, 0
  end

  if GuildRoster then
    GuildRoster()
  end

  if not GetNumGuildMembers or not GetGuildRosterInfo then
    return names, 0
  end

  total = GetNumGuildMembers(true) or GetNumGuildMembers() or 0
  for i = 1, total do
    name = GetGuildRosterInfo(i)
    if name and name ~= "" then
      names[name] = true
    end
  end

  return names, total
end

function pfQuestLedger:PruneGuildMemberCache(force)
  local guild, members, names, total, now, removed, name, missCounts, currentName, threshold
  if not GetGuildInfo or not GetGuildInfo("player") then
    return 0
  end

  guild = pfQuestLedgerDB and pfQuestLedgerDB.guild or nil
  members = guild and guild.members or nil
  if not members then return 0 end

  now = time()
  if not force and (guild.lastPrunedAt or 0) > 0 and (now - (guild.lastPrunedAt or 0)) < (self.guildRosterPruneInterval or (24 * 60 * 60)) then
    return 0
  end

  names, total = self:GetGuildRosterNameSet()
  if total < 1 or tcount(names) < 1 then
    return 0
  end

  currentName = UnitName("player") or ""
  missCounts = guild.rosterMissingCounts or {}
  guild.rosterMissingCounts = missCounts
  threshold = force and 1 or 3
  removed = 0

  for name in pairs(copyTableShallow(members)) do
    if name == currentName then
      missCounts[name] = nil
    elseif names[name] then
      missCounts[name] = nil
    else
      missCounts[name] = (tonumber(missCounts[name]) or 0) + 1
      if missCounts[name] >= threshold then
        members[name] = nil
        missCounts[name] = nil
        removed = removed + 1
      end
    end
  end

  for name in pairs(copyTableShallow(missCounts)) do
    if names[name] then
      missCounts[name] = nil
    end
  end

  guild.lastPrunedAt = now
  if removed > 0 then
    self:AddDebugEvent("guild", "Pruned " .. tostring(removed) .. " guild cache record(s) using the live guild roster.")
  end
  return removed
end

function pfQuestLedger:Trim(text)
  if not text then return "" end
  return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

function pfQuestLedger:Lower(text)
  if not text then return "" end
  return string.lower(text)
end

function pfQuestLedger:FormatClassName(classToken)
  local token = tostring(classToken or "")
  local labels = {
    DRUID = "Druid",
    HUNTER = "Hunter",
    MAGE = "Mage",
    PALADIN = "Paladin",
    PRIEST = "Priest",
    ROGUE = "Rogue",
    SHAMAN = "Shaman",
    WARLOCK = "Warlock",
    WARRIOR = "Warrior",
  }

  if labels[token] then
    return labels[token]
  end

  if token == "" then
    return "?"
  end

  token = string.lower(token)
  return string.upper(string.sub(token, 1, 1)) .. string.sub(token, 2)
end

function pfQuestLedger:FormatGuildSourceLabel(sourceType)
  local labels = {
    auto = "Auto broadcast",
    manual = "Manual broadcast",
    reply = "Reply",
    local_state = "Current character",
    unknown = "Unknown",
  }
  local key = tostring(sourceType or "unknown")
  return labels[key] or key
end

function pfQuestLedger:SanitizeGuildRecord(name, record)
  if type(record) ~= "table" then
    record = {}
  end

  record.class = tostring(record.class or "?")
  record.level = tonumber(record.level) or 0
  record.faction = tostring(record.faction or "Both")
  record.protocolVersion = tonumber(record.protocolVersion) or 1
  record.addonVersion = tostring(record.addonVersion or "")
  record.sourceType = tostring(record.sourceType or (record.isSelf and "local_state" or "unknown"))
  record.updatedAt = tonumber(record.updatedAt) or 0
  record.isSelf = record.isSelf and true or false
  if type(record.attunements) ~= "table" then
    record.attunements = {}
  end
  if type(record.reputations) ~= "table" then
    record.reputations = {}
  end
  return record
end

function pfQuestLedger:RunDBSelfCheckAndMigrations()
  local name, record
  local profile = pfQuestLedgerDB.profile or {}
  local character = pfQuestLedgerDB.character or {}
  local guild = pfQuestLedgerDB.guild or {}

  if type(profile.searchByTab) ~= "table" then profile.searchByTab = {} end
  if type(profile.page) ~= "table" then profile.page = {} end
  if type(profile.filters) ~= "table" then profile.filters = {} end
  if type(profile.launcher) ~= "table" then profile.launcher = {} end

  if type(character.manual) ~= "table" then character.manual = {} end
  if type(character.pendingGuildReplies) ~= "table" then character.pendingGuildReplies = {} end
  if type(character.lastGuildReplyByTarget) ~= "table" then character.lastGuildReplyByTarget = {} end
  if type(character.autoRequestHistory) ~= "table" then character.autoRequestHistory = {} end
  if type(character.debugLog) ~= "table" then character.debugLog = {} end
  if type(character.lastTargetedGuildRequestAt) ~= "table" then character.lastTargetedGuildRequestAt = {} end

  if type(guild.members) ~= "table" then guild.members = {} end
  if type(guild.rosterMissingCounts) ~= "table" then guild.rosterMissingCounts = {} end

  for name, record in pairs(guild.members) do
    guild.members[name] = self:SanitizeGuildRecord(name, record)
  end

  pfQuestLedgerDB.profile = profile
  pfQuestLedgerDB.character = character
  pfQuestLedgerDB.guild = guild
  pfQuestLedgerDB.dbVersion = self.savedVariablesVersion or 1
end

function pfQuestLedger:GetGuildNameColumnWidth()
  if self.guildNameColumnWidth and self.guildNameColumnWidth > 0 then
    return self.guildNameColumnWidth
  end

  local width = 140
  local fontString
  if self.frame then
    self.frame.guildNameMeasure = self.frame.guildNameMeasure or self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontString = self.frame.guildNameMeasure
    fontString:SetText("WWWWWWWWWWWW")
    if fontString.GetStringWidth then
      width = math.ceil((fontString:GetStringWidth() or width) + 8)
    end
  end

  if width < 140 then
    width = 140
  end

  self.guildNameColumnWidth = width
  return width
end

function pfQuestLedger:SetGuildRowHovered(row, hovered)
  if not row or not row.hover then return end

  if hovered then
    row.hover:Show()
  else
    row.hover:Hide()
  end
end

function pfQuestLedger:IsInGuild()
  return GetGuildInfo and GetGuildInfo("player") and true or false
end

function pfQuestLedger:IsGuildTabAvailable()
  return self:IsInGuild()
end

function pfQuestLedger:GetGuildDeleteConfirmSecondsRemaining(name)
  local pendingName = self.pendingGuildDeleteName
  local pendingUntil = tonumber(self.pendingGuildDeleteUntil) or 0
  local now = time()

  if pendingUntil > 0 and now >= pendingUntil then
    self.pendingGuildDeleteName = nil
    self.pendingGuildDeleteUntil = 0
    return 0
  end

  if not name or name == "" or pendingName ~= name or pendingUntil <= 0 then
    return 0
  end

  return pendingUntil - now
end

function pfQuestLedger:ArmGuildDelete(name)
  if not name or name == "" then return end
  self.pendingGuildDeleteName = name
  self.pendingGuildDeleteUntil = time() + 3
end

function pfQuestLedger:ClearGuildDeleteConfirm(name)
  if not name or self.pendingGuildDeleteName == name then
    self.pendingGuildDeleteName = nil
    self.pendingGuildDeleteUntil = 0
  end
end

function pfQuestLedger:RefreshGuildDeleteButtons()
  local rows, i, row, secondsRemaining
  if not self.frame or not self.frame.guildRows then return end

  rows = self.frame.guildRows
  for i = 1, table.getn(rows) do
    row = rows[i]
    if row and row.delete and row.memberName and row.delete:IsShown() then
      secondsRemaining = self:GetGuildDeleteConfirmSecondsRemaining(row.memberName)
      if secondsRemaining > 0 then
        row.delete:SetText("!")
      else
        row.delete:SetText("X")
      end
    end
  end
end


function pfQuestLedger:Contains(haystack, needle)
  haystack = self:Lower(haystack)
  needle = self:Lower(needle)
  if needle == "" then return true end
  return string.find(haystack, needle, 1, true) and true or false
end

function pfQuestLedger:GetFactionLabel()
  local faction = UnitFactionGroup("player")
  if faction == "Alliance" then
    return "Alliance"
  elseif faction == "Horde" then
    return "Horde"
  end
  return "Both"
end

function pfQuestLedger:IsSideVisible(side)
  if not side or side == "Both" then return true end
  return side == self:GetFactionLabel()
end

function pfQuestLedger:IsQuestDeprecated(id)
  local data = self.questData[id] or {}
  local locale = self.questLocale[id] or {}

  if data.deprecated or data.removed or data.obsolete or data.disabled then
    return true
  end

  local title = string.lower(locale.T or "")
  local objective = string.lower(locale.O or "")
  local description = string.lower(locale.D or "")
  if string.find(title, "deprecated", 1, true)
    or string.find(objective, "deprecated", 1, true)
    or string.find(description, "deprecated", 1, true) then
    return true
  end

  return false
end

function pfQuestLedger:IsQuestForPlayer(id)
  local data = self.questData[id]
  if not data or self:IsQuestDeprecated(id) then return false end

  if pfDatabase and bitband then
    local _, race = UnitRace("player")
    local _, class = UnitClass("player")

    if data.race and pfDatabase.GetBitByRace then
      local prace = pfDatabase:GetBitByRace(race)
      if prace and prace > 0 and bitband(data.race, prace) ~= prace then
        return false
      end
    end

    if data.class and pfDatabase.GetBitByClass then
      local pclass = pfDatabase:GetBitByClass(class)
      if pclass and pclass > 0 and bitband(data.class, pclass) ~= pclass then
        return false
      end
    end
  end

  return true
end

function pfQuestLedger:EnsureDB()
  if not pfQuestLedgerDB then
    pfQuestLedgerDB = {}
  end

  pfQuestLedgerDB.profile = pfQuestLedgerDB.profile or {}
  pfQuestLedgerDB.character = pfQuestLedgerDB.character or {}
  pfQuestLedgerDB.guild = pfQuestLedgerDB.guild or {}

  local profile = pfQuestLedgerDB.profile
  profile.activeTab = profile.activeTab or "QUESTS"
  profile.searchByTab = profile.searchByTab or {}
  if profile.search and profile.search ~= "" then
    profile.searchByTab[profile.activeTab] = profile.searchByTab[profile.activeTab] or profile.search
  end
  profile.searchByTab.QUESTS = profile.searchByTab.QUESTS or ""
  profile.searchByTab.CHAINS = profile.searchByTab.CHAINS or ""
  profile.searchByTab.ATTUNEMENTS = profile.searchByTab.ATTUNEMENTS or ""
  profile.searchByTab.GUILD = profile.searchByTab.GUILD or ""
  profile.search = profile.searchByTab[profile.activeTab] or ""
  profile.questStatus = profile.questStatus or "ALL"
  profile.questCategory = profile.questCategory or "ALL"
  profile.questLevel = profile.questLevel or "ALL"
  profile.filters = profile.filters or {}
  self:EnsureFilterSelections(profile)
  profile.page = profile.page or {}
  profile.page.QUESTS = profile.page.QUESTS or 1
  profile.page.CHAINS = profile.page.CHAINS or 1
  profile.page.ATTUNEMENTS = profile.page.ATTUNEMENTS or 1
  profile.page.GUILD = profile.page.GUILD or 1
  profile.manualStepInput = profile.manualStepInput or "1"
  if profile.guildMinLevelMigration ~= 1 then
    if profile.guildMinLevel == nil or tonumber(profile.guildMinLevel) == 1 then
      profile.guildMinLevel = 60
    end
    profile.guildMinLevelMigration = 1
  end
  profile.guildMinLevel = tonumber(profile.guildMinLevel) or 60
  profile.debugEnabled = profile.debugEnabled and true or false
  profile.launcher = profile.launcher or {}
  profile.launcher.x = profile.launcher.x or -220
  profile.launcher.y = profile.launcher.y or -120

  if profile.filterPresetVersion ~= 16 then
    profile.filters = profile.filters or {}
    profile.filters.status = self:CopyOptionSet(self.defaultQuestStatusFilters)
    profile.filters.chainStatus = self:CopyOptionSet(self.defaultChainStatusFilters)
    profile.filters.category = self:CopyOptionSet(self.defaultQuestCategoryFilters)
    profile.filters.level = self:CopyOptionSet(self.defaultQuestLevelFilters)
    profile.filterPresetVersion = 16
  end

  pfQuestLedgerDB.character.manual = pfQuestLedgerDB.character.manual or {}
  pfQuestLedgerDB.character.lastBroadcastAt = pfQuestLedgerDB.character.lastBroadcastAt or 0
  pfQuestLedgerDB.character.lastQuestSyncAt = pfQuestLedgerDB.character.lastQuestSyncAt or 0
  pfQuestLedgerDB.character.lastGuildBroadcastClickAt = pfQuestLedgerDB.character.lastGuildBroadcastClickAt or 0
  pfQuestLedgerDB.character.lastGuildRequestClickAt = pfQuestLedgerDB.character.lastGuildRequestClickAt or 0
  pfQuestLedgerDB.character.lastPublishedGuildState = pfQuestLedgerDB.character.lastPublishedGuildState or ""
  pfQuestLedgerDB.character.lastPublishedGuildStateAt = pfQuestLedgerDB.character.lastPublishedGuildStateAt or 0
  pfQuestLedgerDB.character.autoNextBroadcastAt = pfQuestLedgerDB.character.autoNextBroadcastAt or 0
  pfQuestLedgerDB.character.autoNextRequestAt = pfQuestLedgerDB.character.autoNextRequestAt or 0
  pfQuestLedgerDB.character.lastAutoRequestAt = pfQuestLedgerDB.character.lastAutoRequestAt or 0
  pfQuestLedgerDB.character.guildStateDirty = pfQuestLedgerDB.character.guildStateDirty and true or false
  pfQuestLedgerDB.character.guildStateDirtyAt = tonumber(pfQuestLedgerDB.character.guildStateDirtyAt) or 0
  pfQuestLedgerDB.character.pendingGuildReplies = pfQuestLedgerDB.character.pendingGuildReplies or {}
  pfQuestLedgerDB.character.lastGuildReplyByTarget = pfQuestLedgerDB.character.lastGuildReplyByTarget or {}
  pfQuestLedgerDB.character.autoRequestHistory = pfQuestLedgerDB.character.autoRequestHistory or {}
  pfQuestLedgerDB.character.debugLog = pfQuestLedgerDB.character.debugLog or {}
  pfQuestLedgerDB.character.lastTargetedGuildRequestAt = pfQuestLedgerDB.character.lastTargetedGuildRequestAt or {}

  pfQuestLedgerDB.guild.members = pfQuestLedgerDB.guild.members or {}
  pfQuestLedgerDB.guild.lastPrunedAt = tonumber(pfQuestLedgerDB.guild.lastPrunedAt) or 0
  pfQuestLedgerDB.guild.rosterMissingCounts = pfQuestLedgerDB.guild.rosterMissingCounts or {}

  self:RunDBSelfCheckAndMigrations()
end

function pfQuestLedger:NormalizeTitle(title)
  if not title then return "" end
  title = string.gsub(title, "’", "'")
  title = string.gsub(title, "‘", "'")
  title = string.gsub(title, "“", '"')
  title = string.gsub(title, "”", '"')
  return string.lower(title)
end

function pfQuestLedger:CopyOptionSet(source)
  local copy = {}
  if type(source) ~= "table" then
    return copy
  end
  local key, value
  for key, value in pairs(source) do
    if value then
      copy[key] = true
    end
  end
  return copy
end

function pfQuestLedger:DefaultOptionSet(options)
  local selected = {}
  local i
  for i = 1, table.getn(options) do
    selected[options[i]] = true
  end
  return selected
end

function pfQuestLedger:BuildInitialFilterSet(existing, options, legacy, defaults)
  if type(existing) == "table" then
    return self:CopyOptionSet(existing)
  end

  if legacy and legacy ~= "ALL" then
    local selected = {}
    selected[legacy] = true
    return selected
  end

  if type(defaults) == "table" then
    return self:CopyOptionSet(defaults)
  end

  return self:DefaultOptionSet(options)
end

function pfQuestLedger:EnsureFilterSelections(profile)
  profile.filters = profile.filters or {}
  profile.filters.status = self:BuildInitialFilterSet(profile.filters.status, self.statusOptions, profile.questStatus, self.defaultQuestStatusFilters)
  profile.filters.chainStatus = self:BuildInitialFilterSet(profile.filters.chainStatus, self.chainStatusOptions, nil, self.defaultChainStatusFilters)
  profile.filters.category = self:BuildInitialFilterSet(profile.filters.category, self.categoryOptions, profile.questCategory, self.defaultQuestCategoryFilters)
  profile.filters.level = self:BuildInitialFilterSet(profile.filters.level, self.levelOptions, profile.questLevel, self.defaultQuestLevelFilters)
end

function pfQuestLedger:GetFilterOptions(kind)
  if kind == "status" then
    return self.statusOptions
  elseif kind == "chainStatus" then
    return self.chainStatusOptions
  elseif kind == "category" then
    return self.categoryOptions
  elseif kind == "level" then
    return self.levelOptions
  end
  return {}
end

function pfQuestLedger:GetFilterLabels(kind)
  if kind == "status" or kind == "chainStatus" then
    return self.statusLabels
  elseif kind == "category" then
    return self.categoryLabels
  elseif kind == "level" then
    return self.levelLabels
  end
  return {}
end

function pfQuestLedger:GetActiveTab()
  return (pfQuestLedgerDB and pfQuestLedgerDB.profile and pfQuestLedgerDB.profile.activeTab) or "QUESTS"
end

function pfQuestLedger:GetSearchText(tab)
  self:EnsureDB()
  tab = tab or self:GetActiveTab()
  local profile = pfQuestLedgerDB.profile or {}
  profile.searchByTab = profile.searchByTab or {}
  return self:Trim(profile.searchByTab[tab] or "")
end

function pfQuestLedger:SetSearchTextForTab(tab, value)
  self:EnsureDB()
  tab = tab or self:GetActiveTab()
  pfQuestLedgerDB.profile.searchByTab = pfQuestLedgerDB.profile.searchByTab or {}
  pfQuestLedgerDB.profile.searchByTab[tab] = self:Trim(value or "")
  if tab == self:GetActiveTab() then
    pfQuestLedgerDB.profile.search = pfQuestLedgerDB.profile.searchByTab[tab]
  end
end

function pfQuestLedger:GetFilterSet(kind)
  self:EnsureDB()
  local filters = pfQuestLedgerDB.profile.filters or {}
  return filters[kind] or {}
end

function pfQuestLedger:IsFilterEnabled(kind, option)
  local selected = self:GetFilterSet(kind)
  return selected[option] and true or false
end

function pfQuestLedger:GetFilterSelectedCount(kind)
  local selected = self:GetFilterSet(kind)
  local count = 0
  local option, value
  for option, value in pairs(selected) do
    if value then
      count = count + 1
    end
  end
  return count
end

function pfQuestLedger:ResetFilterPages(kind)
  if not pfQuestLedgerDB or not pfQuestLedgerDB.profile or not pfQuestLedgerDB.profile.page then
    return
  end

  if kind == "chainStatus" then
    pfQuestLedgerDB.profile.page.CHAINS = 1
  else
    pfQuestLedgerDB.profile.page.QUESTS = 1
  end
end

function pfQuestLedger:SetFilterEnabled(kind, option, enabled)
  self:EnsureDB()
  pfQuestLedgerDB.profile.filters[kind] = pfQuestLedgerDB.profile.filters[kind] or {}
  if enabled then
    pfQuestLedgerDB.profile.filters[kind][option] = true
  else
    pfQuestLedgerDB.profile.filters[kind][option] = nil
  end
  self:ResetFilterPages(kind)
  if kind ~= "chainStatus" then
    pfQuestLedgerDB.profile.forcedQuestId = nil
  end
  self:RefreshFilterButtons()
  self:Refresh()
end

function pfQuestLedger:SetAllFilters(kind, enabled)
  self:EnsureDB()
  local options = self:GetFilterOptions(kind)
  local selected = {}
  local i
  if enabled then
    for i = 1, table.getn(options) do
      selected[options[i]] = true
    end
  end
  pfQuestLedgerDB.profile.filters[kind] = selected
  self:ResetFilterPages(kind)
  if kind ~= "chainStatus" then
    pfQuestLedgerDB.profile.forcedQuestId = nil
  end
  self:RefreshFilterButtons()
  self:Refresh()
end

function pfQuestLedger:GetFilterButtonText(kind)
  local total = table.getn(self:GetFilterOptions(kind))
  local selected = self:GetFilterSelectedCount(kind)
  local title = self.filterMenuTitles[kind] or kind
  return title .. " (" .. selected .. "/" .. total .. ")"
end

function pfQuestLedger:HideFilterMenus(except)
  if not self.frame or not self.frame.filterMenus then return end
  local kind, menu
  for kind, menu in pairs(self.frame.filterMenus) do
    if menu and menu ~= except then
      menu:Hide()
    end
  end
  self:UpdateFilterDismissFrame()
end

function pfQuestLedger:IsAnyFilterMenuShown()
  if not self.frame or not self.frame.filterMenus then
    return false
  end

  local _, menu
  for _, menu in pairs(self.frame.filterMenus) do
    if menu and menu:IsShown() then
      return true
    end
  end

  return false
end

function pfQuestLedger:UpdateFilterDismissFrame()
  if not self.frame or not self.frame.filterDismiss then
    return
  end

  if self:IsAnyFilterMenuShown() then
    self.frame.filterDismiss:Show()
  else
    self.frame.filterDismiss:Hide()
  end
end

function pfQuestLedger:IsFrameDescendant(frame, ancestor)
  if not frame or not ancestor then
    return false
  end

  while frame do
    if frame == ancestor then
      return true
    end
    if not frame.GetParent then
      break
    end
    frame = frame:GetParent()
  end

  return false
end

function pfQuestLedger:IsFilterInteractionFrame(frame)
  if not frame or not self.frame then
    return false
  end

  if self:IsFrameDescendant(frame, self.frame.statusButton)
    or self:IsFrameDescendant(frame, self.frame.chainStatusButton)
    or self:IsFrameDescendant(frame, self.frame.categoryButton)
    or self:IsFrameDescendant(frame, self.frame.levelButton) then
    return true
  end

  local _, menu
  for _, menu in pairs(self.frame.filterMenus or {}) do
    if menu and menu:IsShown() and self:IsFrameDescendant(frame, menu) then
      return true
    end
  end

  return false
end

function pfQuestLedger:PollFilterDismiss()
  if not self:IsAnyFilterMenuShown() then
    return
  end

  if not GetMouseFocus or not IsMouseButtonDown then
    return
  end

  local leftDown = IsMouseButtonDown("LeftButton") and true or false
  local rightDown = IsMouseButtonDown("RightButton") and true or false

  self._filterDismissState = self._filterDismissState or { left = false, right = false }

  if self._filterDismissState.left and not leftDown then
    local focus = GetMouseFocus()
    if not self:IsFilterInteractionFrame(focus) then
      self:HideFilterMenus()
      focus = nil
    end
  elseif self._filterDismissState.right and not rightDown then
    local focus = GetMouseFocus()
    if not self:IsFilterInteractionFrame(focus) then
      self:HideFilterMenus()
      focus = nil
    end
  end

  self._filterDismissState.left = leftDown
  self._filterDismissState.right = rightDown
end

function pfQuestLedger:RefreshFilterMenu(kind)
  if not self.frame or not self.frame.filterMenus then return end
  local menu = self.frame.filterMenus[kind]
  if not menu then return end

  local i, check, option
  for i = 1, table.getn(menu.checks) do
    check = menu.checks[i]
    option = menu.options[i]
    check:SetChecked(self:IsFilterEnabled(kind, option) and 1 or nil)
  end
end

function pfQuestLedger:RefreshFilterButtons()
  if not self.frame then return end
  if self.frame.statusButton then
    self.frame.statusButton:SetText(self:GetFilterButtonText("status"))
  end
  if self.frame.chainStatusButton then
    self.frame.chainStatusButton:SetText(self:GetFilterButtonText("chainStatus"))
  end
  if self.frame.categoryButton then
    self.frame.categoryButton:SetText(self:GetFilterButtonText("category"))
  end
  if self.frame.levelButton then
    self.frame.levelButton:SetText(self:GetFilterButtonText("level"))
  end
  self:RefreshFilterMenu("status")
  self:RefreshFilterMenu("chainStatus")
  self:RefreshFilterMenu("category")
  self:RefreshFilterMenu("level")
end

function pfQuestLedger:ToggleFilterMenu(kind, anchor)
  if not self.frame or not self.frame.filterMenus then return end
  local menu = self.frame.filterMenus[kind]
  if not menu then return end

  if menu:IsShown() then
    menu:Hide()
    self:UpdateFilterDismissFrame()
    return
  end

  self:HideFilterMenus(menu)
  self:RefreshFilterMenu(kind)
  menu:ClearAllPoints()

  local anchorBottom = anchor and anchor.GetBottom and anchor:GetBottom() or 0
  local anchorTop = anchor and anchor.GetTop and anchor:GetTop() or 0
  local uiBottom = UIParent and UIParent.GetBottom and UIParent:GetBottom() or 0
  local uiTop = UIParent and UIParent.GetTop and UIParent:GetTop() or 768
  local menuHeight = menu:GetHeight() or 0

  if anchorBottom - menuHeight - 6 < uiBottom and anchorTop + menuHeight + 6 <= uiTop then
    menu:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
  else
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  end

  menu:SetFrameStrata("TOOLTIP")
  menu:SetToplevel(true)
  menu:SetFrameLevel((self.frame and self.frame:GetFrameLevel() or 1) + 40)

  menu:Show()
  if menu.Raise then
    menu:Raise()
  end
  self:UpdateFilterDismissFrame()
end

function pfQuestLedger:CreateFilterMenu(parent, kind, width)
  local options = self:GetFilterOptions(kind)
  local labels = self:GetFilterLabels(kind)
  local rows = table.getn(options)
  local height = 34 + (rows * 22) + 28

  local menu = CreateFrame("Frame", nil, UIParent)
  menu:SetWidth(width)
  menu:SetHeight(height)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetFrameLevel(120)
  menu:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  menu:SetBackdropColor(0, 0, 0, 1)
  menu:SetToplevel(true)
  menu:SetClampedToScreen(true)
  menu:EnableMouse(true)
  menu:SetScript("OnHide", function() pfQuestLedger:UpdateFilterDismissFrame() end)
  menu:Hide()
  menu.kind = kind
  menu.options = options
  menu.labels = labels
  menu.checks = {}

  local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 10, -10)
  title:SetText(self.filterMenuTitles[kind] or kind)
  menu.title = title

  local i, check, label
  for i = 1, rows do
    check = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
    check:SetWidth(22)
    check:SetHeight(22)
    check:SetPoint("TOPLEFT", 10, -12 - (i * 22))
    check:SetFrameStrata("TOOLTIP")
    check:SetFrameLevel(125)
    check.option = options[i]
    check:SetScript("OnClick", function()
      pfQuestLedger:SetFilterEnabled(kind, this.option, this:GetChecked() and true or false)
    end)

    label = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    label:SetText(labels[options[i]] or options[i])
    check.label = label
    menu.checks[i] = check
  end

  local allButton = self:CreateButton(menu, 48, 20, "All")
  allButton:SetPoint("BOTTOMLEFT", 8, 8)
  allButton:SetFrameStrata("TOOLTIP")
  allButton:SetFrameLevel(125)
  allButton:SetScript("OnClick", function()
    pfQuestLedger:SetAllFilters(kind, true)
  end)
  menu.allButton = allButton

  local noneButton = self:CreateButton(menu, 52, 20, "None")
  noneButton:SetPoint("LEFT", allButton, "RIGHT", 6, 0)
  noneButton:SetFrameStrata("TOOLTIP")
  noneButton:SetFrameLevel(125)
  noneButton:SetScript("OnClick", function()
    pfQuestLedger:SetAllFilters(kind, false)
  end)
  menu.noneButton = noneButton

  local closeButton = self:CreateButton(menu, 48, 20, "Close")
  closeButton:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -8, 8)
  closeButton:SetFrameStrata("TOOLTIP")
  closeButton:SetFrameLevel(125)
  closeButton:SetScript("OnClick", function()
    menu:Hide()
  end)
  menu.closeButton = closeButton

  return menu
end

function pfQuestLedger:GetTitleMap(title)
  if not title then return nil end
  return self.titleMap[title] or self.normalizedTitleMap[self:NormalizeTitle(title)]
end

function pfQuestLedger:ResolveQuestIdByTitle(title)
  local matches = self:GetTitleMap(title)
  if not matches or table.getn(matches) == 0 then
    return nil
  end

  if table.getn(matches) == 1 then
    return matches[1]
  end

  local _, race = UnitRace("player")
  local prace = pfDatabase and pfDatabase.GetBitByRace and pfDatabase:GetBitByRace(race) or nil

  if prace and bitband then
    local i, id, data
    for i = 1, table.getn(matches) do
      id = matches[i]
      data = self.questData[id]
      if data and data.race and bitband(data.race, prace) == prace then
        return id
      end
    end
  end

  return matches[1]
end

function pfQuestLedger:GetQuestDisplayLevel(id)
  local data = self.questData[id] or {}
  return tonumber(data.lvl) or tonumber(data.min) or 0
end

function pfQuestLedger:GetQuestRequiredLevel(id)
  local data = self.questData[id] or {}
  return tonumber(data.min) or 0
end

function pfQuestLedger:CompareQuestIds(aId, bId)
  local aLevel = self:GetQuestDisplayLevel(aId)
  local bLevel = self:GetQuestDisplayLevel(bId)
  if aLevel ~= bLevel then
    return aLevel < bLevel
  end

  local aTitle = (self.questLocale[aId] and self.questLocale[aId].T) or ""
  local bTitle = (self.questLocale[bId] and self.questLocale[bId].T) or ""
  if aTitle ~= bTitle then
    return aTitle < bTitle
  end

  return aId < bId
end

function pfQuestLedger:BuildQuestCaches()
  if not pfDB or not pfDB["quests"] or not pfDB["quests"]["loc"] or not pfDB["quests"]["data"] then
    return false
  end

  local qloc = pfDB["quests"]["loc"]
  local qdata = pfDB["quests"]["data"]
  local index = {}
  local titleMap = {}
  local normalizedTitleMap = {}
  local recordById = {}
  local id, locale, data, title, record, normalized

  self.questLocale = qloc
  self.questData = qdata

  for id, locale in pairs(qloc) do
    data = qdata[id]
    title = locale and locale.T
    if data and title and title ~= "" and not self:IsQuestDeprecated(id) then
      record = {
        id = id,
        title = title,
        titleLower = string.lower(title),
        lvl = tonumber(data.lvl) or tonumber(data.min) or 0,
        min = tonumber(data.min) or 0,
        class = data.class,
        skill = data.skill,
        event = data.event,
      }
      table.insert(index, record)
      recordById[id] = record
      titleMap[title] = titleMap[title] or {}
      table.insert(titleMap[title], id)
      normalized = self:NormalizeTitle(title)
      normalizedTitleMap[normalized] = normalizedTitleMap[normalized] or {}
      table.insert(normalizedTitleMap[normalized], id)
    end
  end

  table.sort(index, function(a, b)
    if a.lvl ~= b.lvl then
      return a.lvl < b.lvl
    end
    if a.title ~= b.title then
      return a.title < b.title
    end
    return a.id < b.id
  end)

  self.questIndex = index
  self.questRecordById = recordById
  self.titleMap = titleMap
  self.normalizedTitleMap = normalizedTitleMap
  return true
end

function pfQuestLedger:CollectQuestIds(value, out, seen)
  if not value then return end
  out = out or {}
  seen = seen or {}

  local t = type(value)
  if t == "number" then
    if value > 0 and not seen[value] then
      seen[value] = true
      table.insert(out, value)
    end
    return out
  elseif t == "string" then
    local id = tonumber(value)
    if id and id > 0 and not seen[id] then
      seen[id] = true
      table.insert(out, id)
    end
    return out
  elseif t ~= "table" then
    return out
  end

  local k, v, id
  for k, v in pairs(value) do
    id = tonumber(k)
    if id and id > 0 and not seen[id] then
      seen[id] = true
      table.insert(out, id)
    end

    if type(v) == "table" then
      self:CollectQuestIds(v, out, seen)
    else
      id = tonumber(v)
      if id and id > 0 and not seen[id] then
        seen[id] = true
        table.insert(out, id)
      end
    end
  end

  return out
end

function pfQuestLedger:BuildQuestGraph()
  self.questParents = {}
  self.questChildren = {}

  local id, data, parents, children, i, parentId, childId
  for id, data in pairs(self.questData or {}) do
    self.questParents[id] = self.questParents[id] or {}
    self.questChildren[id] = self.questChildren[id] or {}

    parents = self:CollectQuestIds(data and data.pre)
    if parents then
      for i = 1, table.getn(parents) do
        parentId = parents[i]
        if parentId ~= id then
          table.insert(self.questParents[id], parentId)
          self.questChildren[parentId] = self.questChildren[parentId] or {}
          table.insert(self.questChildren[parentId], id)
        end
      end
    end

    children = self:CollectQuestIds(data and (data.nxt or data.next))
    if children then
      for i = 1, table.getn(children) do
        childId = children[i]
        if childId ~= id then
          self.questParents[childId] = self.questParents[childId] or {}
          self.questChildren[id] = self.questChildren[id] or {}
          table.insert(self.questParents[childId], id)
          table.insert(self.questChildren[id], childId)
        end
      end
    end
  end

  for id, parents in pairs(self.questParents) do
    table.sort(parents, function(a, b) return pfQuestLedger:CompareQuestIds(a, b) end)
  end
  for id, children in pairs(self.questChildren) do
    table.sort(children, function(a, b) return pfQuestLedger:CompareQuestIds(a, b) end)
  end
end

function pfQuestLedger:BuildChains()
  self.chains = {}

  local relevant = {}
  local id
  for id, _ in pairs(self.questRecordById or {}) do
    if self:IsQuestForPlayer(id) and (
      (self.questParents[id] and table.getn(self.questParents[id]) > 0)
      or (self.questChildren[id] and table.getn(self.questChildren[id]) > 0)
    ) then
      relevant[id] = true
    end
  end

  local visited = {}
  local componentOrder = {}
  for _, record in ipairs(self.questIndex) do
    if relevant[record.id] then
      table.insert(componentOrder, record.id)
    end
  end

  local queue, component, head, currentId, neighbours, i, nextId
  local componentIndex = 0

  for i = 1, table.getn(componentOrder) do
    id = componentOrder[i]
    if not visited[id] then
      component = {}
      queue = { id }
      visited[id] = true
      head = 1

      while queue[head] do
        currentId = queue[head]
        head = head + 1
        table.insert(component, currentId)

        neighbours = self.questParents[currentId] or {}
        for _, nextId in ipairs(neighbours) do
          if relevant[nextId] and not visited[nextId] then
            visited[nextId] = true
            table.insert(queue, nextId)
          end
        end

        neighbours = self.questChildren[currentId] or {}
        for _, nextId in ipairs(neighbours) do
          if relevant[nextId] and not visited[nextId] then
            visited[nextId] = true
            table.insert(queue, nextId)
          end
        end
      end

      if table.getn(component) > 1 then
        componentIndex = componentIndex + 1
        table.sort(component, function(a, b) return pfQuestLedger:CompareQuestIds(a, b) end)

        local inComponent = {}
        for _, currentId in ipairs(component) do
          inComponent[currentId] = true
        end

        local roots = {}
        local minLevel = nil
        local firstId = component[1]
        for _, currentId in ipairs(component) do
          if not minLevel or self:GetQuestDisplayLevel(currentId) < minLevel then
            minLevel = self:GetQuestDisplayLevel(currentId)
          end
          local hasParentInComponent = false
          for _, nextId in ipairs(self.questParents[currentId] or {}) do
            if inComponent[nextId] then
              hasParentInComponent = true
              break
            end
          end
          if not hasParentInComponent then
            table.insert(roots, currentId)
          end
        end

        if table.getn(roots) == 0 then
          table.insert(roots, firstId)
        else
          table.sort(roots, function(a, b) return pfQuestLedger:CompareQuestIds(a, b) end)
        end

        local steps = {}
        local stepVisited = {}
        local function addNode(nodeId, depth)
          if stepVisited[nodeId] then return end
          stepVisited[nodeId] = true
          table.insert(steps, {
            kind = "quest",
            questId = nodeId,
            title = (pfQuestLedger.questLocale[nodeId] and pfQuestLedger.questLocale[nodeId].T) or ("Quest " .. nodeId),
            depth = depth or 0,
          })

          local sortedChildren = {}
          for _, childId in ipairs(pfQuestLedger.questChildren[nodeId] or {}) do
            if inComponent[childId] then
              table.insert(sortedChildren, childId)
            end
          end
          table.sort(sortedChildren, function(a, b) return pfQuestLedger:CompareQuestIds(a, b) end)
          for _, childId in ipairs(sortedChildren) do
            addNode(childId, (depth or 0) + 1)
          end
        end

        for _, currentId in ipairs(roots) do
          addNode(currentId, 0)
        end
        for _, currentId in ipairs(component) do
          addNode(currentId, 0)
        end

        local rootTitle = (self.questLocale[roots[1]] and self.questLocale[roots[1]].T) or ((self.questLocale[firstId] and self.questLocale[firstId].T) or ("Quest " .. firstId))
        table.insert(self.chains, {
          id = "CHAIN_" .. componentIndex,
          _listKey = "CHAIN:" .. componentIndex,
          name = rootTitle,
          category = "Quest chain",
          group = "General",
          side = "Both",
          level = minLevel or 0,
          summary = table.getn(component) .. " linked quests from the pfQuest quest graph.",
          steps = steps,
        })
      end
    end
  end
end

function pfQuestLedger:GetAttunementEntryQuestId(att)
  local steps = att and att.steps or nil
  local i, step, qid

  if not steps then
    return nil
  end

  for i = 1, table.getn(steps) do
    step = steps[i]
    if step and step.kind ~= "level" and step.kind ~= "start" and step.kind ~= "attuned" then
      qid = step.questId or step.resolvedQuestId
      if qid then
        return qid
      end
    end
  end

  return nil
end

function pfQuestLedger:GetAttunementEntryLevel(att)
  local qid
  local level = 0

  if not att then
    return 0
  end

  if att.id == "K40_A" or att.id == "K40_H" then
    return 60
  end

  qid = self:GetAttunementEntryQuestId(att)
  if qid then
    level = self:GetQuestRequiredLevel(qid)
    if not level or level < 1 then
      level = self:GetQuestDisplayLevel(qid)
    end
  end

  if (not level or level < 1) and att.level and att.level > 0 then
    level = att.level
  end

  return tonumber(level) or 0
end

function pfQuestLedger:BuildAttunementLevelStep(att, templateStep)
  local step = copyTableShallow(templateStep or {})
  local level = self:GetAttunementEntryLevel(att)

  if level < 1 then
    return nil, 0
  end

  step.kind = "level"
  step.requiredLevel = level
  step.questId = nil
  step.resolvedQuestId = nil
  step.completeIcon = nil
  step.title = "Reach level " .. level
  step.subtitle = "Required minimum"
  step.icon = step.icon or "Interface\\Icons\\Spell_Holy_InnerFire"
  step.note = "Reach level " .. level .. " before starting the " .. (att.name or "attunement") .. " chain."

  return step, level
end

function pfQuestLedger:EnsureAttunementVisualSteps(att)
  if not att or att._visualStepsNormalized then
    return
  end

  local sourceSteps = att.steps or {}
  local resultSteps = {}
  local i, step, qid
  local hasLevel = false
  local hasAttuned = false
  local firstQuestId = nil
  local lastQuestId = nil
  local insertedLevel = false
  local levelStep
  local entryLevel = self:GetAttunementEntryLevel(att)

  if entryLevel and entryLevel > 0 then
    att.level = entryLevel
  end

  for i = 1, table.getn(sourceSteps) do
    step = sourceSteps[i]
    if step.kind == "level" or step.kind == "start" then
      hasLevel = true
    elseif step.kind == "attuned" then
      hasAttuned = true
    end

    qid = step.questId or step.resolvedQuestId
    if qid and not firstQuestId then
      firstQuestId = qid
    end
    if qid then
      lastQuestId = qid
    end
  end

  if not hasLevel then
    levelStep = nil
    if entryLevel and entryLevel > 0 then
      levelStep = self:BuildAttunementLevelStep(att)
    end

    if levelStep then
      table.insert(resultSteps, levelStep)
      insertedLevel = true
    else
      table.insert(resultSteps, {
        kind = "start",
        questId = firstQuestId,
        title = "Begin attunement",
        subtitle = att.group or "Entry point",
        icon = att.icon or "Interface\\Icons\\INV_Scroll_03",
        note = "Start the " .. (att.name or "attunement") .. " chain.",
      })
    end
  end

  for i = 1, table.getn(sourceSteps) do
    step = sourceSteps[i]
    if step.kind == "level" or step.kind == "start" then
      if not insertedLevel then
        levelStep = nil
        if entryLevel and entryLevel > 0 then
          levelStep = self:BuildAttunementLevelStep(att, step)
        end

        if levelStep then
          table.insert(resultSteps, levelStep)
        else
          table.insert(resultSteps, copyTableShallow(step))
        end
        insertedLevel = true
      end
    else
      table.insert(resultSteps, copyTableShallow(step))
    end
  end

  if not hasAttuned and lastQuestId then
    table.insert(resultSteps, {
      kind = "attuned",
      questId = lastQuestId,
      title = "Attuned",
      subtitle = "Completed",
      icon = att.icon or "Interface\\Icons\\INV_Jewelry_Talisman_11",
      completeIcon = att.icon or "Interface\\Icons\\INV_Jewelry_Talisman_11",
      note = "Complete the attunement chain to unlock " .. (att.name or "this attunement") .. ".",
    })
  end

  att.steps = resultSteps
  att._visualStepsNormalized = true
  att._graphLayoutCache = nil
  att._logicalStepMap = nil
end

function pfQuestLedger:ResolveAttunementSteps()
  self.attByQuestId = {}

  local attIndex, stepIndex, att, step, qid
  for attIndex = 1, table.getn(self.attunements) do
    att = self.attunements[attIndex]
    self:EnsureAttunementVisualSteps(att)
    att._index = attIndex
    att._listKey = "ATT:" .. att.id .. ":" .. (att.side or "Both")

    for stepIndex = 1, table.getn(att.steps) do
      step = att.steps[stepIndex]
      if step.kind == "quest" then
        qid = step.questId or self:ResolveQuestIdByTitle(step.title)
        step.resolvedQuestId = qid
        if qid then
          self.attByQuestId[qid] = self.attByQuestId[qid] or {}
          table.insert(self.attByQuestId[qid], att._listKey)
        end
      end
    end
  end
end

function pfQuestLedger:IsQuestCompleted(id)
  return pfQuest_history and pfQuest_history[id] and true or false
end

function pfQuestLedger:IsQuestActive(id)
  return pfQuest and pfQuest.questlog and pfQuest.questlog[id] and true or false
end

function pfQuestLedger:IsQuestAvailable(id)
  if not pfDatabase or not pfDatabase.QuestFilter or not self.questData[id] then
    return false
  end

  local plevel = UnitLevel("player") or 0
  local _, race = UnitRace("player")
  local _, class = UnitClass("player")
  local prace = pfDatabase.GetBitByRace and pfDatabase:GetBitByRace(race) or 0
  local pclass = pfDatabase.GetBitByClass and pfDatabase:GetBitByClass(class) or 0
  return pfDatabase:QuestFilter(id, plevel, pclass, prace) and true or false
end

function pfQuestLedger:GetQuestStatus(id)
  if self:IsQuestActive(id) then
    return "IN_PROGRESS"
  elseif self:IsQuestCompleted(id) then
    return "COMPLETED"
  elseif self:IsQuestAvailable(id) then
    return "AVAILABLE"
  end

  local data = self.questData[id]
  if data and data.pre then
    return "BLOCKED"
  end

  return "NOT_COMPLETED"
end

function pfQuestLedger:GetQuestStatusText(status)
  return self.statusLabels[status] or status
end

function pfQuestLedger:GetStatusColor(status)
  if status == "COMPLETED" then
    return "|cff88cc88"
  elseif status == "IN_PROGRESS" then
    return "|cff55aaff"
  elseif status == "AVAILABLE" then
    return "|cffffff55"
  elseif status == "BLOCKED" then
    return "|cffff7777"
  end
  return "|cffffffff"
end

function pfQuestLedger:GetLevelColor(bucket)
  if bucket == "GREEN" then
    return "|cff40c040"
  elseif bucket == "YELLOW" then
    return "|cffffff55"
  elseif bucket == "ORANGE" then
    return "|cffffaa33"
  elseif bucket == "RED" then
    return "|cffff5555"
  elseif bucket == "UNAVAILABLE" then
    return "|cff999999"
  end
  return "|cffbbbbbb"
end

function pfQuestLedger:GetLevelColorByLevel(level)
  local playerLevel = UnitLevel("player") or 0
  level = tonumber(level) or 0
  if level <= 0 then
    return "|cffbbbbbb"
  elseif level >= playerLevel + 5 then
    return "|cffff5555"
  elseif level >= playerLevel + 3 then
    return "|cffffaa33"
  elseif level >= playerLevel - 2 then
    return "|cffffff55"
  elseif level >= playerLevel - 25 then
    return "|cff40c040"
  end
  return "|cff999999"
end


function pfQuestLedger:GetQuestLevelBucket(id)
  local playerLevel = UnitLevel("player") or 0
  local minLevel = self:GetQuestRequiredLevel(id)
  local questLevel = self:GetQuestDisplayLevel(id)

  if minLevel > playerLevel then
    return "UNAVAILABLE"
  elseif questLevel >= playerLevel + 5 then
    return "RED"
  elseif questLevel >= playerLevel + 3 then
    return "ORANGE"
  elseif questLevel >= playerLevel - 2 then
    return "YELLOW"
  elseif questLevel >= playerLevel - 25 then
    return "GREEN"
  end

  return "GRAY"
end

function pfQuestLedger:QuestTextContains(id, patterns)
  local data = self.questData[id] or {}
  local locale = self.questLocale[id] or {}
  local fields = {
    locale.T, locale.O, locale.D,
    data.flags, data.type, data.tag, data.questTag, data.questType,
    data.category, data.group, data.zone, data.sort,
  }

  local i, j, value, lowered
  for i = 1, table.getn(fields) do
    value = fields[i]
    if type(value) == "string" and value ~= "" then
      lowered = string.lower(value)
      for j = 1, table.getn(patterns) do
        if string.find(lowered, patterns[j], 1, true) then
          return true
        end
      end
    end
  end

  return false
end

function pfQuestLedger:IsQuestPvP(id)
  local data = self.questData[id] or {}
  if data.pvp or data.battleground or data.arena then
    return true
  end
  return self:QuestTextContains(id, { "pvp", "battleground", "warsong", "arathi basin", "alterac valley" })
end

function pfQuestLedger:IsQuestDungeon(id)
  local data = self.questData[id] or {}
  if data.dungeon or data.instance then
    return true
  end
  return self:QuestTextContains(id, self.dungeonPatterns)
end

function pfQuestLedger:IsQuestRaid(id)
  local data = self.questData[id] or {}
  if data.raid then
    return true
  end
  return self:QuestTextContains(id, self.raidPatterns)
end

function pfQuestLedger:IsQuestGroup(id)
  local data = self.questData[id] or {}
  if data.elite or data.groupquest or data.groupq or data.party then
    return true
  end
  if type(data.group) == "number" and data.group > 0 then
    return true
  end
  return self:QuestTextContains(id, self.groupPatterns)
end

function pfQuestLedger:IsQuestRepeatable(id)
  local data = self.questData[id] or {}
  if data.repeatable or data.rpt or data["repeat"] or data.daily or data.dailyi or data.rp then
    return true
  end
  if type(data.flags) == "string" then
    local flags = string.lower(data.flags)
    if string.find(flags, "repeat", 1, true) or string.find(flags, "daily", 1, true) then
      return true
    end
  end
  return false
end

function pfQuestLedger:GetQuestCategoryTags(id)
  local tags = {}
  local data = self.questData[id] or {}
  if self.attByQuestId[id] then
    tags.ATTUNEMENT = true
  end
  if data.class then
    tags.CLASS = true
  end
  if data.skill then
    tags.PROF = true
  end
  if data.event then
    tags.EVENT = true
  end
  if self:IsQuestRepeatable(id) then
    tags.REPEATABLE = true
  end
  if self:IsQuestPvP(id) then
    tags.PVP = true
  end
  if self:IsQuestDungeon(id) then
    tags.DUNGEON = true
  end
  local hasAny = false
  local _
  for _ in pairs(tags) do
    hasAny = true
    break
  end
  if not hasAny then
    tags.GENERAL = true
  end
  return tags
end


function pfQuestLedger:MatchesFilterSet(kind, value)
  local selected = self:GetFilterSet(kind)
  if type(selected) ~= "table" then
    return true
  end

  local key, flag, hasAny = nil, nil, false
  for key, flag in pairs(selected) do
    if flag then
      hasAny = true
      break
    end
  end

  if not hasAny then
    return false
  end

  return selected[value] and true or false
end

function pfQuestLedger:QuestMatchesCategory(id)
  local tags = self:GetQuestCategoryTags(id)
  local hasTags = false
  local tag
  for tag in pairs(tags) do
    hasTags = true
    break
  end
  if not hasTags then
    return true
  end

  local selected = self:GetFilterSet("category")
  local key, flag, hasAny = nil, nil, false
  for key, flag in pairs(selected) do
    if flag then
      hasAny = true
      break
    end
  end

  if not hasAny then
    return false
  end

  for tag in pairs(tags) do
    if selected[tag] then
      return true
    end
  end
  return false
end

function pfQuestLedger:QuestMatchesStatus(id)
  return self:MatchesFilterSet("status", self:GetQuestStatus(id))
end

function pfQuestLedger:QuestMatchesLevelFilter(id)
  return self:MatchesFilterSet("level", self:GetQuestLevelBucket(id))
end

function pfQuestLedger:GetVisibleQuestList()
  local results = {}
  local search = self:GetSearchText("QUESTS")
  local i, record

  for i = 1, table.getn(self.questIndex) do
    record = self.questIndex[i]
    if self:IsQuestForPlayer(record.id)
      and self:QuestMatchesStatus(record.id)
      and self:QuestMatchesCategory(record.id)
      and self:QuestMatchesLevelFilter(record.id)
      and self:Contains(record.title, search) then
      table.insert(results, record)
    end
  end

  local forcedId = pfQuestLedgerDB.profile and pfQuestLedgerDB.profile.forcedQuestId or nil
  if forcedId and self:IsQuestForPlayer(forcedId) then
    local found = false
    for i = 1, table.getn(results) do
      if results[i].id == forcedId then
        found = true
        break
      end
    end
    if not found and self.questRecordById[forcedId] then
      table.insert(results, 1, self.questRecordById[forcedId])
    end
  end

  return results
end

function pfQuestLedger:GetAttunementSortLevel(att)
  local entryLevel = self:GetAttunementEntryLevel(att)
  if entryLevel and entryLevel > 0 then
    return entryLevel
  end

  if att and att.level and att.level > 0 then
    return att.level
  end

  return 0
end

function pfQuestLedger:GetAttunementDifficultyOrder(att)
  local id = att and att.id or nil
  local name = att and att.name or nil
  local category = att and att.category or nil
  local group = att and att.group or nil
  local explicitOrderById = {
    SWC = 100,
    KC_A = 110,
    KC_H = 110,
    MC = 200,
    ONY_A = 210,
    ONY_H = 210,
    BWL = 220,
    ES = 230,
    SC_A = 240,
    SC_H = 240,
    NAXX = 250,
    K40_A = 260,
    K40_H = 260,
  }
  local explicitOrderByName = {
    ["Stormwrought Castle"] = 100,
    ["Karazhan Crypts"] = 110,
    ["Molten Core"] = 200,
    ["Onyxia's Lair"] = 210,
    ["Blackwing Lair"] = 220,
    ["Emerald Sanctum"] = 230,
    ["Scarlet Crusade"] = 240,
    ["Naxxramas"] = 250,
    ["Karazhan 40"] = 260,
  }
  local categoryBias = 0
  local entryLevel = self:GetAttunementSortLevel(att)

  if id and explicitOrderById[id] then
    return explicitOrderById[id]
  end

  if name and explicitOrderByName[name] then
    return explicitOrderByName[name]
  end

  if group == "Dungeons" or category == "Soft Attunement" then
    categoryBias = 100
  elseif group == "Classic Raids" then
    categoryBias = 200
  elseif group == "Raids" then
    categoryBias = 230
  else
    categoryBias = 300
  end

  return categoryBias + (entryLevel or 0)
end

function pfQuestLedger:GetChainStatus(chain)
  if not chain then
    return "NOT_COMPLETED"
  end

  local done, total, _, active, available = self:GetAttunementProgress(chain)
  if total > 0 and done >= total then
    return "COMPLETED"
  elseif active > 0 or done > 0 then
    return "IN_PROGRESS"
  elseif available > 0 then
    return "AVAILABLE"
  elseif total > 0 then
    return "BLOCKED"
  end

  return "NOT_COMPLETED"
end

function pfQuestLedger:ChainMatchesStatus(chain)
  return self:MatchesFilterSet("chainStatus", self:GetChainStatus(chain))
end

function pfQuestLedger:GetVisibleChainList()
  local results = {}
  local search = self:GetSearchText("CHAINS")
  local i, chain, text
  for i = 1, table.getn(self.chains) do
    chain = self.chains[i]
    text = chain.name .. " " .. (chain.summary or "")
    if self:ChainMatchesStatus(chain) and self:Contains(text, search) then
      table.insert(results, chain)
    end
  end
  table.sort(results, function(a, b)
    local aorder = pfQuestLedger:GetAttunementDifficultyOrder(a)
    local border = pfQuestLedger:GetAttunementDifficultyOrder(b)
    if aorder ~= border then
      return aorder < border
    end
    if a.name ~= b.name then
      return a.name < b.name
    end
    return a.id < b.id
  end)
  return results
end

function pfQuestLedger:GetVisibleAttunementList()
  local results = {}
  local search = self:GetSearchText("ATTUNEMENTS")
  local i, att
  for i = 1, table.getn(self.attunements) do
    att = self.attunements[i]
    if self:IsSideVisible(att.side) and self:Contains(att.name .. " " .. (att.category or "") .. " " .. (att.group or ""), search) then
      table.insert(results, att)
    end
  end
  table.sort(results, function(a, b)
    local aorder = pfQuestLedger:GetAttunementDifficultyOrder(a)
    local border = pfQuestLedger:GetAttunementDifficultyOrder(b)
    if aorder ~= border then
      return aorder < border
    end
    if a.name ~= b.name then
      return a.name < b.name
    end
    return (a.side or "Both") < (b.side or "Both")
  end)
  return results
end

function pfQuestLedger:GetGuildMinLevel()
  local value = tonumber(pfQuestLedgerDB.profile.guildMinLevel) or 60
  value = math.floor(value)
  if value < 1 then value = 1 end
  if value > 60 then value = 60 end
  return value
end

function pfQuestLedger:SetGuildMinLevel(value)
  value = tonumber(value) or 60
  value = math.floor(value)
  if value < 1 then value = 1 end
  if value > 60 then value = 60 end
  pfQuestLedgerDB.profile.guildMinLevel = value
end

function pfQuestLedger:GetGuildAttunementCode(att)
  local code = string.upper((att and att.id) or "")
  if string.len(code) > 2 then
    local suffix = string.sub(code, -2)
    if suffix == "_A" or suffix == "_H" then
      code = string.sub(code, 1, string.len(code) - 2)
    end
  end
  return code
end

function pfQuestLedger:GetGuildAttunementAliases(att)
  local aliases = {}
  local seen = {}
  local canonical = self:GetGuildAttunementCode(att)
  local i, candidate, code, legacy

  if canonical ~= "" then
    table.insert(aliases, canonical)
    seen[canonical] = true
  end

  for i = 1, table.getn(self.attunements) do
    candidate = self.attunements[i]
    code = self:GetGuildAttunementCode(candidate)
    if code == canonical then
      legacy = string.upper(candidate.id or "")
      if legacy ~= "" and not seen[legacy] then
        table.insert(aliases, legacy)
        seen[legacy] = true
      end
    end
  end

  return aliases
end

function pfQuestLedger:GetBetterGuildAttunementState(current, candidate)
  local currentDone, currentTotal, candidateDone, candidateTotal
  local currentRatio, candidateRatio

  if not candidate then
    return current
  end
  if not current then
    return candidate
  end

  currentDone = tonumber(current.done) or 0
  currentTotal = tonumber(current.total) or 0
  candidateDone = tonumber(candidate.done) or 0
  candidateTotal = tonumber(candidate.total) or 0

  currentRatio = 0
  if currentTotal > 0 then
    currentRatio = currentDone / currentTotal
  end

  candidateRatio = 0
  if candidateTotal > 0 then
    candidateRatio = candidateDone / candidateTotal
  end

  if candidateRatio > currentRatio then
    return candidate
  end
  if candidateRatio < currentRatio then
    return current
  end
  if candidateDone > currentDone then
    return candidate
  end
  if candidateDone < currentDone then
    return current
  end
  if candidateTotal > currentTotal then
    return candidate
  end

  return current
end

function pfQuestLedger:GetGuildRecordAttunementState(record, att)
  local attunements = record and record.attunements or nil
  local aliases = self:GetGuildAttunementAliases(att)
  local bestState = nil
  local i, alias, state

  if not attunements then
    return nil
  end

  for i = 1, table.getn(aliases) do
    alias = aliases[i]
    state = attunements[alias]
    if state then
      bestState = self:GetBetterGuildAttunementState(bestState, state)
    end
  end

  return bestState
end

function pfQuestLedger:BuildLocalGuildRecord()
  local record = {
    class = nil,
    level = UnitLevel("player") or 0,
    faction = self:GetFactionLabel(),
    protocolVersion = self.guildProtocolVersion or 1,
    addonVersion = self.version or "?",
    sourceType = "local_state",
    attunements = {},
    reputations = {},
    updatedAt = time(),
    isSelf = true,
  }

  local _, class = UnitClass("player")
  local code, state
  record.class = class or "?"

  local i, att, done, total
  for i = 1, table.getn(self.attunements) do
    att = self.attunements[i]
    if self:IsSideVisible(att.side) then
      done, total = self:GetAttunementProgress(att)
      code = self:GetGuildAttunementCode(att)
      state = {
        done = done or 0,
        total = total or 0,
      }
      record.attunements[code] = self:GetBetterGuildAttunementState(record.attunements[code], state)
    end
  end

  local argentDawnStanding = self:GetReputationStandingByName("Argent Dawn")
  if argentDawnStanding then
    record.reputations.ARGENT_DAWN = argentDawnStanding
  end

  return record
end

function pfQuestLedger:GetVisibleGuildAttunements()
  local results = {}
  local lookup = {}
  local i, att, code

  for i = 1, table.getn(self.attunements) do
    att = self.attunements[i]
    code = self:GetGuildAttunementCode(att)
    if code ~= "" then
      if not lookup[code] then
        lookup[code] = att
      elseif self:IsSideVisible(att.side) and not self:IsSideVisible(lookup[code].side) then
        lookup[code] = att
      end
    end
  end

  for _, att in pairs(lookup) do
    table.insert(results, att)
  end

  table.sort(results, function(a, b)
    local aorder = pfQuestLedger:GetAttunementDifficultyOrder(a)
    local border = pfQuestLedger:GetAttunementDifficultyOrder(b)
    if aorder ~= border then
      return aorder < border
    end
    if a.name ~= b.name then
      return a.name < b.name
    end
    return pfQuestLedger:GetGuildAttunementCode(a) < pfQuestLedger:GetGuildAttunementCode(b)
  end)

  return results
end

function pfQuestLedger:GetVisibleGuildList()
  local results = {}
  local search = self:GetSearchText("GUILD")
  local minLevel = self:GetGuildMinLevel()
  local ownName = UnitName("player") or nil
  local name, record

  if ownName and self:Contains(ownName, search) then
    record = self:BuildLocalGuildRecord()
    if (record.level or 0) >= minLevel then
      table.insert(results, { name = ownName, data = record })
    end
  end

  for name, record in pairs(pfQuestLedgerDB.guild.members) do
    if name ~= ownName and self:Contains(name, search) and (record.level or 0) >= minLevel then
      table.insert(results, { name = name, data = record })
    end
  end

  table.sort(results, function(a, b)
    local aLevel = (a.data and a.data.level) or 0
    local bLevel = (b.data and b.data.level) or 0
    if aLevel ~= bLevel then
      return aLevel < bLevel
    end
    return a.name < b.name
  end)

  return results
end

function pfQuestLedger:GetManualState(attId, stepIndex)
  pfQuestLedgerDB.character.manual[attId] = pfQuestLedgerDB.character.manual[attId] or {}
  return pfQuestLedgerDB.character.manual[attId][stepIndex] and true or false
end

function pfQuestLedger:SetManualState(attId, stepIndex, value)
  pfQuestLedgerDB.character.manual[attId] = pfQuestLedgerDB.character.manual[attId] or {}
  pfQuestLedgerDB.character.manual[attId][stepIndex] = value and true or nil
end


function pfQuestLedger:GetReputationStandingByName(name)
  local total, i, fname, _, standingId, _, _, _, _, isHeader

  if not name or name == "" or not GetNumFactions or not GetFactionInfo then
    return nil
  end

  total = GetNumFactions()
  if not total then
    return nil
  end

  for i = 1, total do
    fname, _, standingId, _, _, _, _, _, isHeader = GetFactionInfo(i)
    if fname and not isHeader and self:Lower(fname) == self:Lower(name) then
      return tonumber(standingId) or nil
    end
  end

  return nil
end

function pfQuestLedger:GetRequiredReputationStanding(step)
  local label

  if not step then
    return nil
  end

  if step.requiredStanding then
    return tonumber(step.requiredStanding)
  end

  label = self:Lower(step.title or "")
  if string.find(label, "exalted", 1, true) then
    return 8
  elseif string.find(label, "revered", 1, true) then
    return 7
  elseif string.find(label, "honored", 1, true) then
    return 6
  elseif string.find(label, "friendly", 1, true) then
    return 5
  elseif string.find(label, "neutral", 1, true) then
    return 4
  end

  return nil
end

function pfQuestLedger:GetStepReputationName(step)
  local title

  if not step then
    return nil
  end

  if step.reputationName and step.reputationName ~= "" then
    return step.reputationName
  end

  title = step.title or ""
  title = string.gsub(title, "%s*%-%s*Honored.*$", "")
  title = string.gsub(title, "%s*%-%s*Revered.*$", "")
  title = string.gsub(title, "%s*%-%s*Exalted.*$", "")
  title = string.gsub(title, "%s*%-%s*Friendly.*$", "")
  title = string.gsub(title, "%s*%-%s*Neutral.*$", "")
  title = self:Trim(title)

  if title == "" then
    return nil
  end

  return title
end

function pfQuestLedger:GetStepReputationStanding(step)
  local repName = self:GetStepReputationName(step)
  if not repName then
    return nil
  end
  return self:GetReputationStandingByName(repName)
end

function pfQuestLedger:GetGuildRecordReputationStanding(record, step)
  local repKey, standing

  if not record or not record.reputations or not step then
    return nil
  end

  repKey = string.upper(string.gsub(self:GetStepReputationName(step) or "", "[^%w]", "_"))
  if repKey == "" then
    return nil
  end

  standing = record.reputations[repKey]
  if standing == nil then
    return nil
  end

  return tonumber(standing) or nil
end

function pfQuestLedger:GetGuildStateComparisonPayload()
  return self:SerializeGuildState(nil, true)
end

function pfQuestLedger:GetAutoGuildJitter()
  if self.autoGuildJitter == nil then
    self.autoGuildJitter = deterministicNameJitter(UnitName("player") or "player", self.guildAutoScheduleJitter or 300)
  end
  return self.autoGuildJitter
end

function pfQuestLedger:EnsureAutoGuildSchedule(forceReset)
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  local now

  if not character then
    return
  end

  now = time()

  if forceReset or not character.autoNextBroadcastAt or character.autoNextBroadcastAt < 1 then
    character.autoNextBroadcastAt = now + self:GetAutoGuildJitter()
  end

  if forceReset or not character.autoNextRequestAt or character.autoNextRequestAt < 1 then
    character.autoNextRequestAt = now + (self.guildAutoRequestOffset or (15 * 60)) + self:GetAutoGuildJitter()
  end
end

function pfQuestLedger:UpdatePublishedGuildState(payload, stamp)
  if not pfQuestLedgerDB or not pfQuestLedgerDB.character then
    return
  end

  payload = payload or self:GetGuildStateComparisonPayload()
  pfQuestLedgerDB.character.lastPublishedGuildState = payload or ""
  pfQuestLedgerDB.character.lastPublishedGuildStateAt = tonumber(stamp) or time()
  pfQuestLedgerDB.character.guildStateDirty = false
  pfQuestLedgerDB.character.guildStateDirtyAt = 0
end

function pfQuestLedger:IsGuildTrafficContextSafe()
  local inInstance, instanceType, i, status

  if not GetGuildInfo("player") then
    return false, "no_guild"
  end

  if UnitAffectingCombat and UnitAffectingCombat("player") then
    return false, "combat"
  end

  if IsInInstance then
    inInstance, instanceType = IsInInstance()
    if inInstance then
      return false, instanceType or "instance"
    end
  end

  if IsInRaid and IsInRaid() then
    return false, "raid"
  end

  if GetBattlefieldStatus then
    for i = 1, 3 do
      status = GetBattlefieldStatus(i)
      if status == "active" or status == "confirm" then
        return false, "battleground"
      end
    end
  end

  return true
end

function pfQuestLedger:MarkGuildStateDirty()
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  local payload, now, debounce

  if not character then
    return false
  end

  payload = self:GetGuildStateComparisonPayload()
  if payload == (character.lastPublishedGuildState or "") then
    character.guildStateDirty = false
    character.guildStateDirtyAt = 0
    return false
  end

  now = time()
  debounce = self.guildAutoDirtyDebounce or 60
  character.guildStateDirty = true
  character.guildStateDirtyAt = now
  character.autoNextBroadcastAt = now + debounce

  return true
end

function pfQuestLedger:ScheduleAutoBroadcast(delaySeconds)
  if not pfQuestLedgerDB or not pfQuestLedgerDB.character then
    return
  end

  delaySeconds = clampNumber(delaySeconds, 0, nil)
  pfQuestLedgerDB.character.autoNextBroadcastAt = time() + delaySeconds
end

function pfQuestLedger:ScheduleAutoRequest(delaySeconds)
  if not pfQuestLedgerDB or not pfQuestLedgerDB.character then
    return
  end

  delaySeconds = clampNumber(delaySeconds, 0, nil)
  pfQuestLedgerDB.character.autoNextRequestAt = time() + delaySeconds
end

function pfQuestLedger:PruneAutoRequestHistory(now)
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  local history, kept, i, stamp

  if not character then
    return 0
  end

  history = character.autoRequestHistory or {}
  kept = {}
  now = tonumber(now) or time()

  for i = 1, table.getn(history) do
    stamp = tonumber(history[i]) or 0
    if stamp > 0 and now - stamp < 3600 then
      table.insert(kept, stamp)
    end
  end

  character.autoRequestHistory = kept
  return table.getn(kept)
end

function pfQuestLedger:CanAutoRequestNow(now)
  local used, history, maxPerHour, oldest, waitSeconds
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil

  if not character then
    return false, self.guildAutoUnsafeRetry or (5 * 60)
  end

  now = tonumber(now) or time()
  maxPerHour = tonumber(self.guildAutoRequestMaxPerHour) or 2
  used = self:PruneAutoRequestHistory(now)
  if used < maxPerHour then
    return true, 0
  end

  history = character.autoRequestHistory or {}
  oldest = tonumber(history[1]) or 0
  if oldest <= 0 then
    return false, self.guildAutoUnsafeRetry or (5 * 60)
  end

  waitSeconds = (oldest + 3600) - now
  if waitSeconds < 60 then
    waitSeconds = 60
  end

  return false, waitSeconds
end

function pfQuestLedger:RecordAutoRequest(now)
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  if not character then
    return
  end

  now = tonumber(now) or time()
  self:PruneAutoRequestHistory(now)
  table.insert(character.autoRequestHistory, now)
end

function pfQuestLedger:GetGuildReplyJitter(target)
  return deterministicNameJitter((UnitName("player") or "player") .. ":" .. tostring(target or "?"), self.guildAutoReplyJitter or 10)
end

function pfQuestLedger:CanReplyGuildStateTo(target, payload, now)
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  local replyState, cooldown, waitSeconds

  if not character or not target or target == "" then
    return false, self.guildAutoUnsafeRetry or (5 * 60)
  end

  now = tonumber(now) or time()
  payload = payload or self:GetGuildStateComparisonPayload()
  cooldown = tonumber(self.guildAutoReplyCooldown) or (10 * 60)
  replyState = character.lastGuildReplyByTarget and character.lastGuildReplyByTarget[target] or nil

  if replyState and (replyState.payload or "") == payload and (tonumber(replyState.at) or 0) > 0 then
    waitSeconds = cooldown - (now - (tonumber(replyState.at) or 0))
    if waitSeconds > 0 then
      return false, waitSeconds
    end
  end

  return true, 0
end

function pfQuestLedger:RememberGuildReply(target, payload, now)
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  if not character or not target or target == "" then
    return
  end

  character.lastGuildReplyByTarget = character.lastGuildReplyByTarget or {}
  character.lastGuildReplyByTarget[target] = {
    at = tonumber(now) or time(),
    payload = payload or self:GetGuildStateComparisonPayload(),
  }
end

function pfQuestLedger:QueueGuildStateReply(target)
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  local payload, safe, reason, canReply, waitSeconds, dueAt, existingDueAt, now

  if not character or not target or target == "" then
    return false, "invalid_target"
  end

  now = time()
  payload = self:GetGuildStateComparisonPayload()
  canReply, waitSeconds = self:CanReplyGuildStateTo(target, payload, now)
  if not canReply then
    return false, "cooldown"
  end

  safe, reason = self:IsGuildTrafficContextSafe()
  if safe then
    dueAt = now + self:GetGuildReplyJitter(target)
  else
    dueAt = now + (self.guildAutoUnsafeRetry or (5 * 60))
  end

  character.pendingGuildReplies = character.pendingGuildReplies or {}
  existingDueAt = tonumber(character.pendingGuildReplies[target]) or 0
  if existingDueAt > 0 and existingDueAt <= dueAt then
    return true, safe and "already_queued" or reason
  end

  character.pendingGuildReplies[target] = dueAt
  self:AddDebugEvent("sync", "Queued guild reply for " .. tostring(target) .. " at " .. date("%H:%M:%S", dueAt) .. ".")
  return true, safe and "queued" or reason
end

function pfQuestLedger:ProcessPendingGuildReplies(now)
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  local safe, reason, payload, canReply, waitSeconds, pending, target, dueAt

  if not character or not character.pendingGuildReplies then
    return
  end

  now = tonumber(now) or time()
  pending = copyTableShallow(character.pendingGuildReplies)

  for target, dueAt in pairs(pending) do
    dueAt = tonumber(dueAt) or 0
    if dueAt > 0 and now >= dueAt then
      safe, reason = self:IsGuildTrafficContextSafe()
      if not safe then
        character.pendingGuildReplies[target] = now + (self.guildAutoUnsafeRetry or (5 * 60))
      else
        payload = self:GetGuildStateComparisonPayload()
        canReply, waitSeconds = self:CanReplyGuildStateTo(target, payload, now)
        if not canReply then
          character.pendingGuildReplies[target] = now + waitSeconds
        elseif self:SendGuildState(target, self:SerializeGuildState("reply"), "reply") then
          self:RememberGuildReply(target, payload, now)
          character.pendingGuildReplies[target] = nil
        else
          character.pendingGuildReplies[target] = now + (self.guildAutoUnsafeRetry or (5 * 60))
        end
      end
    end
  end
end

function pfQuestLedger:ShouldAutoRequestGuildState(now)
  local members = pfQuestLedgerDB and pfQuestLedgerDB.guild and pfQuestLedgerDB.guild.members or nil
  local staleAfter = self.guildAutoRequestStaleAfter or (45 * 60)
  local count = 0
  local oldest = now
  local _, record

  if not members then
    return true, "empty"
  end

  for _, record in pairs(members) do
    count = count + 1
    if record and record.updatedAt and record.updatedAt < oldest then
      oldest = record.updatedAt
    end
  end

  if count == 0 then
    return true, "empty"
  end

  if now - oldest >= staleAfter then
    return true, "stale"
  end

  return false, "fresh"
end

function pfQuestLedger:SendGuildState(target, payload, sourceType)
  payload = payload or self:SerializeGuildState(sourceType or (target and "reply" or "manual"))

  if not payload or payload == "" then
    return false
  end

  if target and target ~= "" then
    if string.len(self.prefix) + string.len(payload) > 254 then
      return false
    end
    SendAddonMessage(self.prefix, payload, "WHISPER", target)
    self:AddDebugEvent("sync", "Whispered guild state to " .. tostring(target) .. ".")
    return true
  end

  return self:BroadcastGuildState(false)
end

function pfQuestLedger:ProcessAutoBroadcast(now)
  local safe, reason, payload

  now = tonumber(now) or time()
  safe, reason = self:IsGuildTrafficContextSafe()
  if not safe then
    self:ScheduleAutoBroadcast(self.guildAutoUnsafeRetry or (5 * 60))
    return false, reason
  end

  payload = self:GetGuildStateComparisonPayload()
  if payload == (pfQuestLedgerDB.character.lastPublishedGuildState or "") then
    pfQuestLedgerDB.character.guildStateDirty = false
    self:ScheduleAutoBroadcast(self.guildAutoNoChangeDelay or (60 * 60))
    return false, "unchanged"
  end

  if self:BroadcastGuildState(false, "auto") then
    self:ScheduleAutoBroadcast(self.guildAutoBroadcastInterval or (30 * 60))
    return true, "broadcast"
  end

  self:ScheduleAutoBroadcast(self.guildAutoUnsafeRetry or (5 * 60))
  return false, "send_failed"
end

function pfQuestLedger:ProcessAutoRequest(now)
  local safe, reason, shouldRequest, canRequest, waitSeconds

  now = tonumber(now) or time()
  safe, reason = self:IsGuildTrafficContextSafe()
  if not safe then
    self:ScheduleAutoRequest(self.guildAutoUnsafeRetry or (5 * 60))
    return false, reason
  end

  shouldRequest, reason = self:ShouldAutoRequestGuildState(now)
  if not shouldRequest then
    self:ScheduleAutoRequest(self.guildAutoFreshRequestDelay or (60 * 60))
    return false, reason
  end

  canRequest, waitSeconds = self:CanAutoRequestNow(now)
  if not canRequest then
    self:ScheduleAutoRequest(waitSeconds)
    return false, "rate_limited"
  end

  if self:RequestGuildState() then
    pfQuestLedgerDB.character.lastAutoRequestAt = now
    self:RecordAutoRequest(now)
    self:ScheduleAutoRequest(self.guildAutoRequestInterval or (30 * 60))
    return true, "requested"
  end

  self:ScheduleAutoRequest(self.guildAutoUnsafeRetry or (5 * 60))
  return false, "send_failed"
end

function pfQuestLedger:ProcessAutoGuildTraffic()
  local character = pfQuestLedgerDB and pfQuestLedgerDB.character or nil
  local now = time()

  if not character then
    return
  end

  self:EnsureAutoGuildSchedule()
  self:ProcessPendingGuildReplies(now)

  if (character.autoNextBroadcastAt or 0) > 0 and now >= (character.autoNextBroadcastAt or 0) then
    self:ProcessAutoBroadcast(now)
  end

  if (character.autoNextRequestAt or 0) > 0 and now >= (character.autoNextRequestAt or 0) then
    self:ProcessAutoRequest(now)
  end
end

function pfQuestLedger:GetStepState(att, step, stepIndex)
  local kind = step.kind
  local qid
  local requiredLevel

  if kind == "level" then
    if UnitLevel and UnitLevel("player") >= (step.requiredLevel or att.level or 0) then
      return "DONE"
    end
    return "TODO"
  end

  if kind == "reputation" then
    local requiredStanding = self:GetRequiredReputationStanding(step)
    local standing = self:GetStepReputationStanding(step)

    if requiredStanding and standing then
      if standing >= requiredStanding then
        return "DONE"
      end
      return "TODO"
    end

    if self:GetManualState(att.id, stepIndex) then
      return "DONE"
    end

    return "UNKNOWN"
  end

  if kind == "start" then
    requiredLevel = step.requiredLevel or att.level or 0
    if requiredLevel > 0 and UnitLevel and UnitLevel("player") < requiredLevel then
      return "TODO"
    end

    qid = step.questId or step.resolvedQuestId
    if qid then
      if self:IsQuestCompleted(qid) or self:IsQuestActive(qid) then
        return "DONE"
      elseif self:IsQuestAvailable(qid) then
        return "AVAILABLE"
      end
      return "TODO"
    end

    if requiredLevel > 0 then
      return "DONE"
    end
    return "TODO"
  end

  if kind == "quest" or kind == "quest_pickup" or kind == "quest_objective" or kind == "quest_turnin" or kind == "attuned" then
    qid = step.questId or step.resolvedQuestId
    if not qid then
      return "UNKNOWN"
    elseif self:IsQuestCompleted(qid) then
      return "DONE"
    elseif kind == "quest_pickup" then
      if self:IsQuestActive(qid) then
        return "DONE"
      elseif self:IsQuestAvailable(qid) then
        return "AVAILABLE"
      end
    elseif kind == "quest_objective" or kind == "quest_turnin" then
      if self:IsQuestActive(qid) then
        return "ACTIVE"
      end
    else
      if self:IsQuestActive(qid) then
        return "ACTIVE"
      elseif self:IsQuestAvailable(qid) then
        return "AVAILABLE"
      end
    end
    return "TODO"
  end

  if self:GetManualState(att.id, stepIndex) then
    return "DONE"
  end
  return "TODO"
end

function pfQuestLedger:GetStepStateText(state)
  if state == "DONE" then
    return "Done"
  elseif state == "ACTIVE" then
    return "Active"
  elseif state == "AVAILABLE" then
    return "Available"
  elseif state == "UNKNOWN" then
    return "Unknown"
  end
  return "Todo"
end

function pfQuestLedger:GetStepColor(state)
  if state == "DONE" then
    return "|cff88cc88"
  elseif state == "ACTIVE" then
    return "|cff55aaff"
  elseif state == "AVAILABLE" then
    return "|cffffff55"
  elseif state == "UNKNOWN" then
    return "|cffaaaaaa"
  end
  return "|cffffffff"
end

function pfQuestLedger:GetAttunementProgress(att)
  local total, done, active, available = 0, 0, 0, 0
  local grouped = {}
  local i, step, state, group
  local rank = { UNKNOWN = 0, TODO = 1, AVAILABLE = 2, ACTIVE = 3, DONE = 4 }

  for i = 1, table.getn(att.steps) do
    step = att.steps[i]
    state = self:GetStepState(att, step, i)
    group = step.altGroup

    if group and group ~= "" then
      if not grouped[group] then
        grouped[group] = state
      elseif (rank[state] or 0) > (rank[grouped[group]] or 0) then
        grouped[group] = state
      end
    else
      total = total + 1
      if state == "DONE" then
        done = done + 1
      elseif state == "ACTIVE" then
        active = active + 1
      elseif state == "AVAILABLE" then
        available = available + 1
      end
    end
  end

  for _, groupedState in pairs(grouped) do
    total = total + 1
    if groupedState == "DONE" then
      done = done + 1
    elseif groupedState == "ACTIVE" then
      active = active + 1
    elseif groupedState == "AVAILABLE" then
      available = available + 1
    end
  end

  local status = "Pending"
  if total > 0 and done >= total then
    status = "Completed"
  elseif active > 0 then
    status = "In progress"
  elseif available > 0 then
    status = "Ready"
  elseif done > 0 then
    status = "Started"
  end

  return done, total, status, active, available
end

function pfQuestLedger:FormatShortAttunementState(att)
  local done, total = self:GetAttunementProgress(att)
  return string.lower(att.id) .. "=" .. done .. "/" .. total
end

function pfQuestLedger:BuildProgressBar(done, total, width)
  width = width or 18
  if total <= 0 then
    return "[" .. string.rep("-", width) .. "]"
  end
  local filled = math.floor((done / total) * width + 0.5)
  if filled < 0 then filled = 0 end
  if filled > width then filled = width end
  return "[" .. string.rep("=", filled) .. string.rep("-", width - filled) .. "]"
end

function pfQuestLedger:GetAttunementDisplayTexture(att)
  if att and att.icon and att.icon ~= "" then
    return att.icon
  end
  return "Interface\\Icons\\INV_Misc_Note_01"
end

function pfQuestLedger:GetAttunementArtworkTexture(att)
  if att and att.art and att.art ~= "" then
    return att.art
  end
  return nil
end

function pfQuestLedger:GetStepStatusColorRGB(state)
  if state == "DONE" then return 0.25, 0.80, 0.35 end
  if state == "ACTIVE" then return 0.95, 0.85, 0.25 end
  if state == "AVAILABLE" then return 0.45, 0.70, 1.00 end
  if state == "UNKNOWN" then return 0.48, 0.48, 0.48 end
  return 0.70, 0.25, 0.25
end

function pfQuestLedger:GetAttunementStepSubtitle(step, state, att)
  local suffix = step and step.locationSuffix or nil
  if step and step.subtitle and step.subtitle ~= "" then
    return step.subtitle
  end

  if step.kind == "level" then
    return "Required level"
  elseif step.kind == "start" then
    if step.requiredLevel and step.requiredLevel > 0 then
      return "Required minimum"
    end
    return step.subtitle or "Entry point"
  elseif step.kind == "quest_pickup" then
    return suffix and ("Pick Up in " .. suffix) or "Pick Up"
  elseif step.kind == "quest_objective" then
    return suffix and ("Item in " .. suffix) or "Objective"
  elseif step.kind == "quest_turnin" then
    return suffix and ("Turn In in " .. suffix) or "Turn In"
  elseif step.kind == "attuned" then
    return state == "DONE" and "Completed" or "Final state"
  elseif step.kind == "quest" then
    if state == "ACTIVE" then
      return "In progress"
    elseif state == "AVAILABLE" then
      return "Available"
    elseif att and att.group and att.group ~= "" then
      return att.group
    end
  end

  return step.note or ""
end

function pfQuestLedger:GetAttunementStepActionIcon(step)
  local source = string.lower((step and step.title or "") .. " " .. (step and step.note or ""))

  if step and step.icon and step.icon ~= "" then
    return step.icon
  elseif step and step.kind == "level" then
    return "Interface\\Icons\\Spell_Holy_MagicalSentry"
  elseif step and step.kind == "start" then
    return "Interface\\Icons\\Spell_Holy_MagicalSentry"
  elseif step and step.kind == "quest_pickup" then
    return "Interface\\Icons\\INV_Scroll_03"
  elseif step and step.kind == "quest_objective" then
    return "Interface\\Icons\\INV_Misc_Bag_10"
  elseif step and step.kind == "quest_turnin" then
    return "Interface\\Icons\\INV_Misc_Note_01"
  elseif step and step.kind == "attuned" then
    return step.completeIcon or "Interface\\Icons\\Spell_Fire_SelfDestruct"
  end

  if string.find(source, "kill") or string.find(source, "slay") or string.find(source, "defeat") then
    return "Interface\\Icons\\INV_Sword_04"
  elseif string.find(source, "collect") or string.find(source, "gather") or string.find(source, "recover") or string.find(source, "retrieve") or string.find(source, "loot") then
    return "Interface\\Icons\\INV_Misc_Bag_10"
  elseif string.find(source, "wait") or string.find(source, "listen") then
    return "Interface\\Icons\\INV_Misc_PocketWatch_01"
  elseif string.find(source, "ask") or string.find(source, "consult") or string.find(source, "return") or string.find(source, "bring") or string.find(source, "speak") or string.find(source, "talk") or string.find(source, "report") then
    return "Interface\\Icons\\INV_Misc_Note_01"
  elseif string.find(source, "enter") or string.find(source, "travel") or string.find(source, "find") or string.find(source, "rendezvous") or string.find(source, "village") or string.find(source, "theramore") or string.find(source, "undercity") or string.find(source, "dalaran") or string.find(source, "coast") then
    return "Interface\\Icons\\Ability_Rogue_Sprint"
  elseif string.find(source, "key") then
    return "Interface\\Icons\\INV_Misc_Key_03"
  end

  return "Interface\\Icons\\INV_Scroll_03"
end

function pfQuestLedger:GetAttunementStepFollows(step)
  local follows = {}
  local value

  if not step or not step.follows then
    return follows
  end

  if type(step.follows) == "table" then
    local i
    for i = 1, table.getn(step.follows) do
      value = tonumber(step.follows[i])
      if value and value > 0 then
        table.insert(follows, value)
      end
    end
    return follows
  end

  local text = tostring(step.follows)
  text = string.gsub(text, "|", "&")
  text = string.gsub(text, ",", "&")
  for value in string.gmatch(text, "[^&%s]+") do
    value = tonumber(value)
    if value and value > 0 then
      table.insert(follows, value)
    end
  end

  return follows
end

function pfQuestLedger:GetAttunementGraphLayout(att)
  if not att then return nil end
  if att._graphLayoutCache then
    return att._graphLayoutCache
  end

  local stages = {}
  local stageOrder = {}
  local maxRows = 0
  local i, step, stage, nodes

  for i = 1, table.getn(att.steps) do
    step = att.steps[i]
    stage = tonumber(step.stage) or i
    if not stages[stage] then
      stages[stage] = {}
      table.insert(stageOrder, stage)
    end
    table.insert(stages[stage], i)
  end

  table.sort(stageOrder, function(a, b) return a < b end)

  local orderedStages = {}
  local sIndex
  for sIndex = 1, table.getn(stageOrder) do
    stage = stageOrder[sIndex]
    nodes = stages[stage]
    table.sort(nodes, function(a, b)
      local sa = att.steps[a]
      local sb = att.steps[b]
      local ao = tonumber(sa.order) or tonumber(sa.stageOrder) or a
      local bo = tonumber(sb.order) or tonumber(sb.stageOrder) or b
      if ao == bo then
        return a < b
      end
      return ao < bo
    end)
    orderedStages[sIndex] = { id = stage, steps = nodes }
    if table.getn(nodes) > maxRows then
      maxRows = table.getn(nodes)
    end
  end

  local connections = {}
  local follows, j, prev
  for i = 1, table.getn(att.steps) do
    step = att.steps[i]
    follows = self:GetAttunementStepFollows(step)
    if table.getn(follows) < 1 and i > 1 then
      table.insert(follows, i - 1)
    end
    for j = 1, table.getn(follows) do
      prev = follows[j]
      if att.steps[prev] then
        table.insert(connections, { from = prev, to = i })
      end
    end
  end

  att._graphLayoutCache = {
    stages = orderedStages,
    connections = connections,
    maxRows = maxRows,
  }

  return att._graphLayoutCache
end

function pfQuestLedger:GetAttunementGraphLineColor(fromState, toState)
  if fromState == "DONE" and toState == "DONE" then
    return 0.388, 0.686, 0.388, 1
  end
  if fromState == "DONE" and (toState == "ACTIVE" or toState == "AVAILABLE") then
    return 0.851, 0.608, 0.0, 1
  end
  if toState == "DONE" then
    return 0.388, 0.686, 0.388, 1
  end
  return 0.2, 0.2, 0.2, 1
end

function pfQuestLedger:ResetAttunementGraphLines()
  if not self.frame or not self.frame.attGraphLines then return end
  self.frame.attGraphLineCursor = 1
  local i
  for i = 1, table.getn(self.frame.attGraphLines) do
    self.frame.attGraphLines[i]:Hide()
  end
end

function pfQuestLedger:AcquireAttunementGraphLine()
  if not self.frame or not self.frame.attGraphContent then return nil end

  self.frame.attGraphLines = self.frame.attGraphLines or {}
  self.frame.attGraphLineCursor = self.frame.attGraphLineCursor or 1

  local line = self.frame.attGraphLines[self.frame.attGraphLineCursor]
  if not line then
    line = self.frame.attGraphContent:CreateTexture(nil, "BORDER")
    line:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    self.frame.attGraphLines[self.frame.attGraphLineCursor] = line
  end

  self.frame.attGraphLineCursor = self.frame.attGraphLineCursor + 1
  return line
end

function pfQuestLedger:PositionAttunementGraphLine(line, x, y, width, height, r, g, b, a)
  if not line or not self.frame or not self.frame.attGraphContent then return end
  if width < 1 then width = 1 end
  if height < 1 then height = 1 end

  line:ClearAllPoints()
  line:SetPoint("TOPLEFT", self.frame.attGraphContent, "TOPLEFT", x, -y)
  line:SetWidth(width)
  line:SetHeight(height)
  line:SetVertexColor(r or 0.2, g or 0.2, b or 0.2, a or 1)
  line:Show()
end

function pfQuestLedger:SetAttunementGraphScrollValue(value)
  if not self.frame or not self.frame.attGraphViewport or not self.frame.attGraphContent then
    return
  end

  local viewportWidth = self.frame.attGraphViewport:GetWidth() or 0
  local viewportHeight = self.frame.attGraphViewport:GetHeight() or 0
  if viewportWidth < 1 then viewportWidth = 884 end
  if viewportHeight < 1 then viewportHeight = 300 end

  value = math.floor(value or 0)
  if value < 0 then value = 0 end

  if self.frame.attGraphCanvas then
    self.frame.attGraphCanvas:SetWidth(viewportWidth)
    self.frame.attGraphCanvas:SetHeight(math.max(viewportHeight, self.frame.attGraphContent:GetHeight() or 0))
  end

  self.frame.attGraphContent:ClearAllPoints()
  self.frame.attGraphContent:SetPoint("TOPLEFT", self.frame.attGraphCanvas or self.frame.attGraphScroll, "TOPLEFT", -value, 0)

  if self.frame.attGraphScroll then
    if self.frame.attGraphScroll.SetHorizontalScroll then
      self.frame.attGraphScroll:SetHorizontalScroll(0)
    end
    if self.frame.attGraphScroll.SetVerticalScroll then
      self.frame.attGraphScroll:SetVerticalScroll(0)
    end
  end
end

function pfQuestLedger:UpdateAttunementGraphScroll(contentWidth, contentHeight)
  if not self.frame or not self.frame.attGraphViewport or not self.frame.attGraphScroll or not self.frame.attGraphSlider then
    return
  end

  local viewportWidth = self.frame.attGraphViewport:GetWidth() or 0
  local viewportHeight = self.frame.attGraphViewport:GetHeight() or 0
  if viewportWidth < 1 then viewportWidth = 884 end
  if viewportHeight < 1 then viewportHeight = 300 end

  local maxScroll = math.max(0, math.floor((contentWidth or 0) - viewportWidth))
  local value = self.frame.attGraphSlider:GetValue() or 0
  if value < 0 then value = 0 end
  if value > maxScroll then
    value = maxScroll
  end

  if self.frame.attGraphCanvas then
    self.frame.attGraphCanvas:SetWidth(viewportWidth)
    self.frame.attGraphCanvas:SetHeight(math.max(viewportHeight, contentHeight or 0))
  end

  self.frame.attGraphSlider:SetMinMaxValues(0, maxScroll)
  self.frame.attGraphSlider:SetValueStep(1)
  self.frame.attGraphSlider:SetValue(value)
  self:SetAttunementGraphScrollValue(value)

  if maxScroll > 0 then
    self.frame.attGraphSlider:Show()
  else
    self.frame.attGraphSlider:Hide()
  end
end

function pfQuestLedger:BeginAttunementGraphDrag()
  if not self.frame or not self.frame.attGraphViewport or not self.frame.attGraphSlider then
    return
  end

  local slider = self.frame.attGraphSlider
  if not slider:IsShown() then
    return
  end

  local cursorX = 0
  if GetCursorPosition then
    cursorX = GetCursorPosition() or 0
  end

  local scale = nil
  if self.frame.attGraphViewport.GetEffectiveScale then
    scale = self.frame.attGraphViewport:GetEffectiveScale()
  end
  if (not scale or scale == 0) and UIParent and UIParent.GetEffectiveScale then
    scale = UIParent:GetEffectiveScale()
  end
  if scale and scale > 0 then
    cursorX = cursorX / scale
  end

  self.attGraphDrag = {
    active = true,
    startCursorX = cursorX,
    startValue = slider:GetValue() or 0,
  }

  if self.frame.StopMovingOrSizing then
    self.frame:StopMovingOrSizing()
  end

  self.frame.attGraphViewport:SetScript("OnUpdate", function()
    if pfQuestLedger then
      pfQuestLedger:UpdateAttunementGraphDrag()
    end
  end)
end

function pfQuestLedger:UpdateAttunementGraphDrag()
  if not self.attGraphDrag or not self.attGraphDrag.active or not self.frame or not self.frame.attGraphSlider then
    return
  end

  local slider = self.frame.attGraphSlider
  if not slider:IsShown() then
    self:EndAttunementGraphDrag()
    return
  end

  local cursorX = 0
  if GetCursorPosition then
    cursorX = GetCursorPosition() or 0
  end

  local scale = nil
  if self.frame.attGraphViewport and self.frame.attGraphViewport.GetEffectiveScale then
    scale = self.frame.attGraphViewport:GetEffectiveScale()
  end
  if (not scale or scale == 0) and UIParent and UIParent.GetEffectiveScale then
    scale = UIParent:GetEffectiveScale()
  end
  if scale and scale > 0 then
    cursorX = cursorX / scale
  end

  local deltaX = cursorX - (self.attGraphDrag.startCursorX or 0)
  local minValue, maxValue = slider:GetMinMaxValues()
  local newValue = (self.attGraphDrag.startValue or 0) - deltaX
  if newValue < minValue then newValue = minValue end
  if newValue > maxValue then newValue = maxValue end
  slider:SetValue(newValue)
end

function pfQuestLedger:EndAttunementGraphDrag()
  if self.frame and self.frame.attGraphViewport then
    self.frame.attGraphViewport:SetScript("OnUpdate", nil)
  end
  self.attGraphDrag = nil
end

function pfQuestLedger:GetAttunementLogicalStepMap(att)
  if att._logicalStepMap then
    return att._logicalStepMap.stepToLogical, att._logicalStepMap.logicalToStep, att._logicalStepMap.total
  end

  local stepToLogical = {}
  local logicalToStep = {}
  local grouped = {}
  local logical = 0
  local i, step, group
  for i = 1, table.getn(att.steps) do
    step = att.steps[i]
    group = step.altGroup
    if group and group ~= "" then
      if not grouped[group] then
        logical = logical + 1
        grouped[group] = logical
        logicalToStep[logical] = i
      end
      stepToLogical[i] = grouped[group]
    else
      logical = logical + 1
      stepToLogical[i] = logical
      logicalToStep[logical] = i
    end
  end

  att._logicalStepMap = { stepToLogical = stepToLogical, logicalToStep = logicalToStep, total = logical }
  return stepToLogical, logicalToStep, logical
end

function pfQuestLedger:IsRepresentativeAttunementStep(att, stepIndex)
  local stepToLogical, logicalToStep = self:GetAttunementLogicalStepMap(att)
  return logicalToStep[stepToLogical[stepIndex]] == stepIndex
end

function pfQuestLedger:GetGuildMemberAttunementStepIndex(att, memberState, record)
  local _, logicalToStep, total = self:GetAttunementLogicalStepMap(att)
  local done = tonumber(memberState and memberState.done) or 0
  local memberTotal = tonumber(memberState and memberState.total) or total
  local currentIndex, step, requiredLevel, requiredStanding, standing

  if not memberState or total < 1 then
    return nil
  end

  if memberTotal > 0 and memberTotal ~= total then
    done = math.floor(((done / memberTotal) * total) + 0.0001)
  end

  if done < 0 then done = 0 end
  if done >= total then
    currentIndex = logicalToStep[total]
  else
    currentIndex = logicalToStep[done + 1]
  end

  if not currentIndex then
    return nil
  end

  step = att and att.steps and att.steps[currentIndex] or nil
  if step and step.kind == "level" then
    requiredLevel = tonumber(step.requiredLevel or att.level) or 0
    if requiredLevel > 0 and record and (tonumber(record.level) or 0) < requiredLevel then
      return nil
    end
  elseif step and step.kind == "reputation" then
    requiredStanding = self:GetRequiredReputationStanding(step)
    standing = self:GetGuildRecordReputationStanding(record, step)
    if requiredStanding and standing and standing < requiredStanding then
      return nil
    end
  end

  return currentIndex
end

function pfQuestLedger:GetGuildNamesForAttunementStep(att, stepIndex)
  local names = {}
  local members = pfQuestLedgerDB and pfQuestLedgerDB.guild and pfQuestLedgerDB.guild.members or nil
  local selfName = UnitName("player") or ""
  local name, record, state, currentIndex, stepCount, isEndpoint, allowCrossFaction
  if not self:IsRepresentativeAttunementStep(att, stepIndex) then
    return names, 0
  end
  if not members then
    return names, 0
  end

  stepCount = att and att.steps and table.getn(att.steps) or 0
  isEndpoint = (stepIndex == 1) or (stepIndex == stepCount)

  for name, record in pairs(members) do
    if name ~= selfName then
      allowCrossFaction = true
      if att and att.side and att.side ~= "Both" and record and record.faction and record.faction ~= att.side then
        allowCrossFaction = isEndpoint
      end
      if allowCrossFaction then
        state = self:GetGuildRecordAttunementState(record, att)
        currentIndex = self:GetGuildMemberAttunementStepIndex(att, state, record)
        if currentIndex == stepIndex then
          table.insert(names, name)
        end
      end
    end
  end

  table.sort(names)
  return names, table.getn(names)
end
function pfQuestLedger:EnsureAttunementRosterTooltip()
  if not self.frame or self.frame.attRosterTooltip then return end

  local tip = CreateFrame("Frame", nil, UIParent)
  tip:SetFrameStrata("TOOLTIP")
  tip:SetToplevel(true)
  tip:Hide()
  tip:SetWidth(180)
  tip:SetHeight(56)
  if tip.SetBackdrop then
    tip:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    tip:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
    tip:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)
  end

  tip.header = tip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  tip.header:SetPoint("TOPLEFT", tip, "TOPLEFT", 12, -10)
  tip.header:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -12, -10)
  if tip.header.SetJustifyH then tip.header:SetJustifyH("LEFT") end
  tip.header:SetTextColor(0.20, 1.00, 0.35)
  tip.header:SetText("Guild members on this step")

  tip.divider = tip:CreateTexture(nil, "ARTWORK")
  tip.divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  tip.divider:SetVertexColor(0.35, 0.35, 0.35, 1)
  tip.divider:SetPoint("TOPLEFT", tip, "TOPLEFT", 10, -24)
  tip.divider:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -10, -24)
  tip.divider:SetHeight(1)

  tip.rows = {}
  local i, left, right
  for i = 1, 16 do
    left = tip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    left:SetPoint("TOPLEFT", tip, "TOPLEFT", 12, -32 - ((i - 1) * 12))
    if left.SetJustifyH then left:SetJustifyH("LEFT") end

    right = tip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    right:SetPoint("TOPLEFT", tip, "TOPLEFT", 118, -32 - ((i - 1) * 12))
    if right.SetJustifyH then right:SetJustifyH("LEFT") end

    tip.rows[i] = { left = left, right = right }
  end

  self.frame.attRosterTooltip = tip
end

function pfQuestLedger:ShowAttunementRosterTooltip(owner)
  if not owner or not owner.guildNames or table.getn(owner.guildNames) == 0 then return end
  self:EnsureAttunementRosterTooltip()

  local tip = self.frame.attRosterTooltip
  local names = owner.guildNames
  local columns = (table.getn(names) > 8) and 2 or 1
  local rows = math.ceil(table.getn(names) / columns)
  local i, row, rightIndex
  local width = columns == 2 and 228 or 130
  local minWidth = math.ceil((tip.header:GetStringWidth() or 0) + 24)
  if width < minWidth then width = minWidth end
  local height = (rows * 12) + 44

  for i = 1, table.getn(tip.rows) do
    row = tip.rows[i]
    row.left:SetText("")
    row.right:SetText("")
  end

  for i = 1, rows do
    row = tip.rows[i]
    row.left:SetText(names[i] or "")
    if columns == 2 then
      rightIndex = i + rows
      row.right:SetText(names[rightIndex] or "")
    end
  end

  tip:SetWidth(width)
  tip:SetHeight(height)
  tip:ClearAllPoints()
  if owner.tooltipAbove then
    tip:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 6)
  else
    tip:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -6)
  end
  tip:Show()
end

function pfQuestLedger:HideAttunementGraphTooltip()
  if self.frame and self.frame.attRosterTooltip then
    self.frame.attRosterTooltip:Hide()
  end
  GameTooltip:Hide()
end

function pfQuestLedger:ShowAttunementGraphTooltip(owner)
  if not owner or not owner.step then return end

  GameTooltip:SetOwner(owner, owner.tooltipAbove and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_TOPRIGHT")
  GameTooltip:SetText(owner.step.title or ("Step " .. (owner.stepIndex or 0)), 1, 0.82, 0)
  if owner.subtitle and owner.subtitle ~= "" then
    GameTooltip:AddLine(owner.subtitle, 0.95, 0.95, 0.25)
  end
  GameTooltip:AddLine(self:GetStepStateText(owner.state or "TODO"), 0.85, 0.85, 0.85)
  if owner.step.kind == "level" then
    GameTooltip:AddLine("Requires level " .. (owner.step.requiredLevel or owner.owner.level or 0), 0.80, 0.80, 0.80)
  elseif owner.questId then
    GameTooltip:AddLine("Quest ID: " .. owner.questId, 0.80, 0.80, 0.80)
    GameTooltip:AddLine("Left click to open this quest in the Quests tab.", 0.75, 0.75, 0.75)
  end
  if owner.step.note and owner.step.note ~= "" then
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine(owner.step.note, 0.72, 0.72, 0.72, 1)
  end
  GameTooltip:Show()
  if owner.guildCount and owner.guildCount > 0 then
    self:ShowAttunementRosterTooltip(owner)
  end
end

function pfQuestLedger:EnsureAttunementGraphWidgets()
  if not self.frame or not self.frame.attStepNodes or self.frame.attGraphWidgetsReady then return end

  self:EnsureAttunementRosterTooltip()

  local i, node, statusBar, indexLabel, badge, badgeIcon, badgeText, connectorV
  for i = 1, table.getn(self.frame.attStepNodes) do
    node = self.frame.attStepNodes[i]
    node:SetWidth(170)
    node:SetHeight(48)
    if node.SetBackdrop then
      node:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
      })
    end

    if not node.stepBg then
      node.stepBg = node:CreateTexture(nil, "BACKGROUND")
      node.stepBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
      node.stepBg:SetAllPoints(node)
    end
    node.stepBg:SetVertexColor(0, 0, 0, 0)

    if node.leftIcon then
      node.leftIcon:ClearAllPoints()
      node.leftIcon:SetPoint("TOPLEFT", node, "TOPLEFT", 8, -8)
      node.leftIcon:SetWidth(32)
      node.leftIcon:SetHeight(32)
    end

    if node.label then
      node.label:ClearAllPoints()
      node.label:SetPoint("TOPLEFT", node, "TOPLEFT", 44, -8)
      node.label:SetPoint("TOPRIGHT", node, "TOPRIGHT", -8, -8)
      if node.label.SetJustifyH then node.label:SetJustifyH("LEFT") end
      if node.label.SetJustifyV then node.label:SetJustifyV("TOP") end
    end

    if not node.subLabel then
      node.subLabel = node:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    end
    node.subLabel:ClearAllPoints()
    node.subLabel:SetPoint("TOPLEFT", node, "TOPLEFT", 44, -24)
    node.subLabel:SetPoint("TOPRIGHT", node, "TOPRIGHT", -8, -24)
    if node.subLabel.SetJustifyH then node.subLabel:SetJustifyH("LEFT") end
    if node.subLabel.SetJustifyV then node.subLabel:SetJustifyV("TOP") end

    statusBar = node:CreateTexture(nil, "BORDER")
    statusBar:SetWidth(1)
    statusBar:SetPoint("TOPLEFT", node, "TOPLEFT", 0, 0)
    statusBar:SetPoint("BOTTOMLEFT", node, "BOTTOMLEFT", 0, 0)
    statusBar:Hide()
    node.statusBar = statusBar

    indexLabel = node:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    indexLabel:SetPoint("TOPRIGHT", node, "TOPRIGHT", -6, -5)
    indexLabel:Hide()
    node.indexLabel = indexLabel

    connectorV = node:CreateTexture(nil, "BORDER")
    connectorV:SetWidth(2)
    connectorV:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    connectorV:SetVertexColor(0.75, 0.75, 0.75, 1)
    connectorV:Hide()
    node.connectorV = connectorV
    node.connectorH = node.connector
    if node.connectorH then
      node.connectorH:SetHeight(2)
      node.connectorH:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
      node.connectorH:SetVertexColor(0.75, 0.75, 0.75, 1)
      node.connectorH:Hide()
    end

    badge = CreateFrame("Button", nil, node)
    badge:SetWidth(20)
    badge:SetHeight(26)
    badge:EnableMouse(true)
    badge:RegisterForDrag("LeftButton")
    badge.ownerNode = node
    badge:SetScript("OnEnter", function()
      pfQuestLedger:ShowAttunementGraphTooltip(this.ownerNode)
    end)
    badge:SetScript("OnLeave", function()
      pfQuestLedger:HideAttunementGraphTooltip()
    end)
    badge:SetScript("OnDragStart", function()
      if pfQuestLedger and pfQuestLedger.BeginAttunementGraphDrag then
        pfQuestLedger:BeginAttunementGraphDrag()
      end
    end)
    badge:SetScript("OnDragStop", function()
      if pfQuestLedger and pfQuestLedger.EndAttunementGraphDrag then
        pfQuestLedger:EndAttunementGraphDrag()
      end
    end)
    node.countBadge = badge

    badgeIcon = badge:CreateTexture(nil, "ARTWORK")
    badgeIcon:SetTexture("Interface\\AddOns\\pfQuestLedger\\assets\\guildmates_badge.tga")
    badgeIcon:SetWidth(20)
    badgeIcon:SetHeight(16)
    badgeIcon:SetPoint("BOTTOM", badge, "BOTTOM", 0, 0)
    node.countIcon = badgeIcon

    badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badgeText:SetPoint("BOTTOM", badgeIcon, "TOP", 0, -1)
    node.countText = badgeText

    node:RegisterForDrag("LeftButton")
    node:SetScript("OnDragStart", function()
      if pfQuestLedger and pfQuestLedger.BeginAttunementGraphDrag then
        pfQuestLedger:BeginAttunementGraphDrag()
      end
    end)
    node:SetScript("OnDragStop", function()
      if pfQuestLedger and pfQuestLedger.EndAttunementGraphDrag then
        pfQuestLedger:EndAttunementGraphDrag()
      end
    end)
    node:SetScript("OnClick", function(arg1)
      pfQuestLedger:HandleDetailLinkClick(this, arg1)
    end)
    node:SetScript("OnEnter", function()
      pfQuestLedger:ShowAttunementGraphTooltip(this)
    end)
    node:SetScript("OnLeave", function()
      pfQuestLedger:HideAttunementGraphTooltip()
    end)
  end

  self.frame.attGraphWidgetsReady = true
end

function pfQuestLedger:SelectAttunementCard(listKey)
  self.selection.ATTUNEMENTS = listKey
  if pfQuestLedgerDB and pfQuestLedgerDB.profile and pfQuestLedgerDB.profile.page then
    pfQuestLedgerDB.profile.page.ATTUNEMENTS = 1
  end
  self:Refresh()
end

function pfQuestLedger:BackToAttunementGrid()
  self.selection.ATTUNEMENTS = nil
  self:Refresh()
end

function pfQuestLedger:GetAttunementCardLabel(att)
  local done, total, summary = self:GetAttunementProgress(att)
  return self:GetStatusColor(self:GetChainStatus(att)) .. summary .. "|r  |cffaaaaaa" .. done .. "/" .. total .. "|r"
end

function pfQuestLedger:RefreshAttunementCards(items)
  if not self.frame or not self.frame.attBackdrop then return end
  local cards = self.frame.attCards or {}
  local i, card, att, done, total
  for i = 1, table.getn(cards) do
    card = cards[i]
    att = items and items[i] or nil
    if att then
      card.att = att
      card.icon:SetTexture(self:GetAttunementDisplayTexture(att))
      card.title:SetText(att.name)
      card.sub:SetText(self:GetAttunementCardLabel(att))
      done, total = self:GetAttunementProgress(att)
      card.level:SetText("")
      card.side:SetText((att.side and att.side ~= "Both") and att.side or "")
      card:Show()
    else
      card.att = nil
      card:Hide()
    end
  end
end

function pfQuestLedger:RefreshAttunementPanel()
  if not self.frame or not self.frame.attBackdrop then return end

  local att = self:FindAttunementByListKey(self.selection.ATTUNEMENTS)
  local grid = self.frame.attGridView
  local detail = self.frame.attDetailView
  if not att then
    if self.frame.attDetailArt then
      self.frame.attDetailArt:Hide()
    end
    self:HideAttunementGraphTooltip()
    if self.frame.attGraphSlider then
      self.frame.attGraphSlider:Hide()
      self.frame.attGraphSlider:SetValue(0)
    end
    self:SetAttunementGraphScrollValue(0)
    self:ResetAttunementGraphLines()
    grid:Show()
    detail:Hide()
    return
  end

  self:EnsureAttunementGraphWidgets()
  grid:Hide()
  detail:Show()
  self.frame.attDetailTitle:SetText(att.name)
  self.frame.attDetailIcon:SetTexture(self:GetAttunementDisplayTexture(att))
  if self.frame.attDetailArt then
    self.frame.attDetailArt:Hide()
  end

  local done, total, summary = self:GetAttunementProgress(att)
  self.frame.attDetailMeta:SetText((att.category or "") .. "  -  " .. (att.group or ""))
  self.frame.attDetailSummary:SetText(done .. "/" .. total .. " - " .. summary)

  local graphViewport = self.frame.attGraphViewport
  local graphScroll = self.frame.attGraphScroll
  local graphContent = self.frame.attGraphContent
  local nodes = self.frame.attStepNodes or {}
  local layout = self:GetAttunementGraphLayout(att) or { stages = {}, connections = {}, maxRows = 1 }
  local stages = layout.stages or {}
  local positions = {}
  local viewportWidth = graphViewport and graphViewport:GetWidth() or 0
  local viewportHeight = graphViewport and graphViewport:GetHeight() or 0
  if viewportWidth < 1 then viewportWidth = 884 end
  if viewportHeight < 1 then viewportHeight = 300 end

  local nodeWidth = 170
  local nodeHeight = 48
  local stagePitch = 178
  local leftPadding = 20
  local rightPadding = 28
  local topPadding = 16
  local bottomPadding = 16
  local maxRows = math.max(1, layout.maxRows or 1)
  local availableHeight = viewportHeight - topPadding - bottomPadding
  local rowGap = 0
  if maxRows > 1 then
    rowGap = math.floor((availableHeight - (maxRows * nodeHeight)) / (maxRows - 1))
    if rowGap < 16 then rowGap = 16 end
    if rowGap > 40 then rowGap = 40 end
  end

  local stageIndex, stageInfo, count, columnHeight, startY, rowIndex, stepIndex
  local contentHeight = viewportHeight
  for stageIndex = 1, table.getn(stages) do
    stageInfo = stages[stageIndex]
    count = table.getn(stageInfo.steps)
    columnHeight = (count * nodeHeight) + (math.max(0, count - 1) * rowGap)
    startY = topPadding + math.floor((availableHeight - columnHeight) / 2)
    if startY < topPadding then
      startY = topPadding
    end

    for rowIndex = 1, count do
      stepIndex = stageInfo.steps[rowIndex]
      positions[stepIndex] = {
        x = leftPadding + ((stageIndex - 1) * stagePitch),
        y = startY + ((rowIndex - 1) * (nodeHeight + rowGap)),
      }
    end

    if (startY + columnHeight + bottomPadding) > contentHeight then
      contentHeight = startY + columnHeight + bottomPadding
    end
  end

  local contentWidth = leftPadding + (math.max(0, table.getn(stages) - 1) * stagePitch) + nodeWidth + rightPadding
  if contentWidth < viewportWidth then contentWidth = viewportWidth end
  if contentHeight < viewportHeight then contentHeight = viewportHeight end
  graphContent:SetWidth(contentWidth)
  graphContent:SetHeight(contentHeight)

  if self.frame.attLastGraphKey ~= att._listKey then
    self.frame.attLastGraphKey = att._listKey
    if self.frame.attGraphSlider then
      self.frame.attGraphSlider:SetValue(0)
    end
    self:SetAttunementGraphScrollValue(0)
  end

  self:ResetAttunementGraphLines()
  local thickness = 4
  local edgeIndex, edge, fromPos, toPos, fromState, toState, r, g, b, a
  local startX, endX, startMidY, endMidY, midX, topY
  for edgeIndex = 1, table.getn(layout.connections) do
    edge = layout.connections[edgeIndex]
    fromPos = positions[edge.from]
    toPos = positions[edge.to]
    if fromPos and toPos then
      fromState = self:GetStepState(att, att.steps[edge.from], edge.from)
      toState = self:GetStepState(att, att.steps[edge.to], edge.to)
      r, g, b, a = self:GetAttunementGraphLineColor(fromState, toState)

      startX = fromPos.x + nodeWidth
      endX = toPos.x
      startMidY = fromPos.y + math.floor(nodeHeight / 2)
      endMidY = toPos.y + math.floor(nodeHeight / 2)
      midX = startX + math.floor((endX - startX) / 2)
      if midX < (startX + 12) then midX = startX + 12 end
      if midX > (endX - 12) then midX = endX - 12 end

      self:PositionAttunementGraphLine(self:AcquireAttunementGraphLine(), startX, startMidY - math.floor(thickness / 2), midX - startX, thickness, r, g, b, a)

      if endMidY >= startMidY then
        topY = startMidY
      else
        topY = endMidY
      end
      self:PositionAttunementGraphLine(self:AcquireAttunementGraphLine(), midX - math.floor(thickness / 2), topY, thickness, math.abs(endMidY - startMidY), r, g, b, a)
      self:PositionAttunementGraphLine(self:AcquireAttunementGraphLine(), midX, endMidY - math.floor(thickness / 2), endX - midX, thickness, r, g, b, a)
    end
  end

  local i, node, step, state, questId, pos, badgeCount, names, subtitle
  local bgR, bgG, bgB, borderR, borderG, borderB, alpha
  for i = 1, table.getn(nodes) do
    node = nodes[i]
    step = att.steps[i]
    pos = positions[i]
    if step and pos then
      state = self:GetStepState(att, step, i)
      questId = step.questId or step.resolvedQuestId
      node:ClearAllPoints()
      node:SetPoint("TOPLEFT", graphContent, "TOPLEFT", pos.x, -pos.y)
      node.step = step
      node.questId = questId
      node.owner = att
      node.stepIndex = i
      node.state = state
      node.isAttunement = true
      node.tooltipAbove = (pos.y > (contentHeight - 120)) and true or nil
      node.leftIcon:SetTexture(self:GetAttunementStepActionIcon(step))
      node.label:SetText(step.title or ("Step " .. i))
      subtitle = self:GetAttunementStepSubtitle(step, state, att)
      node.subtitle = subtitle
      if node.subLabel then
        node.subLabel:SetText(subtitle or "")
        if step.kind == "attuned" then
          node.subLabel:SetTextColor(0.90, 0.90, 0.90)
        else
          node.subLabel:SetTextColor(1.00, 0.82, 0.00)
        end
      end
      if node.indexLabel then
        node.indexLabel:SetText("")
        node.indexLabel:Hide()
      end

      if step.kind == "attuned" then
        if state == "DONE" then
          bgR, bgG, bgB = 0.055, 0.306, 0.576
        else
          bgR, bgG, bgB = 0.557, 0.055, 0.075
        end
        borderR, borderG, borderB = 1.0, 1.0, 1.0
        alpha = 0.70
      elseif state == "DONE" then
        bgR, bgG, bgB = 0.373, 0.729, 0.275
        borderR, borderG, borderB = 0.373, 0.729, 0.275
        alpha = 0.30
      elseif state == "ACTIVE" or state == "AVAILABLE" then
        bgR, bgG, bgB = 0.851, 0.608, 0.0
        borderR, borderG, borderB = 0.851, 0.608, 0.0
        alpha = 0.30
      else
        bgR, bgG, bgB = 0.10, 0.10, 0.10
        borderR, borderG, borderB = 0.40, 0.40, 0.40
        alpha = 0.50
      end
      if node.SetBackdropColor then
        node:SetBackdropColor(bgR, bgG, bgB, alpha)
      end
      if node.SetBackdropBorderColor then
        node:SetBackdropBorderColor(borderR, borderG, borderB, 1)
      end
      if node.stepBg then
        node.stepBg:SetVertexColor(0, 0, 0, 0)
      end
      if node.statusBar then
        node.statusBar:Hide()
      end

      names, badgeCount = self:GetGuildNamesForAttunementStep(att, i)
      node.guildNames = names
      node.guildCount = badgeCount
      if badgeCount > 0 then
        node.countText:SetText(badgeCount)
        node.countBadge:ClearAllPoints()
        node.countBadge:SetPoint("TOPRIGHT", node, "TOPRIGHT", 8, 8)
        node.countBadge:Show()
      else
        node.countBadge:Hide()
      end

      if node.connectorH then node.connectorH:Hide() end
      if node.connectorV then node.connectorV:Hide() end
      node:Show()
    else
      node:Hide()
      if node.countBadge then node.countBadge:Hide() end
      if node.connectorH then node.connectorH:Hide() end
      if node.connectorV then node.connectorV:Hide() end
      node.questId = nil
      node.owner = nil
      node.stepIndex = nil
      node.step = nil
      node.isAttunement = nil
      node.guildNames = nil
      node.guildCount = 0
      node.subtitle = nil
      if node.subLabel then node.subLabel:SetText("") end
    end
  end

  self:UpdateAttunementGraphScroll(contentWidth, contentHeight)
end


function pfQuestLedger:SerializeGuildState(sourceType, comparisonOnly)
  local parts = {}
  local _, class = UnitClass("player")
  local level = UnitLevel("player") or 0
  local faction = self:GetFactionLabel()
  local record = self:BuildLocalGuildRecord()
  local visibleAtts = self:GetVisibleGuildAttunements()
  local i, code, state
  table.insert(parts, "STATE")
  table.insert(parts, UnitName("player") or "?")
  table.insert(parts, class or "?")
  table.insert(parts, tostring(level))
  table.insert(parts, faction)
  table.insert(parts, "v=" .. tostring(self.guildProtocolVersion or 1))
  table.insert(parts, "av=" .. tostring(self.version or "?"))
  if not comparisonOnly then
    table.insert(parts, "src=" .. tostring(sourceType or "manual"))
  end

  for i = 1, table.getn(visibleAtts) do
    code = self:GetGuildAttunementCode(visibleAtts[i])
    state = record.attunements[code]
    if state then
      table.insert(parts, string.lower(code) .. "=" .. (state.done or 0) .. "/" .. (state.total or 0))
    end
  end

  if record.reputations and record.reputations.ARGENT_DAWN then
    table.insert(parts, "rep_argent_dawn=" .. tostring(record.reputations.ARGENT_DAWN))
  end

  return table.concat(parts, self.msgSep or "~")
end

function pfQuestLedger:BroadcastGuildState(force, sourceType)
  if not GetGuildInfo("player") then
    self:Print("Guild sync is unavailable because you are not in a guild.")
    return false
  end

  local now = time()
  if not force and now - (pfQuestLedgerDB.character.lastBroadcastAt or 0) < 5 then
    return false
  end

  local payload = self:SerializeGuildState(sourceType or "manual")
  if string.len(self.prefix) + string.len(payload) > 254 then
    self:Print("Guild payload is too large for SendAddonMessage.")
    return false
  end

  SendAddonMessage(self.prefix, payload, "GUILD")
  self:AddDebugEvent("sync", "Broadcasted guild state to GUILD (" .. tostring(sourceType or "manual") .. ").")
  pfQuestLedgerDB.character.lastBroadcastAt = now
  self:UpdatePublishedGuildState(nil, now)
  return true
end

function pfQuestLedger:RequestGuildState()
  if not GetGuildInfo("player") then
    self:Print("Guild sync is unavailable because you are not in a guild.")
    return false
  end

  local payload = "REQ" .. (self.msgSep or "~") .. (UnitName("player") or "?")
  if string.len(self.prefix) + string.len(payload) > 254 then
    return false
  end

  SendAddonMessage(self.prefix, payload, "GUILD")
  self:AddDebugEvent("sync", "Sent guild state request to GUILD.")
  return true
end

function pfQuestLedger:CanTargetedRequestGuildState(target)
  local now = time()
  local stamp, cooldown
  if not target or target == "" or target == (UnitName("player") or "") then
    return false, 0
  end
  pfQuestLedgerDB.character.lastTargetedGuildRequestAt = pfQuestLedgerDB.character.lastTargetedGuildRequestAt or {}
  stamp = tonumber(pfQuestLedgerDB.character.lastTargetedGuildRequestAt[target]) or 0
  cooldown = tonumber(self.guildTargetedRequestCooldown) or 15
  if stamp > 0 and (now - stamp) < cooldown then
    return false, cooldown - (now - stamp)
  end
  return true, 0
end

function pfQuestLedger:RequestGuildStateFrom(target)
  local payload, canSend, waitSeconds

  if not GetGuildInfo("player") then
    self:Print("Guild sync is unavailable because you are not in a guild.")
    return false
  end

  canSend, waitSeconds = self:CanTargetedRequestGuildState(target)
  if not canSend then
    self:Print("Targeted request is on cooldown for " .. tostring(waitSeconds or 0) .. "s.")
    return false
  end

  payload = "REQ" .. (self.msgSep or "~") .. (UnitName("player") or "?")
  if string.len(self.prefix) + string.len(payload) > 254 then
    return false
  end

  SendAddonMessage(self.prefix, payload, "WHISPER", target)
  pfQuestLedgerDB.character.lastTargetedGuildRequestAt[target] = time()
  self:AddDebugEvent("sync", "Sent targeted guild state request to " .. tostring(target) .. ".")
  return true
end

function pfQuestLedger:GetGuildButtonCooldownRemaining(kind)
  local stamp = 0
  local now = time()
  local duration = self.guildButtonCooldown or (30 * 60)

  if kind == "broadcast" then
    stamp = pfQuestLedgerDB.character.lastGuildBroadcastClickAt or 0
  else
    stamp = pfQuestLedgerDB.character.lastGuildRequestClickAt or 0
  end

  if stamp <= 0 then
    return 0
  end

  if now - stamp >= duration then
    return 0
  end

  return duration - (now - stamp)
end

function pfQuestLedger:FormatGuildButtonCooldown(seconds)
  local mins, secs
  seconds = math.floor(seconds or 0)
  if seconds < 0 then seconds = 0 end
  mins = math.floor(seconds / 60)
  secs = math.mod(seconds, 60)
  if secs < 10 then
    return mins .. ":0" .. secs
  end
  return mins .. ":" .. secs
end

function pfQuestLedger:RefreshGuildActionButtons()
  local broadcastButton, requestButton, remaining

  if not self.frame then return end

  broadcastButton = self.frame.broadcastButton
  requestButton = self.frame.requestButton

  if broadcastButton then
    remaining = self:GetGuildButtonCooldownRemaining("broadcast")
    if remaining > 0 then
      broadcastButton:SetText(self:FormatGuildButtonCooldown(remaining))
      broadcastButton:Disable()
    else
      broadcastButton:SetText("Broadcast")
      broadcastButton:Enable()
    end
  end

  if requestButton then
    remaining = self:GetGuildButtonCooldownRemaining("request")
    if remaining > 0 then
      requestButton:SetText(self:FormatGuildButtonCooldown(remaining))
      requestButton:Disable()
    else
      requestButton:SetText("Request")
      requestButton:Enable()
    end
  end
end

function pfQuestLedger:HandleGuildBroadcastButton()
  if self:GetGuildButtonCooldownRemaining("broadcast") > 0 then
    self:RefreshGuildActionButtons()
    return
  end

  if self:BroadcastGuildState(true, "manual") then
    pfQuestLedgerDB.character.lastGuildBroadcastClickAt = time()
  end
  self:RefreshGuildActionButtons()
end

function pfQuestLedger:HandleGuildRequestButton()
  if self:GetGuildButtonCooldownRemaining("request") > 0 then
    self:RefreshGuildActionButtons()
    return
  end

  if self:RequestGuildState() then
    pfQuestLedgerDB.character.lastGuildRequestClickAt = time()
  end
  self:RefreshGuildActionButtons()
end

function pfQuestLedger:HandleAddonMessage(message, sender, distribution)
  if not message or message == "" then return end
  if sender == UnitName("player") then return end

  local parts = {}
  local token
  local sep = self.msgSep or "~"
  local pattern = "([^" .. sep .. "]+)"
  for token in string.gfind(message, pattern) do
    table.insert(parts, token)
  end

  if table.getn(parts) == 0 then return end

  if parts[1] == "REQ" then
    if sender and sender ~= "" then
      self:AddDebugEvent("sync", "Received REQ from " .. tostring(sender) .. ".")
      self:QueueGuildStateReply(sender)
    end
    return
  end

  if parts[1] ~= "STATE" or table.getn(parts) < 5 then
    return
  end

  local record = {
    class = parts[3],
    level = tonumber(parts[4]) or 0,
    faction = parts[5],
    protocolVersion = 1,
    addonVersion = "",
    sourceType = distribution == "WHISPER" and "reply" or "manual",
    attunements = {},
    reputations = {},
    updatedAt = time(),
  }

  local i, code, done, total, repCode, repStanding, protoVersion, addonVersion, sourceType
  for i = 6, table.getn(parts) do
    _, _, protoVersion = string.find(parts[i], "v=([%d]+)")
    if protoVersion then
      record.protocolVersion = tonumber(protoVersion) or 1
    else
      _, _, addonVersion = string.find(parts[i], "av=(.+)")
      if addonVersion then
        record.addonVersion = tostring(addonVersion or "")
      else
        _, _, sourceType = string.find(parts[i], "src=(.+)")
        if sourceType then
          record.sourceType = tostring(sourceType or record.sourceType or "unknown")
        else
          _, _, repCode, repStanding = string.find(parts[i], "rep_([%w_]+)=([%d]+)")
          if repCode then
            record.reputations[string.upper(repCode)] = tonumber(repStanding) or 0
          else
            _, _, code, done, total = string.find(parts[i], "([%w_]+)=([%d]+)/([%d]+)")
            if code then
              record.attunements[string.upper(code)] = {
                done = tonumber(done) or 0,
                total = tonumber(total) or 0,
              }
            end
          end
        end
      end
    end
  end

  pfQuestLedgerDB.guild.members[sender] = self:SanitizeGuildRecord(sender, record)
  self:AddDebugEvent("sync", "Received guild state from " .. tostring(sender) .. " via " .. tostring(distribution or "?") .. " (" .. tostring(record.sourceType or "unknown") .. ").")
  if self.frame and self.frame:IsShown() then
    self:Refresh()
  end
end

function pfQuestLedger:SetSearchText(text)
  local tab = self:GetActiveTab()
  self:SetSearchTextForTab(tab, text)
  pfQuestLedgerDB.profile.page[tab] = 1
  if tab == "QUESTS" then
    pfQuestLedgerDB.profile.forcedQuestId = nil
  end
  self:Refresh()
end

function pfQuestLedger:OpenStatusFilterMenu()
  self:ToggleFilterMenu("status", self.frame.statusButton)
end

function pfQuestLedger:OpenCategoryFilterMenu()
  self:ToggleFilterMenu("category", self.frame.categoryButton)
end

function pfQuestLedger:OpenChainStatusFilterMenu()
  self:ToggleFilterMenu("chainStatus", self.frame.chainStatusButton)
end

function pfQuestLedger:OpenLevelFilterMenu()
  self:ToggleFilterMenu("level", self.frame.levelButton)
end

function pfQuestLedger:SetActiveTab(tab)
  if tab == "GUILD" and not self:IsGuildTabAvailable() then
    return
  end

  self:HideFilterMenus()
  pfQuestLedgerDB.profile.activeTab = tab
  pfQuestLedgerDB.profile.search = self:GetSearchText(tab)
  pfQuestLedgerDB.profile.page[tab] = pfQuestLedgerDB.profile.page[tab] or 1
  if tab ~= "QUESTS" then
    pfQuestLedgerDB.profile.forcedQuestId = nil
  end
  self:Refresh()
end

function pfQuestLedger:GetPagedSlice(items)
  local tab = pfQuestLedgerDB.profile.activeTab
  local page = pfQuestLedgerDB.profile.page[tab] or 1
  local pageCount = math.max(1, math.ceil(table.getn(items) / self.listPageSize))
  if page > pageCount then page = pageCount end
  if page < 1 then page = 1 end
  pfQuestLedgerDB.profile.page[tab] = page

  local startIndex = ((page - 1) * self.listPageSize) + 1
  local finishIndex = math.min(table.getn(items), startIndex + self.listPageSize - 1)
  return startIndex, finishIndex, page, pageCount
end

function pfQuestLedger:ChangePage(delta)
  local tab = pfQuestLedgerDB.profile.activeTab
  pfQuestLedgerDB.profile.page[tab] = (pfQuestLedgerDB.profile.page[tab] or 1) + delta
  if pfQuestLedgerDB.profile.page[tab] < 1 then pfQuestLedgerDB.profile.page[tab] = 1 end
  self:Refresh()
end

function pfQuestLedger:SelectListItem(index)
  local object = self.currentList[index]
  if not object then return end

  local tab = pfQuestLedgerDB.profile.activeTab
  if tab == "QUESTS" then
    self.selection[tab] = object.id
    pfQuestLedgerDB.profile.forcedQuestId = nil
  elseif tab == "GUILD" then
    self.selection[tab] = object.name
  else
    self.selection[tab] = object._listKey
  end
  self:RefreshDetails()
  self:RefreshListButtons()
end

function pfQuestLedger:FindAttunementByListKey(listKey)
  local i
  for i = 1, table.getn(self.attunements) do
    if self.attunements[i]._listKey == listKey then
      return self.attunements[i]
    end
  end
  return nil
end

function pfQuestLedger:FindChainByListKey(listKey)
  local i
  for i = 1, table.getn(self.chains) do
    if self.chains[i]._listKey == listKey then
      return self.chains[i]
    end
  end
  return nil
end

function pfQuestLedger:HideDetailLinks()
  if not self.frame or not self.frame.detailLinks then return end
  local i, button
  for i = 1, table.getn(self.frame.detailLinks) do
    button = self.frame.detailLinks[i]
    button:Hide()
    button.questId = nil
    button.step = nil
    button.owner = nil
    button.isAttunement = nil
    button.stepIndex = nil
    if button.label then
      button.label:SetText("")
    end
  end
end

function pfQuestLedger:UpdateDetailsGuideLayout(showGuide)
  if not self.frame or not self.frame.details then return end

  local details = self.frame.details
  details:ClearAllPoints()
  details:SetPoint("TOPLEFT", 10, -10)

  if showGuide and self.frame.guideButton and self.frame.guideButton:IsShown() then
    details:SetPoint("TOPRIGHT", self.frame.guideButton, "TOPLEFT", -10, 0)
  else
    details:SetPoint("TOPRIGHT", -10, -10)
  end
end

function pfQuestLedger:ClearDetails()
  if not self.frame or not self.frame.details then return end
  self.frame.details:Clear()
  self:HideDetailLinks()
  if self.frame and self.frame.guideButton then
    self.frame.guideButton:Hide()
  end
  self:UpdateDetailsGuideLayout(false)
end

function pfQuestLedger:AddDetailLine(text, r, g, b)
  self.frame.details:AddMessage(text, r or 1, g or 1, b or 1)
end


function pfQuestLedger:GetQuestStarterInfo(id)
  if self.questStarterCache[id] ~= nil then
    return self.questStarterCache[id] or nil
  end

  local info = nil
  local addonKey = "PFLEDGER_STARTER"
  local ok = false

  if pfDatabase and pfDatabase.SearchQuestID and pfMap and pfMap.DeleteNode and pfMap.nodes then
    pfMap:DeleteNode(addonKey)
    ok = pcall(function()
      pfDatabase:SearchQuestID(id, { addon = addonKey }, {})
    end)

    if ok and pfMap.nodes[addonKey] then
      local bestScore = nil
      local zoneId, coords, nodeTitle, node, x, y, zoneName, score
      for zoneId, coords in pairs(pfMap.nodes[addonKey]) do
        for _, titles in pairs(coords) do
          for nodeTitle, node in pairs(titles) do
            if node then
              x = tonumber(node.x)
              y = tonumber(node.y)
              zoneName = (pfMap.GetMapNameByID and pfMap:GetMapNameByID(zoneId)) or (pfDB and pfDB["zones"] and pfDB["zones"]["loc"] and pfDB["zones"]["loc"][zoneId]) or tostring(zoneId)
              if x and y and zoneName then
                score = 0
                if node.questid == id then score = score + 10 end
                if node.QTYPE == "NPC_START" or node.QTYPE == "OBJECT_START" then score = score + 5 end
                if node.layer == 1 or node.layer == 2 then score = score + 2 end
                if type(bestScore) ~= "number" or score > bestScore then
                  bestScore = score
                  info = {
                    zoneId = tonumber(zoneId),
                    floor = node.floor and tonumber(node.floor) or nil,
                    zoneName = zoneName,
                    x = x,
                    y = y,
                    title = node.spawn or nodeTitle or ((self.questLocale[id] and self.questLocale[id].T) or ("Quest " .. id)),
                    qtype = node.QTYPE,
                    layer = node.layer or 99,
                  }
                end
              end
            end
          end
        end
      end
    end

    pfMap:DeleteNode(addonKey)
  end

  self.questStarterCache[id] = info or false
  return info
end

function pfQuestLedger:NormalizeTomTomZoneName(zoneName)
  if not zoneName or zoneName == "" then
    return zoneName
  end

  local aliases = {
    ["stormwind city"] = "Stormwind",
    ["orgrimmar city"] = "Orgrimmar",
    ["ironforge city"] = "Ironforge",
    ["darnassus city"] = "Darnassus",
    ["thunder bluff city"] = "Thunder Bluff",
    ["undercity city"] = "Undercity",
    ["the undercity"] = "Undercity",
  }

  local normalized = string.lower(zoneName)
  if aliases[normalized] then
    return aliases[normalized]
  end

  local stripped = string.gsub(zoneName, "%s+[Cc]ity$", "")
  if stripped ~= "" then
    return stripped
  end

  return zoneName
end

function pfQuestLedger:ResolveWorldMapZone(zoneName)
  if not zoneName or zoneName == "" or not GetMapContinents or not GetMapZones then
    return nil, nil
  end

  local normalized = string.lower(zoneName)
  local continents = { GetMapContinents() }
  local i, j, zones, zname

  for i = 1, table.getn(continents) do
    zones = { GetMapZones(i) }
    for j = 1, table.getn(zones) do
      zname = zones[j]
      if zname and string.lower(zname) == normalized then
        return i, j
      end
    end
  end

  return nil, nil
end

function pfQuestLedger:TryTomTomWaypoint(info)
  if not info or not TomTom then
    return false
  end

  local title = info.title or "Questgiver"
  local zoneName = info.zoneName
  local tomtomZoneName = self:NormalizeTomTomZoneName(zoneName)
  local x = tonumber(info.x)
  local y = tonumber(info.y)
  if not tomtomZoneName or tomtomZoneName == "" or not x or not y then
    return false
  end

  if SlashCmdList and SlashCmdList["TOMTOM_WAY"] then
    local ok = pcall(function()
      SlashCmdList["TOMTOM_WAY"](string.format("%s %.1f, %.1f %s", tomtomZoneName, x, y, title))
    end)
    if ok then return true end
  end

  local continent, zone = self:ResolveWorldMapZone(tomtomZoneName)
  if continent and zone and TomTom.AddZWaypoint then
    local ok = pcall(function()
      TomTom:AddZWaypoint(continent, zone, x / 100, y / 100, title, false, true, true)
    end)
    if ok then return true end
  end

  if TomTom.AddWaypoint then
    local ok = pcall(function()
      TomTom:AddWaypoint(tomtomZoneName, x / 100, y / 100, { title = title })
    end)
    if ok then return true end
  end

  return false
end

function pfQuestLedger:GuideToQuestStarter(id)
  local info = self:GetQuestStarterInfo(id)
  if not info then
    self:Print("Quest giver location is unavailable in the current pfQuest database.")
    return
  end

  if self:TryTomTomWaypoint(info) then
    self:Print("Waypoint added for " .. (info.title or "quest giver") .. ".")
    return
  end

  self:Print(string.format("%s - %s %.1f, %.1f", info.title or "Quest giver", info.zoneName or "Unknown zone", info.x or 0, info.y or 0))
end

function pfQuestLedger:PopulateDetailLinks(owner, isAttunement)
  if not self.frame or not self.frame.detailLinks then return end

  local i, button, step, qid, state, prefix, indent, statusText, color
  for i = 1, table.getn(self.frame.detailLinks) do
    button = self.frame.detailLinks[i]
    step = owner and owner.steps and owner.steps[i]
    if step then
      qid = step.questId or step.resolvedQuestId
      state = self:GetStepState(owner, step, i)
      statusText = self:GetStepStateText(state)
      indent = string.rep("  ", step.depth or 0)
      color = self:GetStepColor(state)
      prefix = string.format("%02d. ", i)
      if qid then
        button.label:SetText(indent .. color .. prefix .. step.title .. " (" .. qid .. ") - " .. statusText .. "|r")
      else
        button.label:SetText(indent .. color .. prefix .. step.title .. " - " .. statusText .. "|r")
      end
      button.questId = qid
      button.step = step
      button.owner = owner
      button.isAttunement = isAttunement and true or false
      button.stepIndex = i
      button:Show()
    else
      button:Hide()
      button.questId = nil
      button.step = nil
      button.owner = nil
      button.isAttunement = nil
      button.stepIndex = nil
      button.label:SetText("")
    end
  end
end

function pfQuestLedger:RenderQuestDetails(id)
  self:ClearDetails()
  if self.frame and self.frame.details then
    self.frame.details:SetHeight(350)
  end
  if self.frame and self.frame.guideButton then
    self.frame.guideButton:Hide()
  end
  self:UpdateDetailsGuideLayout(false)
  if not id or not self.questLocale[id] then
    self:AddDetailLine("Select a quest to inspect its status.", 0.8, 0.8, 0.8)
    return
  end

  local locale = self.questLocale[id]
  local data = self.questData[id] or {}
  local status = self:GetQuestStatus(id)
  local starter = self:GetQuestStarterInfo(id)

  self:AddDetailLine(locale.T, 0.3, 1.0, 0.8)
  self:AddDetailLine("ID: " .. id .. "    Status: " .. self:GetQuestStatusText(status), 1, 1, 1)
  self:AddDetailLine("Quest Level: " .. (tonumber(data.lvl) or 0) .. "    Required Level: " .. (tonumber(data.min) or 0), 1, 1, 1)

  if data.class then self:AddDetailLine("Class Restricted: yes", 1, 1, 1) end
  if data.skill then self:AddDetailLine("Profession Restricted: yes", 1, 1, 1) end
  if data.event then self:AddDetailLine("Event Quest: yes", 1, 1, 1) end
  if data.pre then self:AddDetailLine("Prerequisites: " .. tcount(data.pre), 1, 1, 1) end

  if starter then
    self:AddDetailLine("Quest giver: " .. (starter.title or "Unknown"), 1, 1, 1)
    self:AddDetailLine(string.format("Location: %s %.1f, %.1f", starter.zoneName or "Unknown zone", starter.x or 0, starter.y or 0), 1, 1, 1)
    if self.frame and self.frame.guideButton then
      self.frame.guideButton.questId = id
      self.frame.guideButton:Show()
      self:UpdateDetailsGuideLayout(true)
    end
  else
    self:AddDetailLine("Quest giver: location unavailable in the current pfQuest database.", 0.8, 0.8, 0.8)
    self:UpdateDetailsGuideLayout(false)
  end

  if self.attByQuestId[id] then
    self:AddDetailLine(" ")
    self:AddDetailLine("Attunements:", 1, 0.82, 0.2)
    local i, att
    for i = 1, table.getn(self.attByQuestId[id]) do
      att = self:FindAttunementByListKey(self.attByQuestId[id][i])
      if att then
        self:AddDetailLine(" - " .. att.name .. " [" .. (att.side or "Both") .. "]", 1, 1, 1)
      end
    end
  end

  self:AddDetailLine(" ")
  self:AddDetailLine("Objective:", 1, 0.82, 0.2)
  self:AddDetailLine(locale.O or "No objective text in pfQuest DB.", 0.9, 0.9, 0.9)

  self:AddDetailLine(" ")
  self:AddDetailLine("Description:", 1, 0.82, 0.2)
  self:AddDetailLine(locale.D or "No description text in pfQuest DB.", 0.75, 0.75, 0.75)
end

function pfQuestLedger:RenderChainOrAttunementDetails(object, isAttunementTab)
  self:ClearDetails()
  if self.frame and self.frame.details then
    self.frame.details:SetHeight(110)
  end
  if self.frame and self.frame.guideButton then
    self.frame.guideButton:Hide()
  end
  self:UpdateDetailsGuideLayout(false)
  if not object then
    self:AddDetailLine("Select an item to inspect its steps.", 0.8, 0.8, 0.8)
    return
  end

  local done, total, summary = self:GetAttunementProgress(object)
  local header = object.name
  if object.side and object.side ~= "Both" then
    header = header .. " - " .. object.side
  end

  self:AddDetailLine(header, 0.3, 1.0, 0.8)
  self:AddDetailLine((object.category or "") .. " / " .. (object.group or ""), 1, 1, 1)
  self:AddDetailLine("Progress: " .. self:BuildProgressBar(done, total, 20) .. " " .. done .. "/" .. total .. " - " .. summary, 1, 1, 1)
  self:AddDetailLine(" ")
  self:AddDetailLine(object.summary or "", 0.85, 0.85, 0.85)
  self:AddDetailLine(" ")
  self:AddDetailLine("Steps below are clickable.", 1, 0.82, 0.2)
  self:AddDetailLine("Left click opens the quest in the Quests tab.", 0.8, 0.8, 0.8)
  if isAttunementTab then
    self:AddDetailLine("Right click toggles manual-only steps.", 0.8, 0.8, 0.8)
  end
  self:PopulateDetailLinks(object, isAttunementTab)
end

function pfQuestLedger:GetGuildClassIconCoords(classToken)
  local coords = nil
  local fallback = {
    WARRIOR = { 0, 0.25, 0, 0.25 },
    MAGE = { 0.25, 0.49609375, 0, 0.25 },
    ROGUE = { 0.49609375, 0.7421875, 0, 0.25 },
    DRUID = { 0.7421875, 0.98828125, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 },
    SHAMAN = { 0.25, 0.49609375, 0.25, 0.5 },
    PRIEST = { 0.49609375, 0.7421875, 0.25, 0.5 },
    WARLOCK = { 0.7421875, 0.98828125, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
  }

  if CLASS_ICON_TCOORDS and classToken and CLASS_ICON_TCOORDS[classToken] then
    coords = CLASS_ICON_TCOORDS[classToken]
  else
    coords = fallback[classToken]
  end

  if coords then
    return coords[1], coords[2], coords[3], coords[4]
  end

  return 0, 0.25, 0, 0.25
end

function pfQuestLedger:GetGuildAttunementPercent(record, att)
  local state = self:GetGuildRecordAttunementState(record, att)
  local done = state and (state.done or 0) or 0
  local total = state and (state.total or 0) or 0
  local pct = 0
  if total > 0 then
    pct = math.floor(((done / total) * 100) + 0.5)
  end
  return done, total, pct
end

function pfQuestLedger:DeleteGuildMemberRecord(name)
  if not name or name == (UnitName("player") or "") then
    return
  end

  self:ClearGuildDeleteConfirm(name)

  if pfQuestLedgerDB.guild.members[name] then
    pfQuestLedgerDB.guild.members[name] = nil
  end
  if pfQuestLedgerDB.guild.rosterMissingCounts then
    pfQuestLedgerDB.guild.rosterMissingCounts[name] = nil
  end

  if self.selection and self.selection.GUILD == name then
    self.selection.GUILD = nil
  end

  self:Refresh()
  self:RefreshGuildDeleteButtons()
end

function pfQuestLedger:IsGuildRecordProtocolMismatch(record)
  if not record then return false end
  return tonumber(record.protocolVersion or 1) ~= tonumber(self.guildProtocolVersion or 1)
end


function pfQuestLedger:ShowGuildMatrixTooltip(button)
  if not button then return end

  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  if button.isHeader and button.att then
    GameTooltip:SetText(button.att.name or "Attunement", 1, 0.82, 0)
    GameTooltip:AddLine((button.att.category or "") .. " - " .. (button.att.group or ""), 0.80, 0.80, 0.80)
    GameTooltip:Show()
    return
  end

  if button.memberName and button.att then
    GameTooltip:SetText(button.memberName, 0.3, 1.0, 0.8)
    GameTooltip:AddLine(button.att.name or "Attunement", 1, 0.82, 0)
    GameTooltip:AddLine((button.done or 0) .. "/" .. (button.total or 0) .. " - " .. (button.percent or 0) .. "%", 0.85, 0.85, 0.85)
    if button.record then
      GameTooltip:AddLine("Source: " .. self:FormatGuildSourceLabel(button.record.sourceType), 0.75, 0.75, 0.75)
    end
    if button.record and button.record.isSelf then
      GameTooltip:AddLine("Current character", 0.75, 0.75, 0.75)
    end
    GameTooltip:Show()
    return
  end

  if button.memberName then
    GameTooltip:SetText(button.memberName, 0.3, 1.0, 0.8)
    if button.record then
      GameTooltip:AddLine("Level " .. (button.record.level or 0) .. " " .. self:FormatClassName(button.record.class), 0.85, 0.85, 0.85)
      GameTooltip:AddLine("Protocol: " .. tostring(button.record.protocolVersion or 1), self:IsGuildRecordProtocolMismatch(button.record) and 1.0 or 0.75, self:IsGuildRecordProtocolMismatch(button.record) and 0.45 or 0.75, self:IsGuildRecordProtocolMismatch(button.record) and 0.45 or 0.75)
      if self:IsGuildRecordProtocolMismatch(button.record) then
        GameTooltip:AddLine("Expected protocol: " .. tostring(self.guildProtocolVersion or 1), 1.0, 0.45, 0.45)
      end
      if button.record.addonVersion and button.record.addonVersion ~= "" then
        GameTooltip:AddLine("Addon: " .. tostring(button.record.addonVersion), 0.75, 0.75, 0.75)
      else
        GameTooltip:AddLine("Addon: unknown", 0.75, 0.75, 0.75)
      end
      GameTooltip:AddLine("Source: " .. self:FormatGuildSourceLabel(button.record.sourceType), 0.75, 0.75, 0.75)
      if button.record.updatedAt then
        GameTooltip:AddLine("Last update: " .. date("%Y-%m-%d %H:%M:%S", button.record.updatedAt), 0.75, 0.75, 0.75)
      end
    end
    GameTooltip:Show()
  end
end

function pfQuestLedger:HideGuildMatrixTooltip()
  GameTooltip:Hide()
end

function pfQuestLedger:RefreshGuildPanel(items)
  if not self.frame or not self.frame.guildBackdrop then return end

  local visibleAtts = self:GetVisibleGuildAttunements()
  local guildName = GetGuildInfo("player") or "Guild Sync"
  local memberCount = table.getn(items or {})
  local titleIcon = self.frame.guildTitleIcon
  local titleText = self.frame.guildTitleText
  local titleMeta = self.frame.guildTitleMeta
  local slider = self.frame.guildLevelSlider
  local sliderValue = self:GetGuildMinLevel()
  local header = self.frame.guildHeader
  local headerIcons = self.frame.guildHeaderIcons or {}
  local rows = self.frame.guildRows or {}
  local emptyText = self.frame.guildEmptyText
  local scrollChild = self.frame.guildScrollChild
  local scroll = self.frame.guildScroll
  local scrollBar = self.frame.guildScrollBar
  local nameWidth = self:GetGuildNameColumnWidth()
  local leftWidth = 70 + nameWidth
  local columnWidth = 42
  local refreshWidth = 28
  local deleteWidth = 40
  local rowHeight = 30
  local contentWidth = leftWidth + (table.getn(visibleAtts) * columnWidth) + refreshWidth + deleteWidth + 20
  local i, att, icon, row, record, xOffset, done, total, percent, cell, classLeft, classRight, classTop, classBottom

  if titleIcon then
    titleIcon:Hide()
  end
  titleText:ClearAllPoints()
  titleText:SetPoint("TOPLEFT", self.frame.guildBackdrop, "TOPLEFT", 14, -18)
  titleText:SetText(guildName)
  titleMeta:ClearAllPoints()
  titleMeta:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -6)
  titleMeta:SetPoint("TOPRIGHT", self.frame.guildBackdrop, "TOPRIGHT", -250, -52)
  titleMeta:SetText(memberCount .. " synced characters")
  self:RefreshGuildActionButtons()

  if slider then
    self.frame.guildSliderIgnore = true
    slider:SetValue(sliderValue)
    self.frame.guildSliderIgnore = nil
    if self.frame.guildLevelValue then
      self.frame.guildLevelValue:SetText(tostring(sliderValue))
    end
  end

  if header then
    header:SetWidth(contentWidth)
  end
  if scrollChild then
    scrollChild:SetWidth(contentWidth)
  end

  xOffset = leftWidth + 10
  for i = 1, table.getn(headerIcons) do
    icon = headerIcons[i]
    att = visibleAtts[i]
    if att then
      icon.att = att
      icon.isHeader = true
      icon:ClearAllPoints()
      icon:SetPoint("TOPLEFT", header, "TOPLEFT", xOffset + ((i - 1) * columnWidth), -8)
      icon.texture:SetTexture(self:GetAttunementDisplayTexture(att))
      icon:Show()
    else
      icon.att = nil
      icon.isHeader = nil
      icon:Hide()
    end
  end

  if not items or memberCount == 0 then
    emptyText:SetText("No synced guild data matches the current filters.")
    emptyText:Show()
  else
    emptyText:Hide()
  end

  for i = 1, table.getn(rows) do
    row = rows[i]
    local item = items and items[i] or nil
    if item then
      record = item.data or {}
      row.memberName = item.name
      row.record = record
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i - 1) * rowHeight))
      row:SetWidth(contentWidth)
      if row.bg then
        if math.mod(i, 2) == 1 then
          row.bg:SetVertexColor(0.07, 0.07, 0.07, 0.92)
        else
          row.bg:SetVertexColor(0.11, 0.11, 0.11, 0.92)
        end
      end
      self:SetGuildRowHovered(row, false)
      row.level:SetText(tostring(record.level or 0))
      row.name:SetText(item.name or "?")
      if self:IsGuildRecordProtocolMismatch(record) then
        row.name:SetTextColor(1.00, 0.72, 0.25)
      else
        row.name:SetTextColor(record.isSelf and 0.30 or 1.00, record.isSelf and 1.00 or 1.00, record.isSelf and 0.80 or 1.00)
      end
      row.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
      classLeft, classRight, classTop, classBottom = self:GetGuildClassIconCoords(record.class)
      row.classIcon:SetTexCoord(classLeft, classRight, classTop, classBottom)
      row.delete.memberName = item.name
      if self:GetGuildDeleteConfirmSecondsRemaining(item.name) > 0 then
        row.delete:SetText("!")
      else
        row.delete:SetText("X")
      end
      if row.refresh then
        row.refresh.memberName = item.name
      end
      if record.isSelf then
        row.delete:Hide()
        if row.refresh then row.refresh:Hide() end
      else
        row.delete:Show()
        if row.refresh then row.refresh:Show() end
      end

      for iconIndex = 1, table.getn(row.cells) do
        cell = row.cells[iconIndex]
        att = visibleAtts[iconIndex]
        if att then
          done, total, percent = self:GetGuildAttunementPercent(record, att)
          cell.memberName = item.name
          cell.record = record
          cell.att = att
          cell.done = done
          cell.total = total
          cell.percent = percent
          cell:ClearAllPoints()
          cell:SetPoint("LEFT", row, "LEFT", xOffset + ((iconIndex - 1) * columnWidth), 0)
          if total > 0 and done >= total then
            cell.text:SetText("")
            cell.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            cell.check:Show()
          else
            cell.check:Hide()
            if total > 0 then
              cell.text:SetText(percent .. "%")
            else
              cell.text:SetText("0%")
            end
            if percent > 0 then
              cell.text:SetTextColor(1.0, 1.0, 1.0)
            else
              cell.text:SetTextColor(0.72, 0.72, 0.72)
            end
          end
          cell:Show()
        else
          cell.memberName = nil
          cell.record = nil
          cell.att = nil
          cell.done = nil
          cell.total = nil
          cell.percent = nil
          cell.text:SetText("")
          cell.check:Hide()
          cell:Hide()
        end
      end

      row:Show()
    else
      row.memberName = nil
      row.record = nil
      row:Hide()
      if row.refresh then
        row.refresh.memberName = nil
        row.refresh:Hide()
      end
      if row.delete then row.delete:SetText("X") row.delete:Hide() end
      for iconIndex = 1, table.getn(row.cells) do
        cell = row.cells[iconIndex]
        cell.memberName = nil
        cell.record = nil
        cell.att = nil
        cell.done = nil
        cell.total = nil
        cell.percent = nil
        cell.text:SetText("")
        cell.check:Hide()
        cell:Hide()
      end
    end
  end

  local contentHeight = math.max(rowHeight, memberCount * rowHeight)
  scrollChild:SetHeight(contentHeight)

  local viewportHeight = scroll and scroll:GetHeight() or 0
  if viewportHeight < 1 then viewportHeight = 300 end
  if scrollBar then
    local maxScroll = math.max(0, contentHeight - viewportHeight)
    local currentValue = scrollBar:GetValue() or 0
    scrollBar:SetMinMaxValues(0, maxScroll)
    scrollBar:SetValueStep(16)
    if currentValue > maxScroll then currentValue = maxScroll end
    if currentValue < 0 then currentValue = 0 end
    scrollBar:SetValue(currentValue)
    if maxScroll > 0 then
      scrollBar:Show()
    else
      scrollBar:Hide()
      if scroll then scroll:SetVerticalScroll(0) end
    end
  end
end

function pfQuestLedger:RenderGuildDetails(name)
  self:ClearDetails()
  if self.frame and self.frame.details then
    self.frame.details:SetHeight(380)
  end
  if self.frame and self.frame.guideButton then
    self.frame.guideButton:Hide()
  end
  self:UpdateDetailsGuideLayout(false)
  if not name or not pfQuestLedgerDB.guild.members[name] then
    self:AddDetailLine("Select a guild member to inspect synced attunement progress.", 0.8, 0.8, 0.8)
    return
  end

  local record = pfQuestLedgerDB.guild.members[name]
  self:AddDetailLine(name, 0.3, 1.0, 0.8)
  self:AddDetailLine("Class: " .. self:FormatClassName(record.class) .. "    Level: " .. (record.level or 0) .. "    Faction: " .. (record.faction or "?"), 1, 1, 1)
  self:AddDetailLine("Protocol: " .. tostring(record.protocolVersion or 1) .. "    Addon: " .. ((record.addonVersion and record.addonVersion ~= "") and record.addonVersion or "unknown") .. "    Source: " .. self:FormatGuildSourceLabel(record.sourceType), 1, 1, 1)
  self:AddDetailLine("Last update: " .. date("%Y-%m-%d %H:%M:%S", record.updatedAt or time()), 1, 1, 1)
  self:AddDetailLine(" ")
  self:AddDetailLine("Attunements:", 1, 0.82, 0.2)

  local i, att, state
  for i = 1, table.getn(self.attunements) do
    att = self.attunements[i]
    if self:IsSideVisible(att.side) then
      state = record.attunements[string.upper(att.id)]
      if state then
        self:AddDetailLine(" - " .. att.name .. " [" .. att.id .. "]: " .. state.done .. "/" .. state.total, 1, 1, 1)
      end
    end
  end
end

function pfQuestLedger:RefreshDetails()
  if not self.frame or not self.frame:IsShown() then return end

  local tab = pfQuestLedgerDB.profile.activeTab
  if tab == "QUESTS" then
    self:RenderQuestDetails(self.selection[tab])
  elseif tab == "CHAINS" then
    self:RenderChainOrAttunementDetails(self:FindChainByListKey(self.selection[tab]), false)
  elseif tab == "ATTUNEMENTS" then
    self:RefreshAttunementPanel()
  elseif tab == "GUILD" then
    return
  end
end

function pfQuestLedger:GetListLabel(tab, object)
  if tab == "QUESTS" then
    local status = self:GetQuestStatus(object.id)
    local statusColor = self:GetStatusColor(status)
    local levelColor = self:GetLevelColor(self:GetQuestLevelBucket(object.id))
    return levelColor .. "[" .. object.lvl .. "]|r " .. object.title .. " - " .. statusColor .. self:GetQuestStatusText(status) .. "|r"
  elseif tab == "GUILD" then
    local totalDone, totalTotal = 0, 0
    local attId, state
    for attId, state in pairs(object.data.attunements or {}) do
      totalDone = totalDone + (state.done or 0)
      totalTotal = totalTotal + (state.total or 0)
    end
    return object.name .. " |cffaaaaaa- " .. (object.data.class or "?") .. " " .. (object.data.level or 0) .. " - " .. totalDone .. "/" .. totalTotal .. "|r"
  elseif tab == "CHAINS" then
    local status = self:GetChainStatus(object)
    local statusColor = self:GetStatusColor(status)
    local levelColor = self:GetLevelColorByLevel(self:GetAttunementSortLevel(object))
    return levelColor .. "[" .. self:GetAttunementSortLevel(object) .. "]|r " .. object.name .. " - " .. statusColor .. self:GetQuestStatusText(status) .. "|r |cffaaaaaa(" .. table.getn(object.steps) .. " quests)|r"
  end

  local done, total, summary = self:GetAttunementProgress(object)
  return object.name .. " [" .. (object.side or "Both") .. "] |cffaaaaaa" .. self:BuildProgressBar(done, total, 8) .. " " .. done .. "/" .. total .. " - " .. summary .. "|r"
end

function pfQuestLedger:RefreshListButtons()
  if not self.frame then return end
  local tab = pfQuestLedgerDB.profile.activeTab
  local i, button, object, selectedKey, selectedQuestId, selectedName

  for i = 1, self.listPageSize do
    button = self.frame.listButtons[i]
    object = self.currentList[i]
    if object then
      if button.label then
        button.label:SetText(self:GetListLabel(tab, object))
      end
      button:Show()
      if tab == "QUESTS" then
        selectedQuestId = self.selection[tab]
        if selectedQuestId and selectedQuestId == object.id then
          button:GetHighlightTexture():Show()
        else
          button:GetHighlightTexture():Hide()
        end
      elseif tab == "GUILD" then
        selectedName = self.selection[tab]
        if selectedName and selectedName == object.name then
          button:GetHighlightTexture():Show()
        else
          button:GetHighlightTexture():Hide()
        end
      else
        selectedKey = self.selection[tab]
        if selectedKey and selectedKey == object._listKey then
          button:GetHighlightTexture():Show()
        else
          button:GetHighlightTexture():Hide()
        end
      end
    else
      if button.label then
        button.label:SetText("")
      end
      button:GetHighlightTexture():Hide()
      button:Hide()
    end
  end
end

function pfQuestLedger:RefreshList()
  local tab = pfQuestLedgerDB.profile.activeTab
  local source
  if tab == "QUESTS" then
    source = self:GetVisibleQuestList()
  elseif tab == "CHAINS" then
    source = self:GetVisibleChainList()
  elseif tab == "ATTUNEMENTS" then
    source = self:GetVisibleAttunementList()
  else
    source = self:GetVisibleGuildList()
  end

  if tab == "ATTUNEMENTS" then
    self.currentList = source
    self.frame.pageText:SetText(table.getn(source) .. " destinations")
    self.frame.statusLine:SetText("Search: '" .. (self:GetSearchText("ATTUNEMENTS") or "") .. "'")
    self:RefreshAttunementCards(source)
    return
  elseif tab == "GUILD" then
    self.currentList = source
    self.frame.statusLine:SetText("Search: '" .. (self:GetSearchText("GUILD") or "") .. "' | Minimum level " .. self:GetGuildMinLevel() .. " | " .. table.getn(source) .. " characters")
    self:RefreshGuildPanel(source)
    return
  end

  local startIndex, finishIndex, page, pageCount = self:GetPagedSlice(source)
  local current = {}
  local i, idx
  idx = 1
  for i = startIndex, finishIndex do
    current[idx] = source[i]
    idx = idx + 1
  end
  self.currentList = current

  self.frame.pageText:SetText("Page " .. page .. "/" .. pageCount .. " - " .. table.getn(source) .. " items")
  if tab == "QUESTS" then
    self.frame.statusLine:SetText("Search: '" .. (self:GetSearchText("QUESTS") or "") .. "' | Status " .. self:GetFilterSelectedCount("status") .. "/" .. table.getn(self.statusOptions) .. " | Tags " .. self:GetFilterSelectedCount("category") .. "/" .. table.getn(self.categoryOptions) .. " | Level " .. self:GetFilterSelectedCount("level") .. "/" .. table.getn(self.levelOptions))
  elseif tab == "CHAINS" then
    self.frame.statusLine:SetText("Search: '" .. (self:GetSearchText("CHAINS") or "") .. "' | Chain status " .. self:GetFilterSelectedCount("chainStatus") .. "/" .. table.getn(self.chainStatusOptions))
  else
    self.frame.statusLine:SetText("Search: '" .. (self:GetSearchText(tab) or "") .. "'")
  end
  self:RefreshListButtons()
end

function pfQuestLedger:LayoutActionButtons(tab)
  local function hide(widget)
    widget:Hide()
    widget:ClearAllPoints()
  end
  local function place(widget, anchor)
    widget:ClearAllPoints()
    widget:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
    widget:Show()
    return widget
  end

  hide(self.frame.statusButton)
  hide(self.frame.chainStatusButton)
  hide(self.frame.categoryButton)
  hide(self.frame.levelButton)
  hide(self.frame.syncButton)
  hide(self.frame.broadcastButton)
  hide(self.frame.requestButton)

  local anchor = self.frame.searchBox
  if tab == "QUESTS" then
    anchor = place(self.frame.statusButton, anchor)
    anchor = place(self.frame.categoryButton, anchor)
    anchor = place(self.frame.levelButton, anchor)
    place(self.frame.syncButton, anchor)
  elseif tab == "CHAINS" then
    anchor = place(self.frame.chainStatusButton, anchor)
    place(self.frame.syncButton, anchor)
  elseif tab == "ATTUNEMENTS" then
    place(self.frame.syncButton, anchor)
  elseif tab == "GUILD" then
    anchor = place(self.frame.broadcastButton, anchor)
    place(self.frame.requestButton, anchor)
  end
  self:RefreshGuildActionButtons()
end

function pfQuestLedger:RefreshControls()
  local tab = pfQuestLedgerDB.profile.activeTab
  local i, button, tabKey, guildAvailable

  guildAvailable = self:IsGuildTabAvailable()
  if tab == "GUILD" and not guildAvailable then
    pfQuestLedgerDB.profile.activeTab = "QUESTS"
    tab = "QUESTS"
  end

  for i = 1, table.getn(self.frame.tabs) do
    button = self.frame.tabs[i]
    tabKey = self.tabOrder[i]
    if tabKey == "GUILD" then
      if guildAvailable then
        button:Enable()
      else
        button:Disable()
      end
    else
      button:Enable()
    end

    if tabKey == tab then
      button:LockHighlight()
      button:SetAlpha(1)
    else
      button:UnlockHighlight()
      if tabKey == "GUILD" and not guildAvailable then
        button:SetAlpha(0.50)
      else
        button:SetAlpha(0.85)
      end
    end
  end

  self.frame.searchBox:SetText(self:GetSearchText(tab) or "")
  self:RefreshFilterButtons()
  self:LayoutActionButtons(tab)
  if tab ~= "QUESTS" and tab ~= "CHAINS" then
    self:HideFilterMenus()
  end

  self.frame.manualStepLabel:Hide()
  self.frame.manualStepBox:Hide()
  self.frame.openQuestButton:Hide()
  self.frame.toggleManualButton:Hide()
  if self.frame.guideButton then
    self.frame.guideButton:Hide()
  end

  local isAtt = (tab == "ATTUNEMENTS") and true or false
  local isGuild = (tab == "GUILD") and true or false
  local usesCustomPanel = (isAtt or isGuild) and true or false

  if self.frame.listBackdrop then
    if usesCustomPanel then self.frame.listBackdrop:Hide() else self.frame.listBackdrop:Show() end
  end
  if self.frame.detailsBackdrop then
    if usesCustomPanel then self.frame.detailsBackdrop:Hide() else self.frame.detailsBackdrop:Show() end
  end
  if self.frame.attBackdrop then
    if isAtt then self.frame.attBackdrop:Show() else self.frame.attBackdrop:Hide() end
  end
  if self.frame.guildBackdrop then
    if isGuild then self.frame.guildBackdrop:Show() else self.frame.guildBackdrop:Hide() end
  end
  if self.frame.prevButton then
    if usesCustomPanel then self.frame.prevButton:Hide() else self.frame.prevButton:Show() end
  end
  if self.frame.nextButton then
    if usesCustomPanel then self.frame.nextButton:Hide() else self.frame.nextButton:Show() end
  end
  if self.frame.pageText then
    if usesCustomPanel then self.frame.pageText:Hide() else self.frame.pageText:Show() end
  end
end

function pfQuestLedger:Refresh()
  if not self.frame or not self.frame:IsShown() then return end
  self:RefreshControls()
  self:RefreshList()
  self:RefreshDetails()
end

function pfQuestLedger:GetSelectedStepIndex()
  local text = self:Trim(self.frame.manualStepBox:GetText())
  local value = tonumber(text)
  if not value then return nil end
  return math.floor(value)
end

function pfQuestLedger:GetSelectedStepOwner()
  local tab = pfQuestLedgerDB.profile.activeTab
  if tab == "ATTUNEMENTS" then
    return self:FindAttunementByListKey(self.selection.ATTUNEMENTS)
  elseif tab == "CHAINS" then
    return self:FindChainByListKey(self.selection.CHAINS)
  end
  return nil
end

function pfQuestLedger:OpenQuestById(questId)
  if not questId then
    return
  end

  self:HideFilterMenus()
  pfQuestLedgerDB.profile.activeTab = "QUESTS"
  pfQuestLedgerDB.profile.search = self:GetSearchText("QUESTS")
  pfQuestLedgerDB.profile.page.QUESTS = 1
  pfQuestLedgerDB.profile.forcedQuestId = questId
  self.selection.QUESTS = questId
  self:Refresh()
end

function pfQuestLedger:OpenSelectedStepQuest()
  local owner = self:GetSelectedStepOwner()
  if not owner then
    self:Print("Select a chain or attunement first.")
    return
  end

  local stepIndex = self:GetSelectedStepIndex()
  if not stepIndex or stepIndex < 1 or stepIndex > table.getn(owner.steps) then
    self:Print("Invalid step number.")
    return
  end

  local step = owner.steps[stepIndex]
  local questId = step.questId or step.resolvedQuestId
  if step.kind ~= "quest" or not questId then
    self:Print("This step is not backed by a quest.")
    return
  end

  self:OpenQuestById(questId)
end

function pfQuestLedger:HandleDetailLinkClick(button, mouseButton)
  if not button or not button.step then
    return
  end

  if button.questId then
    self:OpenQuestById(button.questId)
    return
  end

  if mouseButton == "RightButton" and button.isAttunement and button.owner and button.stepIndex then
    local current = self:GetManualState(button.owner.id, button.stepIndex)
    self:SetManualState(button.owner.id, button.stepIndex, not current)
    self:MarkGuildStateDirty()
    self:ProcessAutoGuildTraffic()
    self:Refresh()
  end
end

function pfQuestLedger:ShowDetailLinkTooltip(button)
  if not button or not button.step then return end

  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  if button.step.title then
    GameTooltip:SetText(button.step.title, 1, 1, 1)
  end
  if button.questId then
    GameTooltip:AddLine("Quest ID: " .. button.questId, 0.9, 0.9, 0.9)
    GameTooltip:AddLine("Left click to open this quest in the Quests tab.", 0.8, 0.8, 0.8)
  elseif button.isAttunement then
    GameTooltip:AddLine("Right click to toggle this manual step.", 0.8, 0.8, 0.8)
  end
  if button.step.note and button.step.note ~= "" then
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine(button.step.note, 0.75, 0.75, 0.75, 1)
  end
  GameTooltip:Show()
end

function pfQuestLedger:ToggleManualStep()
  local att = self:FindAttunementByListKey(self.selection.ATTUNEMENTS)
  if not att then
    self:Print("Select an attunement first.")
    return
  end

  local stepIndex = self:GetSelectedStepIndex()
  if not stepIndex or stepIndex < 1 or stepIndex > table.getn(att.steps) then
    self:Print("Invalid manual step number.")
    return
  end

  local step = att.steps[stepIndex]
  if step.kind == "quest" then
    self:Print("Quest steps are read-only. Use /db query or regular quest progression.")
    return
  end

  local current = self:GetManualState(att.id, stepIndex)
  self:SetManualState(att.id, stepIndex, not current)
  self:MarkGuildStateDirty()
  self:ProcessAutoGuildTraffic()
  self:Refresh()
end

function pfQuestLedger:TriggerQuestSync()
  if pfDatabase and pfDatabase.QueryServer then
    pfDatabase:QueryServer()
    pfQuestLedgerDB.character.lastQuestSyncAt = time()
    self:Print("Requested completed quest sync from the server.")
  else
    self:Print("pfQuest QueryServer is unavailable.")
  end
end

function pfQuestLedger:EnsureLauncherButton()
  if self.launcher then return end

  local button = CreateFrame("Button", "pfQuestLedgerLauncher", UIParent)
  button:SetWidth(31)
  button:SetHeight(31)
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetClampedToScreen(true)
  button:SetFrameStrata("DIALOG")
  button:SetFrameLevel(20)

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetAllPoints(button)
  background:SetVertexColor(0, 0, 0, 1)
  button.background = background

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetDrawLayer("ARTWORK", 1)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Key_14")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon:SetWidth(18)
  icon:SetHeight(18)
  icon:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.icon = icon

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(54)
  border:SetHeight(54)
  border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  button.border = border

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  highlight:SetWidth(40)
  highlight:SetHeight(40)
  highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
  highlight:SetBlendMode("ADD")
  highlight:SetVertexColor(1, 1, 1, 0.75)
  button.highlight = highlight

  local pos = pfQuestLedgerDB and pfQuestLedgerDB.profile and pfQuestLedgerDB.profile.launcher or nil
  button:ClearAllPoints()
  button:SetPoint("CENTER", UIParent, "CENTER", (pos and pos.x) or -220, (pos and pos.y) or -120)

  button:SetScript("OnDragStart", function()
    this:StartMoving()
  end)

  button:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local cx, cy = this:GetCenter()
    local px, py = UIParent:GetCenter()
    if cx and px and cy and py then
      pfQuestLedgerDB.profile.launcher.x = math.floor(cx - px + 0.5)
      pfQuestLedgerDB.profile.launcher.y = math.floor(cy - py + 0.5)
    end
  end)

  button:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      pfQuestLedger:ResetLauncherPosition()
      return
    end
    pfQuestLedger:ToggleWindow()
  end)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("pfQuestLedger", 0.3, 1.0, 0.8)
    GameTooltip:AddLine("Left click - open/close", 1, 1, 1)
    GameTooltip:AddLine("Drag - move button", 1, 1, 1)
    GameTooltip:AddLine("Right click - reset button position", 1, 1, 1)
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  self.launcher = button
end

function pfQuestLedger:ResetLauncherPosition()
  if not pfQuestLedgerDB or not pfQuestLedgerDB.profile or not pfQuestLedgerDB.profile.launcher then return end
  pfQuestLedgerDB.profile.launcher.x = -220
  pfQuestLedgerDB.profile.launcher.y = -120
  if self.launcher then
    self.launcher:ClearAllPoints()
    self.launcher:SetPoint("CENTER", UIParent, "CENTER", -220, -120)
  end
end

function pfQuestLedger:InitializeRuntime()
  if self.initialized then return end
  self:EnsureDB()
  self:BuildQuestCaches()
  self:BuildQuestGraph()
  self:BuildChains()
  self:ResolveAttunementSteps()
  self:EnsureLauncherButton()
  self.initialized = true
end

function pfQuestLedger:RefreshRuntimeCaches()
  self:EnsureDB()
  self.questStarterCache = {}
  self:BuildQuestCaches()
  self:BuildQuestGraph()
  self:BuildChains()
  self:ResolveAttunementSteps()
end

function pfQuestLedger:GetMonotonicTime()
  if GetTime then
    return GetTime()
  end

  return tonumber(time()) or 0
end

function pfQuestLedger:ScheduleQuestProgressWork(refreshUI)
  local now = self:GetMonotonicTime()
  local uiDueAt = now + (self.questUpdateUIRefreshDebounce or 0.20)
  local dirtyDueAt = now + (self.questUpdateGuildDirtyDebounce or 0.75)

  self.pendingGuildStateDirtyAt = dirtyDueAt

  if refreshUI and self.frame and self.frame:IsShown() then
    self.pendingQuestUIRefreshAt = uiDueAt
  end
end

function pfQuestLedger:ProcessPendingDeferredWork(now)
  now = tonumber(now) or self:GetMonotonicTime()

  if self.pendingGuildStateDirtyAt and now >= self.pendingGuildStateDirtyAt then
    self.pendingGuildStateDirtyAt = nil
    self:MarkGuildStateDirty()
  end

  if self.pendingQuestUIRefreshAt and now >= self.pendingQuestUIRefreshAt then
    self.pendingQuestUIRefreshAt = nil
    if self.frame and self.frame:IsShown() then
      self:Refresh()
    end
  end
end

function pfQuestLedger:CreateButton(parent, width, height, text)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(height)
  button:SetText(text)
  return button
end

function pfQuestLedger:CreateUI()
  if self.frame then return end

  local frame = CreateFrame("Frame", "pfQuestLedgerMainFrame", UIParent)
  frame:SetWidth(980)
  frame:SetHeight(600)
  frame:SetPoint("CENTER", 0, 0)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetToplevel(true)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.90)
  frame:SetBackdropBorderColor(1, 1, 1, 1)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetScript("OnHide", function() pfQuestLedger:HideFilterMenus() end)
  frame:SetScript("OnUpdate", function()
    this.guildButtonUpdateElapsed = (this.guildButtonUpdateElapsed or 0) + (arg1 or 0)
    if this.guildButtonUpdateElapsed < 0.5 then return end
    this.guildButtonUpdateElapsed = 0
    if pfQuestLedger then
      pfQuestLedger:RefreshGuildActionButtons()
      pfQuestLedger:RefreshGuildDeleteButtons()
    end
  end)
  frame:Hide()

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -14)
  title:SetText("pfQuestLedger " .. self.version)
  frame.title = title

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)

  frame.tabs = {}
  local i, tabKey, tabButton
  for i = 1, table.getn(self.tabOrder) do
    tabKey = self.tabOrder[i]
    tabButton = self:CreateButton(frame, 110, 22, self.tabLabels[tabKey])
    if i == 1 then
      tabButton:SetPoint("TOPLEFT", 16, -40)
    else
      tabButton:SetPoint("LEFT", frame.tabs[i-1], "RIGHT", 6, 0)
    end
    tabButton.tabKey = tabKey
    tabButton:SetScript("OnClick", function() pfQuestLedger:SetActiveTab(this.tabKey) end)
    if tabKey == "GUILD" then
      tabButton:SetScript("OnEnter", function()
        if pfQuestLedger and not pfQuestLedger:IsGuildTabAvailable() then
          GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
          GameTooltip:SetText("Guild tab unavailable", 1, 0.82, 0)
          GameTooltip:AddLine("Join a guild to use the guild sync view.", 0.80, 0.80, 0.80, 1)
          GameTooltip:Show()
        end
      end)
      tabButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    end
    frame.tabs[i] = tabButton
  end

  local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  searchLabel:SetPoint("TOPLEFT", 18, -74)
  searchLabel:SetText("Search")

  local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  searchBox:SetAutoFocus(false)
  searchBox:SetWidth(180)
  searchBox:SetHeight(24)
  searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
  searchBox:SetScript("OnEnterPressed", function()
    pfQuestLedger:SetSearchText(this:GetText())
    this:ClearFocus()
  end)
  searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  frame.searchBox = searchBox

  local statusButton = self:CreateButton(frame, 104, 22, self:GetFilterButtonText("status"))
  statusButton:SetScript("OnClick", function() pfQuestLedger:OpenStatusFilterMenu() end)
  frame.statusButton = statusButton

  local chainStatusButton = self:CreateButton(frame, 126, 22, self:GetFilterButtonText("chainStatus"))
  chainStatusButton:SetScript("OnClick", function() pfQuestLedger:OpenChainStatusFilterMenu() end)
  frame.chainStatusButton = chainStatusButton

  local categoryButton = self:CreateButton(frame, 96, 22, self:GetFilterButtonText("category"))
  categoryButton:SetScript("OnClick", function() pfQuestLedger:OpenCategoryFilterMenu() end)
  frame.categoryButton = categoryButton

  local levelButton = self:CreateButton(frame, 96, 22, self:GetFilterButtonText("level"))
  levelButton:SetScript("OnClick", function() pfQuestLedger:OpenLevelFilterMenu() end)
  frame.levelButton = levelButton

  local syncButton = self:CreateButton(frame, 100, 22, "Sync")
  syncButton:SetScript("OnClick", function() pfQuestLedger:TriggerQuestSync() end)
  frame.syncButton = syncButton

  local broadcastButton = self:CreateButton(frame, 100, 22, "Broadcast")
  broadcastButton:SetScript("OnClick", function() pfQuestLedger:HandleGuildBroadcastButton() end)
  frame.broadcastButton = broadcastButton

  local requestButton = self:CreateButton(frame, 100, 22, "Request")
  requestButton:SetScript("OnClick", function() pfQuestLedger:HandleGuildRequestButton() end)
  frame.requestButton = requestButton

  local listBackdrop = CreateFrame("Frame", nil, frame)
  listBackdrop:SetWidth(390)
  listBackdrop:SetHeight(400)
  listBackdrop:SetPoint("TOPLEFT", 16, -108)
  listBackdrop:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  listBackdrop:SetBackdropColor(0, 0, 0, 0.72)
  frame.listBackdrop = listBackdrop

  frame.listButtons = {}
  local button, highlight, y
  y = -8
  for i = 1, self.listPageSize do
    button = CreateFrame("Button", nil, listBackdrop)
    button:SetID(i)
    button:SetWidth(360)
    button:SetHeight(24)
    button:SetPoint("TOPLEFT", 10, y)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", function() pfQuestLedger:SelectListItem(this:GetID()) end)

    local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", button, "LEFT", 4, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    if label.SetJustifyH then
      label:SetJustifyH("LEFT")
    end
    if label.SetJustifyV then
      label:SetJustifyV("MIDDLE")
    end
    button.label = label

    highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)
    button:SetHighlightTexture(highlight)

    frame.listButtons[i] = button
    y = y - 27
  end

  local prevButton = self:CreateButton(frame, 80, 22, "Prev")
  prevButton:SetPoint("TOPLEFT", listBackdrop, "BOTTOMLEFT", 8, -8)
  prevButton:SetScript("OnClick", function() pfQuestLedger:ChangePage(-1) end)
  frame.prevButton = prevButton

  local nextButton = self:CreateButton(frame, 80, 22, "Next")
  nextButton:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
  nextButton:SetScript("OnClick", function() pfQuestLedger:ChangePage(1) end)
  frame.nextButton = nextButton

  local pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  pageText:SetPoint("LEFT", nextButton, "RIGHT", 12, 0)
  pageText:SetText("Page 1/1")
  frame.pageText = pageText

  local filterDismiss = CreateFrame("Frame", nil, UIParent)
  filterDismiss:SetAllPoints(UIParent)
  filterDismiss:SetFrameStrata("FULLSCREEN_DIALOG")
  filterDismiss:SetScript("OnUpdate", function()
    pfQuestLedger:PollFilterDismiss()
  end)
  filterDismiss:Hide()
  frame.filterDismiss = filterDismiss

  local detailsBackdrop = CreateFrame("Frame", nil, frame)
  detailsBackdrop:SetWidth(540)
  detailsBackdrop:SetHeight(400)
  detailsBackdrop:SetPoint("TOPLEFT", listBackdrop, "TOPRIGHT", 12, 0)
  detailsBackdrop:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  detailsBackdrop:SetBackdropColor(0, 0, 0, 0.72)
  frame.detailsBackdrop = detailsBackdrop

  local attBackdrop = CreateFrame("Frame", nil, frame)
  attBackdrop:SetWidth(936)
  attBackdrop:SetHeight(430)
  attBackdrop:SetPoint("TOPLEFT", 16, -108)
  attBackdrop:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  attBackdrop:SetBackdropColor(0, 0, 0, 1)
  attBackdrop:Hide()
  frame.attBackdrop = attBackdrop

  local attGridView = CreateFrame("Frame", nil, attBackdrop)
  attGridView:SetAllPoints(attBackdrop)
  frame.attGridView = attGridView

  frame.attCards = {}
  local cardCols, cardWidth, cardHeight, cardGapX, cardGapY = 4, 214, 122, 12, 12
  local cardIndex, row, col, card, iconBg, icon, titleFS, subFS, sideFS, levelFS
  for cardIndex = 1, 12 do
    row = math.floor((cardIndex - 1) / cardCols)
    col = math.mod(cardIndex - 1, cardCols)
    card = CreateFrame("Button", nil, attGridView)
    card:SetWidth(cardWidth)
    card:SetHeight(cardHeight)
    card:SetPoint("TOPLEFT", 14 + (col * (cardWidth + cardGapX)), -14 - (row * (cardHeight + cardGapY)))
    card:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.03, 0.03, 0.03, 0.96)
    card:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)
    card:RegisterForClicks("LeftButtonUp")
    card:SetScript("OnClick", function()
      if this.att then
        pfQuestLedger:SelectAttunementCard(this.att._listKey)
      end
    end)

    iconBg = card:CreateTexture(nil, "BORDER")
    iconBg:SetWidth(70)
    iconBg:SetHeight(70)
    iconBg:SetPoint("TOP", card, "TOP", 0, -12)
    iconBg:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(58)
    icon:SetHeight(58)
    icon:SetPoint("CENTER", iconBg, "CENTER", 0, 0)
    card.icon = icon

    levelFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelFS:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    levelFS:SetText("")
    card.level = levelFS

    sideFS = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sideFS:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -8)
    sideFS:SetText("")
    card.side = sideFS

    titleFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFS:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -86)
    titleFS:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -86)
    if titleFS.SetJustifyH then titleFS:SetJustifyH("CENTER") end
    titleFS:SetText("")
    card.title = titleFS

    subFS = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subFS:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -102)
    subFS:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -102)
    if subFS.SetJustifyH then subFS:SetJustifyH("CENTER") end
    subFS:SetText("")
    card.sub = subFS

    frame.attCards[cardIndex] = card
  end

  local attDetailView = CreateFrame("Frame", nil, attBackdrop)
  attDetailView:SetAllPoints(attBackdrop)
  attDetailView:Hide()
  frame.attDetailView = attDetailView

  local attBackButton = pfQuestLedger:CreateButton(attDetailView, 28, 20, "<")
  attBackButton:SetPoint("TOPLEFT", 12, -12)
  attBackButton:SetScript("OnClick", function()
    pfQuestLedger:BackToAttunementGrid()
  end)
  frame.attBackButton = attBackButton

  local attDetailArt = attDetailView:CreateTexture(nil, "BACKGROUND")
  attDetailArt:SetPoint("TOPRIGHT", attDetailView, "TOPRIGHT", -16, -16)
  attDetailArt:SetWidth(320)
  attDetailArt:SetHeight(320)
  attDetailArt:SetAlpha(0.92)
  frame.attDetailArt = attDetailArt

  local attDetailIcon = attDetailView:CreateTexture(nil, "ARTWORK")
  attDetailIcon:SetWidth(40)
  attDetailIcon:SetHeight(40)
  attDetailIcon:SetPoint("TOPLEFT", attBackButton, "TOPRIGHT", 12, -6)
  frame.attDetailIcon = attDetailIcon

  local attDetailTitle = attDetailView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  attDetailTitle:SetPoint("LEFT", attDetailIcon, "RIGHT", 10, 8)
  attDetailTitle:SetText("")
  frame.attDetailTitle = attDetailTitle

  local attDetailMeta = attDetailView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  attDetailMeta:SetPoint("TOPLEFT", attDetailIcon, "BOTTOMRIGHT", 10, -2)
  attDetailMeta:SetText("")
  frame.attDetailMeta = attDetailMeta

  local attDetailSummary = attDetailView:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  attDetailSummary:SetPoint("TOPLEFT", attDetailTitle, "BOTTOMLEFT", 0, -6)
  attDetailSummary:SetPoint("TOPRIGHT", attDetailView, "TOPRIGHT", -16, -54)
  if attDetailSummary.SetJustifyH then attDetailSummary:SetJustifyH("LEFT") end
  attDetailSummary:SetText("")
  frame.attDetailSummary = attDetailSummary

  local attGraphViewport = CreateFrame("Frame", nil, attDetailView)
  attGraphViewport:SetPoint("TOPLEFT", attDetailView, "TOPLEFT", 12, -92)
  attGraphViewport:SetPoint("BOTTOMRIGHT", attDetailView, "BOTTOMRIGHT", -12, 32)
  attGraphViewport:EnableMouseWheel(true)
  frame.attGraphViewport = attGraphViewport

  local attGraphScroll = CreateFrame("ScrollFrame", nil, attGraphViewport)
  attGraphScroll:SetAllPoints(attGraphViewport)
  frame.attGraphScroll = attGraphScroll

  local attGraphCanvas = CreateFrame("Frame", nil, attGraphScroll)
  attGraphCanvas:SetWidth(884)
  attGraphCanvas:SetHeight(300)
  attGraphCanvas:SetPoint("TOPLEFT", attGraphScroll, "TOPLEFT", 0, 0)
  attGraphScroll:SetScrollChild(attGraphCanvas)
  frame.attGraphCanvas = attGraphCanvas

  local attGraphContent = CreateFrame("Frame", nil, attGraphCanvas)
  attGraphContent:SetWidth(900)
  attGraphContent:SetHeight(300)
  attGraphContent:SetPoint("TOPLEFT", attGraphCanvas, "TOPLEFT", 0, 0)
  frame.attGraphContent = attGraphContent
  frame.attGraphLines = {}

  local attGraphSlider = CreateFrame("Slider", nil, attDetailView)
  attGraphSlider:SetPoint("BOTTOMLEFT", attGraphViewport, "BOTTOMLEFT", 0, -18)
  attGraphSlider:SetPoint("BOTTOMRIGHT", attGraphViewport, "BOTTOMRIGHT", 0, -18)
  attGraphSlider:SetHeight(16)
  attGraphSlider:SetMinMaxValues(0, 0)
  attGraphSlider:SetValueStep(1)
  attGraphSlider:SetValue(0)
  if attGraphSlider.SetOrientation then
    attGraphSlider:SetOrientation("HORIZONTAL")
  end
  attGraphSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  attGraphSlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  attGraphSlider:SetScript("OnValueChanged", function()
    if pfQuestLedger and pfQuestLedger.SetAttunementGraphScrollValue then
      pfQuestLedger:SetAttunementGraphScrollValue(this:GetValue() or 0)
    end
  end)
  attGraphSlider:Hide()
  frame.attGraphSlider = attGraphSlider

  attGraphViewport:EnableMouse(true)
  attGraphViewport:RegisterForDrag("LeftButton")
  attGraphViewport:SetScript("OnDragStart", function()
    if pfQuestLedger and pfQuestLedger.BeginAttunementGraphDrag then
      pfQuestLedger:BeginAttunementGraphDrag()
    end
  end)
  attGraphViewport:SetScript("OnDragStop", function()
    if pfQuestLedger and pfQuestLedger.EndAttunementGraphDrag then
      pfQuestLedger:EndAttunementGraphDrag()
    end
  end)

  attGraphViewport:SetScript("OnMouseWheel", function()
    if not pfQuestLedger.frame or not pfQuestLedger.frame.attGraphSlider then
      return
    end
    local slider = pfQuestLedger.frame.attGraphSlider
    if not slider:IsShown() then
      return
    end
    local minValue, maxValue = slider:GetMinMaxValues()
    local delta = arg1 and (arg1 * 64) or 0
    local newValue = (slider:GetValue() or 0) - delta
    if newValue < minValue then newValue = minValue end
    if newValue > maxValue then newValue = maxValue end
    slider:SetValue(newValue)
  end)

  frame.attStepNodes = {}
  local stepIndex, stepButton, stepBg, stepIcon, stepLabel, connector
  for stepIndex = 1, 80 do
    stepButton = CreateFrame("Button", nil, attGraphContent)
    stepButton:SetWidth(860)
    stepButton:SetHeight(22)
    stepButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    stepButton:SetScript("OnClick", function(arg1)
      pfQuestLedger:HandleDetailLinkClick(this, arg1)
    end)
    stepButton:SetScript("OnEnter", function()
      pfQuestLedger:ShowDetailLinkTooltip(this)
    end)
    stepButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    stepBg = stepButton:CreateTexture(nil, "BACKGROUND")
    stepBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    stepBg:SetVertexColor(0.07, 0.07, 0.07, 0.9)
    stepBg:SetAllPoints(stepButton)

    stepIcon = stepButton:CreateTexture(nil, "ARTWORK")
    stepIcon:SetWidth(14)
    stepIcon:SetHeight(14)
    stepIcon:SetPoint("LEFT", stepButton, "LEFT", 8, 0)
    stepButton.leftIcon = stepIcon

    stepLabel = stepButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stepLabel:SetPoint("LEFT", stepIcon, "RIGHT", 8, 0)
    stepLabel:SetPoint("RIGHT", stepButton, "RIGHT", -8, 0)
    if stepLabel.SetJustifyH then stepLabel:SetJustifyH("LEFT") end
    stepButton.label = stepLabel

    connector = attGraphContent:CreateTexture(nil, "BORDER")
    connector:SetWidth(2)
    connector:SetHeight(6)
    connector:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    connector:SetVertexColor(0.65, 0.65, 0.65, 1)
    connector:SetPoint("TOPLEFT", stepButton, "BOTTOMLEFT", 16, 0)
    stepButton.connector = connector

    frame.attStepNodes[stepIndex] = stepButton
  end

  local guildBackdrop = CreateFrame("Frame", nil, frame)
  guildBackdrop:SetWidth(936)
  guildBackdrop:SetHeight(430)
  guildBackdrop:SetPoint("TOPLEFT", 16, -108)
  guildBackdrop:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  guildBackdrop:SetBackdropColor(0, 0, 0, 1)
  guildBackdrop:Hide()
  frame.guildBackdrop = guildBackdrop

  local guildTitleIcon = guildBackdrop:CreateTexture(nil, "ARTWORK")
  guildTitleIcon:SetWidth(32)
  guildTitleIcon:SetHeight(32)
  guildTitleIcon:SetPoint("TOPLEFT", guildBackdrop, "TOPLEFT", 14, -14)
  guildTitleIcon:Hide()
  frame.guildTitleIcon = guildTitleIcon

  local guildTitleText = guildBackdrop:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  guildTitleText:SetPoint("TOPLEFT", guildBackdrop, "TOPLEFT", 14, -18)
  guildTitleText:SetText("Guild Sync")
  frame.guildTitleText = guildTitleText

  local guildTitleMeta = guildBackdrop:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  guildTitleMeta:SetPoint("TOPLEFT", guildTitleText, "BOTTOMLEFT", 0, -6)
  guildTitleMeta:SetPoint("TOPRIGHT", guildBackdrop, "TOPRIGHT", -250, -52)
  if guildTitleMeta.SetJustifyH then guildTitleMeta:SetJustifyH("LEFT") end
  guildTitleMeta:SetText("")
  frame.guildTitleMeta = guildTitleMeta

  local guildLevelLabel = guildBackdrop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  guildLevelLabel:SetPoint("TOPRIGHT", guildBackdrop, "TOPRIGHT", -74, -18)
  guildLevelLabel:SetText("Minimum Level")
  frame.guildLevelLabel = guildLevelLabel

  local guildLevelSlider = CreateFrame("Slider", nil, guildBackdrop)
  guildLevelSlider:SetWidth(210)
  guildLevelSlider:SetHeight(16)
  guildLevelSlider:SetPoint("TOPRIGHT", guildBackdrop, "TOPRIGHT", -18, -40)
  guildLevelSlider:SetMinMaxValues(1, 60)
  guildLevelSlider:SetValueStep(1)
  guildLevelSlider:SetValue(60)
  if guildLevelSlider.SetOrientation then
    guildLevelSlider:SetOrientation("HORIZONTAL")
  end
  guildLevelSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  guildLevelSlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  guildLevelSlider:SetScript("OnValueChanged", function()
    local value = math.floor((this:GetValue() or 1) + 0.5)
    if pfQuestLedger and pfQuestLedger.frame and pfQuestLedger.frame.guildLevelValue then
      pfQuestLedger.frame.guildLevelValue:SetText(tostring(value))
    end
    if pfQuestLedger and not pfQuestLedger.frame.guildSliderIgnore and pfQuestLedger:GetGuildMinLevel() ~= value then
      pfQuestLedger:SetGuildMinLevel(value)
      pfQuestLedger:Refresh()
    end
  end)
  frame.guildLevelSlider = guildLevelSlider

  local guildLevelLow = guildBackdrop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  guildLevelLow:SetPoint("TOPLEFT", guildLevelSlider, "BOTTOMLEFT", 0, -2)
  guildLevelLow:SetText("1")
  frame.guildLevelLow = guildLevelLow

  local guildLevelHigh = guildBackdrop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  guildLevelHigh:SetPoint("TOPRIGHT", guildLevelSlider, "BOTTOMRIGHT", 0, -2)
  guildLevelHigh:SetText("60")
  frame.guildLevelHigh = guildLevelHigh

  local guildLevelValue = guildBackdrop:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  guildLevelValue:SetPoint("TOP", guildLevelSlider, "BOTTOM", 0, -2)
  guildLevelValue:SetText("60")
  frame.guildLevelValue = guildLevelValue

  local guildHeader = CreateFrame("Frame", nil, guildBackdrop)
  guildHeader:SetWidth(884)
  guildHeader:SetHeight(42)
  guildHeader:SetPoint("TOPLEFT", guildBackdrop, "TOPLEFT", 12, -86)
  guildHeader:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  guildHeader:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
  guildHeader:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)
  frame.guildHeader = guildHeader

  local guildHeaderLabel = guildHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  guildHeaderLabel:SetPoint("LEFT", guildHeader, "LEFT", 12, 0)
  guildHeaderLabel:SetText("Character")
  frame.guildHeaderLabel = guildHeaderLabel

  frame.guildHeaderIcons = {}
  local guildHeaderIconButton, guildHeaderIconTexture
  for i = 1, 16 do
    guildHeaderIconButton = CreateFrame("Button", nil, guildHeader)
    guildHeaderIconButton:SetWidth(28)
    guildHeaderIconButton:SetHeight(28)
    guildHeaderIconButton:SetScript("OnEnter", function()
      pfQuestLedger:ShowGuildMatrixTooltip(this)
    end)
    guildHeaderIconButton:SetScript("OnLeave", function()
      pfQuestLedger:HideGuildMatrixTooltip()
    end)

    guildHeaderIconTexture = guildHeaderIconButton:CreateTexture(nil, "ARTWORK")
    guildHeaderIconTexture:SetWidth(20)
    guildHeaderIconTexture:SetHeight(20)
    guildHeaderIconTexture:SetPoint("CENTER", guildHeaderIconButton, "CENTER", 0, 0)
    guildHeaderIconButton.texture = guildHeaderIconTexture
    guildHeaderIconButton:Hide()
    frame.guildHeaderIcons[i] = guildHeaderIconButton
  end

  local guildScroll = CreateFrame("ScrollFrame", "pfQuestLedgerGuildScrollFrame", guildBackdrop, "UIPanelScrollFrameTemplate")
  guildScroll:SetPoint("TOPLEFT", guildHeader, "BOTTOMLEFT", 0, -8)
  guildScroll:SetPoint("BOTTOMRIGHT", guildBackdrop, "BOTTOMRIGHT", -30, 12)
  guildScroll:EnableMouseWheel(true)
  frame.guildScroll = guildScroll

  local guildScrollChild = CreateFrame("Frame", nil, guildScroll)
  guildScrollChild:SetWidth(884)
  guildScrollChild:SetHeight(1)
  guildScrollChild:SetPoint("TOPLEFT", guildScroll, "TOPLEFT", 0, 0)
  guildScroll:SetScrollChild(guildScrollChild)
  frame.guildScrollChild = guildScrollChild

  local guildScrollBar = _G["pfQuestLedgerGuildScrollFrameScrollBar"]
  frame.guildScrollBar = guildScrollBar
  frame.guildNameColumnWidth = self:GetGuildNameColumnWidth()
  if guildScrollBar then
    guildScrollBar:SetScript("OnValueChanged", function()
      if pfQuestLedger and pfQuestLedger.frame and pfQuestLedger.frame.guildScroll then
        pfQuestLedger.frame.guildScroll:SetVerticalScroll(this:GetValue() or 0)
      end
    end)
  end
  guildScroll:SetScript("OnMouseWheel", function()
    local bar = pfQuestLedger and pfQuestLedger.frame and pfQuestLedger.frame.guildScrollBar or nil
    if not bar or not bar:IsShown() then return end
    local minValue, maxValue = bar:GetMinMaxValues()
    local newValue = (bar:GetValue() or 0) - ((arg1 or 0) * 24)
    if newValue < minValue then newValue = minValue end
    if newValue > maxValue then newValue = maxValue end
    bar:SetValue(newValue)
  end)

  local guildEmptyText = guildBackdrop:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  guildEmptyText:SetPoint("CENTER", guildScroll, "CENTER", 0, 0)
  guildEmptyText:SetText("No synced guild data available.")
  frame.guildEmptyText = guildEmptyText

  frame.guildRows = {}
  local guildRow, guildRowBg, guildRowLevel, guildRowClassIcon, guildRowName, guildCell, guildCellBg, guildCellText, guildCellCheck, guildDelete
  for i = 1, 80 do
    guildRow = CreateFrame("Button", nil, guildScrollChild)
    guildRow:SetWidth(884)
    guildRow:SetHeight(30)
    guildRow:RegisterForClicks("LeftButtonUp")
    guildRow:SetScript("OnEnter", function()
      pfQuestLedger:SetGuildRowHovered(this, true)
      pfQuestLedger:ShowGuildMatrixTooltip(this)
    end)
    guildRow:SetScript("OnLeave", function()
      pfQuestLedger:SetGuildRowHovered(this, false)
      pfQuestLedger:HideGuildMatrixTooltip()
    end)

    guildRowBg = guildRow:CreateTexture(nil, "BACKGROUND")
    guildRowBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    guildRowBg:SetAllPoints(guildRow)
    guildRow.bg = guildRowBg

    local guildRowHover = guildRow:CreateTexture(nil, "ARTWORK")
    guildRowHover:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    guildRowHover:SetAllPoints(guildRow)
    guildRowHover:SetVertexColor(1.00, 0.82, 0.20, 0.22)
    guildRowHover:Hide()
    guildRow.hover = guildRowHover

    guildRowLevel = guildRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildRowLevel:SetPoint("LEFT", guildRow, "LEFT", 8, 0)
    guildRowLevel:SetWidth(24)
    if guildRowLevel.SetJustifyH then guildRowLevel:SetJustifyH("RIGHT") end
    guildRow.level = guildRowLevel

    guildRowClassIcon = guildRow:CreateTexture(nil, "ARTWORK")
    guildRowClassIcon:SetWidth(18)
    guildRowClassIcon:SetHeight(18)
    guildRowClassIcon:SetPoint("LEFT", guildRow, "LEFT", 36, 0)
    guildRow.classIcon = guildRowClassIcon

    guildRowName = guildRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildRowName:SetPoint("LEFT", guildRow, "LEFT", 60, 0)
    guildRowName:SetWidth(self:GetGuildNameColumnWidth())
    if guildRowName.SetJustifyH then guildRowName:SetJustifyH("LEFT") end
    guildRow.name = guildRowName

    local guildRefresh = CreateFrame("Button", nil, guildRow, "UIPanelButtonTemplate")
    guildRefresh:SetWidth(22)
    guildRefresh:SetHeight(18)
    guildRefresh:SetPoint("RIGHT", guildRow, "RIGHT", -42, 0)
    guildRefresh:SetText("")
    guildRefresh:SetScript("OnEnter", function()
      local remaining = 0
      pfQuestLedger:SetGuildRowHovered(this:GetParent(), true)
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Request fresh data", 1, 0.82, 0)
      GameTooltip:AddLine(this.memberName or "Unknown", 0.75, 0.75, 0.75)
      GameTooltip:AddLine("This sends a direct addon request to that character.", 0.80, 0.80, 0.80, 1)
      GameTooltip:AddLine("The target must be online to answer.", 0.80, 0.80, 0.80, 1)
      local canSend, waitSeconds = pfQuestLedger:CanTargetedRequestGuildState(this.memberName)
      if not canSend and (waitSeconds or 0) > 0 then
        GameTooltip:AddLine("Cooldown: " .. tostring(math.ceil(waitSeconds or 0)) .. "s", 1.0, 0.45, 0.45)
      end
      GameTooltip:Show()
    end)
    guildRefresh:SetScript("OnLeave", function()
      pfQuestLedger:SetGuildRowHovered(this:GetParent(), false)
      GameTooltip:Hide()
    end)
    guildRefresh:SetScript("OnClick", function()
      pfQuestLedger:RequestGuildStateFrom(this.memberName)
    end)
    guildRefresh.icon = guildRefresh:CreateTexture(nil, "ARTWORK")
    guildRefresh.icon:SetWidth(14)
    guildRefresh.icon:SetHeight(14)
    guildRefresh.icon:SetPoint("CENTER", guildRefresh, "CENTER", 0, 0)
    guildRefresh.icon:SetTexture(pfQuestLedger.guildRefreshButtonTexture)
    guildRow.refresh = guildRefresh

    guildDelete = pfQuestLedger:CreateButton(guildRow, 34, 18, "X")
    guildDelete:SetPoint("RIGHT", guildRow, "RIGHT", -6, 0)
    guildDelete:SetScript("OnEnter", function()
      local secondsRemaining = pfQuestLedger:GetGuildDeleteConfirmSecondsRemaining(this.memberName)
      pfQuestLedger:SetGuildRowHovered(this:GetParent(), true)
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Delete cached record", 1, 0.82, 0)
      GameTooltip:AddLine(this.memberName or "Unknown", 0.75, 0.75, 0.75)
      if secondsRemaining > 0 then
        GameTooltip:AddLine("Click again within " .. tostring(math.ceil(secondsRemaining)) .. "s to confirm.", 1.0, 0.45, 0.45, 1)
      else
        GameTooltip:AddLine("Two clicks are required to prevent accidental deletion.", 0.80, 0.80, 0.80, 1)
      end
      GameTooltip:Show()
    end)
    guildDelete:SetScript("OnLeave", function()
      pfQuestLedger:SetGuildRowHovered(this:GetParent(), false)
      GameTooltip:Hide()
    end)
    guildDelete:SetScript("OnClick", function()
      local secondsRemaining = pfQuestLedger:GetGuildDeleteConfirmSecondsRemaining(this.memberName)
      if secondsRemaining > 0 then
        pfQuestLedger:DeleteGuildMemberRecord(this.memberName)
      else
        pfQuestLedger:ArmGuildDelete(this.memberName)
        pfQuestLedger:RefreshGuildDeleteButtons()
      end
    end)
    guildRow.delete = guildDelete

    guildRow.cells = {}
    for j = 1, 16 do
      guildCell = CreateFrame("Button", nil, guildRow)
      guildCell:SetWidth(36)
      guildCell:SetHeight(20)
      guildCell:SetScript("OnEnter", function()
        pfQuestLedger:SetGuildRowHovered(this:GetParent(), true)
        pfQuestLedger:ShowGuildMatrixTooltip(this)
      end)
      guildCell:SetScript("OnLeave", function()
        pfQuestLedger:SetGuildRowHovered(this:GetParent(), false)
        pfQuestLedger:HideGuildMatrixTooltip()
      end)

      guildCellBg = guildCell:CreateTexture(nil, "BACKGROUND")
      guildCellBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
      guildCellBg:SetAllPoints(guildCell)
      guildCellBg:SetVertexColor(0, 0, 0, 0)
      guildCell.bg = guildCellBg

      guildCellText = guildCell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      guildCellText:SetPoint("CENTER", guildCell, "CENTER", 0, 0)
      guildCell.text = guildCellText

      guildCellCheck = guildCell:CreateTexture(nil, "ARTWORK")
      guildCellCheck:SetWidth(16)
      guildCellCheck:SetHeight(16)
      guildCellCheck:SetPoint("CENTER", guildCell, "CENTER", 0, 0)
      guildCellCheck:Hide()
      guildCell.check = guildCellCheck

      guildCell:Hide()
      guildRow.cells[j] = guildCell
    end

    guildRow:Hide()
    frame.guildRows[i] = guildRow
  end

  local details = CreateFrame("ScrollingMessageFrame", nil, detailsBackdrop)
  details:SetPoint("TOPLEFT", 10, -10)
  details:SetPoint("TOPRIGHT", -10, -10)
  details:SetHeight(110)
  details:SetFont(STANDARD_TEXT_FONT, 12)
  details:SetJustifyH("LEFT")
  details:SetFading(false)
  details:SetMaxLines(1000)
  frame.details = details

  frame.detailLinks = {}
  local linkButton, linkLabel, linkHighlight, linkY
  linkY = -126
  for i = 1, 18 do
    linkButton = CreateFrame("Button", nil, detailsBackdrop)
    linkButton:SetWidth(508)
    linkButton:SetHeight(16)
    linkButton:SetPoint("TOPLEFT", 12, linkY)
    linkButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    linkButton:SetScript("OnClick", function(arg1)
      pfQuestLedger:HandleDetailLinkClick(this, arg1)
    end)
    linkButton:SetScript("OnEnter", function()
      pfQuestLedger:ShowDetailLinkTooltip(this)
    end)
    linkButton:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    linkLabel = linkButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    linkLabel:SetPoint("LEFT", linkButton, "LEFT", 0, 0)
    linkLabel:SetPoint("RIGHT", linkButton, "RIGHT", 0, 0)
    if linkLabel.SetJustifyH then
      linkLabel:SetJustifyH("LEFT")
    end
    linkButton.label = linkLabel

    linkHighlight = linkButton:CreateTexture(nil, "HIGHLIGHT")
    linkHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    linkHighlight:SetBlendMode("ADD")
    linkHighlight:SetAllPoints(linkButton)
    linkButton:SetHighlightTexture(linkHighlight)
    linkButton:Hide()

    frame.detailLinks[i] = linkButton
    linkY = linkY - 17
  end

  local manualStepLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  manualStepLabel:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -12)
  manualStepLabel:SetText("Step")
  frame.manualStepLabel = manualStepLabel

  local manualStepBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  manualStepBox:SetAutoFocus(false)
  if manualStepBox.SetNumeric then
    manualStepBox:SetNumeric(true)
  end
  manualStepBox:SetWidth(40)
  manualStepBox:SetHeight(24)
  manualStepBox:SetPoint("LEFT", manualStepLabel, "RIGHT", 8, 0)
  manualStepBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  manualStepBox:SetScript("OnEnterPressed", function()
    pfQuestLedgerDB.profile.manualStepInput = this:GetText()
    this:ClearFocus()
  end)
  frame.manualStepBox = manualStepBox

  local openQuestButton = self:CreateButton(frame, 100, 22, "Open quest")
  openQuestButton:SetPoint("LEFT", manualStepBox, "RIGHT", 8, 0)
  openQuestButton:SetScript("OnClick", function() pfQuestLedger:OpenSelectedStepQuest() end)
  frame.openQuestButton = openQuestButton

  local toggleManualButton = self:CreateButton(frame, 110, 22, "Toggle Manual")
  toggleManualButton:SetPoint("LEFT", openQuestButton, "RIGHT", 8, 0)
  toggleManualButton:SetScript("OnClick", function() pfQuestLedger:ToggleManualStep() end)
  frame.toggleManualButton = toggleManualButton

  local guideButton = self:CreateButton(detailsBackdrop, 170, 22, "Guide to questgiver")
  guideButton:SetPoint("TOPRIGHT", detailsBackdrop, "TOPRIGHT", -10, -10)
  guideButton:SetFrameStrata("FULLSCREEN_DIALOG")
  guideButton:SetFrameLevel(detailsBackdrop:GetFrameLevel() + 5)
  guideButton:SetScript("OnClick", function()
    pfQuestLedger:GuideToQuestStarter(this.questId or pfQuestLedger.selection.QUESTS)
  end)
  guideButton.questId = nil
  guideButton:Hide()
  frame.guideButton = guideButton

  frame.filterMenus = {}
  frame.filterMenus.status = self:CreateFilterMenu(frame, "status", 170)
  frame.filterMenus.chainStatus = self:CreateFilterMenu(frame, "chainStatus", 210)
  frame.filterMenus.category = self:CreateFilterMenu(frame, "category", 190)
  frame.filterMenus.level = self:CreateFilterMenu(frame, "level", 170)

  local statusLine = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  statusLine:SetPoint("BOTTOMLEFT", 16, 12)
  statusLine:SetPoint("BOTTOMRIGHT", -16, 12)
  statusLine:SetJustifyH("LEFT")
  statusLine:SetText("")
  frame.statusLine = statusLine

  local specialExists = false
  local i
  for i = 1, table.getn(UISpecialFrames) do
    if UISpecialFrames[i] == "pfQuestLedgerMainFrame" then
      specialExists = true
      break
    end
  end
  if not specialExists then
    table.insert(UISpecialFrames, "pfQuestLedgerMainFrame")
  end

  frame:SetScript("OnHide", function()
    pfQuestLedger:HideFilterMenus()
  end)

  self.frame = frame
end

function pfQuestLedger:ToggleWindow()
  self:InitializeRuntime()

  if not self.frame then
    self:CreateUI()
  end

  if self.frame:IsShown() then
    self.frame:Hide()
    return
  end

  if not pfQuest or not pfDB then
    self:Print("pfQuest must be loaded before pfQuestLedger can be used.")
    return
  end

  self:RefreshRuntimeCaches()
  self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
  self.frame:SetToplevel(true)
  self.frame:Show()
  if self.frame.Raise then
    self.frame:Raise()
  end
  self:Refresh()
end

function pfQuestLedger:RegisterSlashCommands()
  if self.slashRegistered then return end

  SLASH_PFQUESTLEDGER1 = "/pfledger"
  SLASH_PFQUESTLEDGER2 = "/pfl"
  SlashCmdList["PFQUESTLEDGER"] = function(msg)
    local cmd, arg
    msg = pfQuestLedger:Trim(msg)
    _, _, cmd, arg = string.find(msg, "^(%S+)%s*(.-)$")
    cmd = pfQuestLedger:Lower(cmd or "")
    arg = pfQuestLedger:Lower(arg or "")

    if cmd == "reset" then
      pfQuestLedger:ResetLauncherPosition()
      if pfQuestLedger.frame then
        pfQuestLedger.frame:ClearAllPoints()
        pfQuestLedger.frame:SetPoint("CENTER", 0, 0)
      end
      pfQuestLedger:Print("Window and launcher positions were reset.")
      return
    elseif cmd == "resetcache" or cmd == "guildreset" then
      pfQuestLedger:ResetGuildCache()
      pfQuestLedger:Print("Guild cache was cleared.")
      return
    elseif cmd == "resetsync" then
      pfQuestLedger:ResetGuildSyncState()
      pfQuestLedger:Print("Guild sync state was reset.")
      return
    elseif cmd == "debug" then
      if arg == "on" then
        pfQuestLedgerDB.profile.debugEnabled = true
        pfQuestLedger:Print("Debug mode enabled.")
        pfQuestLedger:AddDebugEvent("debug", "Debug mode enabled.")
      elseif arg == "off" then
        pfQuestLedger:AddDebugEvent("debug", "Debug mode disabled.")
        pfQuestLedgerDB.profile.debugEnabled = false
        pfQuestLedger:Print("Debug mode disabled.")
      elseif arg == "dump" then
        pfQuestLedger:DumpDebugLog()
      elseif arg == "clear" then
        pfQuestLedger:ClearDebugLog()
        pfQuestLedger:Print("Debug log cleared.")
      else
        pfQuestLedger:Print("Usage: /pfl debug on|off|dump|clear")
      end
      return
    elseif cmd == "help" then
      pfQuestLedger:Print("/pfl reset - reset window position")
      pfQuestLedger:Print("/pfl resetcache - clear cached guild records")
      pfQuestLedger:Print("/pfl resetsync - clear guild sync timers and reply state")
      pfQuestLedger:Print("/pfl debug on|off|dump|clear")
      return
    elseif cmd == "pruneguild" then
      local removed = pfQuestLedger:PruneGuildMemberCache(true)
      pfQuestLedger:Print("Pruned " .. tostring(removed or 0) .. " guild cache record(s).")
      if pfQuestLedger.frame and pfQuestLedger.frame:IsShown() then
        pfQuestLedger:Refresh()
      end
      return
    end
    pfQuestLedger:ToggleWindow()
  end

  self.slashRegistered = true
end

function pfQuestLedger:Bootstrap()
  self:RegisterSlashCommands()
  self:InitializeRuntime()
end

pfQuestLedger:RegisterSlashCommands()

pfQuestLedger:RegisterEvent("ADDON_LOADED")
pfQuestLedger:RegisterEvent("QUEST_LOG_UPDATE")
pfQuestLedger:RegisterEvent("QUEST_QUERY_COMPLETE")
pfQuestLedger:RegisterEvent("CHAT_MSG_ADDON")
pfQuestLedger:RegisterEvent("GUILD_ROSTER_UPDATE")
pfQuestLedger:RegisterEvent("PLAYER_ENTERING_WORLD")
pfQuestLedger:RegisterEvent("PLAYER_LEVEL_UP")
pfQuestLedger:RegisterEvent("UPDATE_FACTION")
pfQuestLedger:RegisterEvent("PLAYER_REGEN_ENABLED")
pfQuestLedger:RegisterEvent("PLAYER_REGEN_DISABLED")
pfQuestLedger:RegisterEvent("ZONE_CHANGED_NEW_AREA")

pfQuestLedger:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == "pfQuestLedger" or (not pfQuestLedger.addonLoaded) then
      pfQuestLedger.addonLoaded = true
      pfQuestLedger:Bootstrap()
      pfQuestLedger:EnsureAutoGuildSchedule()
      pfQuestLedger:PruneGuildMemberCache(false)
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    pfQuestLedger:Bootstrap()
    pfQuestLedger:EnsureAutoGuildSchedule()
    if GetGuildInfo("player") then
      GuildRoster()
      pfQuestLedger:PruneGuildMemberCache(false)
    end
    pfQuestLedger:MarkGuildStateDirty()
  elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_QUERY_COMPLETE" then
    pfQuestLedger:InitializeRuntime()
    pfQuestLedger:ScheduleQuestProgressWork(true)
    pfQuestLedger:ProcessAutoGuildTraffic()
  elseif event == "PLAYER_LEVEL_UP" or event == "UPDATE_FACTION" then
    pfQuestLedger:InitializeRuntime()
    pfQuestLedger:ScheduleQuestProgressWork(true)
    pfQuestLedger:ProcessAutoGuildTraffic()
  elseif event == "PLAYER_REGEN_ENABLED" or event == "ZONE_CHANGED_NEW_AREA" then
    pfQuestLedger:ProcessAutoGuildTraffic()
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- no-op, used only to re-evaluate safe auto-sync windows after combat ends
  elseif event == "CHAT_MSG_ADDON" then
    if arg1 == pfQuestLedger.prefix then
      pfQuestLedger:HandleAddonMessage(arg2, arg4, arg3)
    end
  elseif event == "GUILD_ROSTER_UPDATE" then
    pfQuestLedger:PruneGuildMemberCache(false)
    if pfQuestLedger.frame and pfQuestLedger.frame:IsShown() then
      pfQuestLedger:Refresh()
    end
  end
end)

pfQuestLedger:SetScript("OnUpdate", function()
  this.autoGuildTickElapsed = (this.autoGuildTickElapsed or 0) + (arg1 or 0)
  if pfQuestLedger then
    pfQuestLedger:ProcessPendingDeferredWork()
  end
  if this.autoGuildTickElapsed < 1 then return end
  this.autoGuildTickElapsed = 0
  if pfQuestLedger then
    pfQuestLedger:ProcessAutoGuildTraffic()
  end
end)
