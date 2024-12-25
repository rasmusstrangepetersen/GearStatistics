-- *** Version information
REVISION = "11.3.0";

-- *** Local variables
local showDebug = 0; -- 1 = show debugs in general chat, 0 turns off debug
local initialized = false;
local cycleNumber = 0;
local timeCounter = 0;
local updateFrame = CreateFrame("frame");
local updateDelay = 2;

-- *** Functions

-- **************************************************************************
-- DESC : Debug function to print message to chat frame
-- VARS : Message = message to print to chat frame
-- **************************************************************************
function debugMessage(Message, override)
  if ((showDebug == 1 or override == 1) and Message ~= lastDebug) then
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorRed .."GS: " .. Message);
    lastDebug = Message;
  end
end

-- **************************************************************************
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
function GS_OnLoad(self)
  debugMessage("Loading GearStatistics", 0);
  
    -- Register the events we need
  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("PLAYER_LOGOUT");
  self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
  self:RegisterEvent("PLAYER_LEVEL_UP");
end

-- **************************************************************************
-- DESC : GearStat event handler
-- **************************************************************************
function GS_OnEvent(self, event, _, ...)

  debugMessage("Event: "..event, 0)

  -- Handle events
  if (initialized == true and (event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_LEVEL_UP")) then
    updateGearScore("player", 0);

    -- For TitanPanel support
    TitanPanelButton_UpdateButton(TITAN_GS_ID);
    TitanPanelButton_UpdateTooltip(self);

    if (GS_CharFrame:IsVisible()) then
      GS_CharFrame:Hide();
      GS_CharFrame:Show();
    end
    return;
  end
    
  if (event == "PLAYER_ENTERING_WORLD") then
    self:UnregisterEvent("PLAYER_ENTERING_WORLD");

    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:RegisterEvent("PLAYER_LEVEL_UP");
    self:RegisterEvent("PLAYER_LOGOUT");
    self:RegisterEvent("PLAYER_LEAVING_WORLD");

    initialise();
    initialized = true;
    return;
  end

  if (event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD") then
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:UnregisterEvent("PLAYER_LEVEL_UP");
      
    GS.currentPlayer = {};
    return;
  end
end

-- **************************************************************************
-- DESC : Initialise GearStatistics
-- **************************************************************************
function initialise()
  debugMessage("Initialising GearStatistics", 0);

  -- setup data block
  if (GS == nil) then
    GS = {};
    GS.currentPlayer = {};
    GS.Data = {};
  end
  if(GS.Data.version == nil or not (GS.Data.version == REVISION)) then
    GS = {};
    GS.currentPlayer = {};
    GS.Data = {}; -- zap all prior history if not current version
    GS.Data.version = REVISION;
    GS.Data.lastUpdated = time();
  end
  GS.thisRealm = GetRealmName();
  if(GS.Data[GS.thisRealm] == nil) then
    GS.Data[GS.thisRealm] = {};
  end
  
  -- Register our slash command
  SlashCmdList["GEARSTATISTICS"] = function(msg)
    slashCommandHandler(msg);
  end
  SLASH_GEARSTATISTICS1 = "/gs";

  hookTooltips();
  GS_Frame:Hide();
  
  updateFrame:SetScript("OnUpdate", GS_OnUpdate)
  debugMessage("slash registered", 0);
  DEFAULT_CHAT_FRAME:AddMessage("|c".. colorOrange .."".. TEXT_LOADED .. REVISION .. VERSION_WOWVERSION.. TEXT_USE_COMMANDS);
end

-- **************************************************************************
-- DESC : Handle slash commands
-- **************************************************************************
function slashCommandHandler(msg)
  debugMessage("Received slash command: "..msg, 0);
  
  -- handles slash commands
  msg = string.lower(msg)
  if(msg == CMD_VERSION) then
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorYellow .. VERSION_TEXT .. REVISION .. VERSION_WOWVERSION);
  elseif(msg == CMD_RELOADUI or msg == CMD_RL) then
    ReloadUI();
  elseif(msg == "debug") then
    showCurrentPlayerData();
  elseif(msg == CMD_SHOW or msg == CMD_HIDE) then
    GS_CharFrame_Toggle();
  elseif(msg == CMD_UPDATE) then
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorYellow .. TEXT_UPDATING_GEAR);
    updateGearScore("player", 1);
--  elseif(msg == "showdb") then
-- TODO    GearStat_ShowDB();
  else
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorOrange .. CMD_TEXT_HEADLINE);
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorYellow .. CMD_TEXT_VERSION);
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorYellow .. CMD_TEXT_UPDATE);
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorYellow .. CMD_TEXT_SHOW);
    DEFAULT_CHAT_FRAME:AddMessage("|c".. colorYellow .. CMD_TEXT_RL);
  end
end

-- **************************************************************************
-- DESC : Update cache after <GS_UpdateDelay> seconds
-- **************************************************************************
function GS_OnUpdate(_, elapsed)
  debugMessage("Trying to update gear cache", 0);
  
  if (elapsed == nil ) then
    elapsed = 0.01
  end
  timeCounter = timeCounter + elapsed
  if (timeCounter >= updateDelay and cycleNumber == 0) then
    debugMessage("first update!", 0)

    -- For TitanPanel support
    TitanPanelButton_UpdateButton(TITAN_GS_ID);
    TitanPanelButton_UpdateTooltip(self);

    timeCounter = 0
    cycleNumber = 1;
  end
  if (timeCounter >= updateDelay and cycleNumber == 1) then
    debugMessage("second update! - updating gear, time-counter: ".. timeCounter, 0)
    updateGearScore("player", 1);
    timeCounter = 0
    updateFrame:SetScript("OnUpdate", nil)
  end
end

-- **************************************************************************
-- DESC : Update database with player stats
-- **************************************************************************
function updateGearScore(unit, override)
  debugMessage("Updating unit: "..unit.." - override: "..override, 0);

  if ((UnitExists(unit) and UnitIsPlayer(unit)) or override == 1) then
    local name = UnitName(unit);
    debugMessage("Updating data for "..name, 0);
    
    GS.currentPlayer = {};
    GS.currentPlayer.realmName = GetRealmName();
    GS.currentPlayer.playerName = UnitName(unit);
    GS.currentPlayer.playerLevel = UnitLevel(unit);
    GS.currentPlayer.class = UnitClass(unit);
    GS.currentPlayer.gender = UnitSex(unit);
    GS.currentPlayer.race = UnitRace(unit);
    GS.currentPlayer.guild = GetGuildInfo(unit);
    GS.currentPlayer.faction = UnitFactionGroup(unit);
    if(GS.currentPlayer.guild == nil) then
      GS.currentPlayer.guild = TEXT_NO_GUILD;
    end
    GS.currentPlayer.twoHandWeapon = false;
    updateCurrentPlayerProfessions(unit);
    updateCurrentPlayerItemList(unit);
    GS.currentPlayer.recordedTime = time();
    addPlayerRecord(GS.currentPlayer);
    
    if(unit ~= GS_TEXT_PLAYER) then
      GS.currentPlayer = getPlayerRecord(UnitName(GS_TEXT_PLAYER));
    end
  end
end

-- **************************************************************************
-- DESC : Add player record to Data
-- **************************************************************************
function addPlayerRecord(playerRecord)
  -- will check if player exists if not adds player to array.
  if (playerRecord ~= nil) then
    if(GS.Data[GS.thisRealm][playerRecord.playerName] == nil) then
      GS.Data[GS.thisRealm][playerRecord.playerName] = {};
    end
    debugMessage("Adding player record: "..playerRecord.playerName.." to saved variables", 0 )
    GS.Data[GS.thisRealm][playerRecord.playerName] = playerRecord;
    GS.Data.lastUpdated = time();
  end
end

-- **************************************************************************
-- DESC : return the player record from variables
-- **************************************************************************
function getPlayerRecord(playerName, currentPlayer)
  if (playerName == nil) then
    return nil;
  end
  if(currentPlayer == 1) then
    return GS.currentPlayer
  end
  local record = GS.Data[GS.thisRealm][playerName];
  
  return record;
end

-- **************************************************************************
-- DESC : Update currentPlayers professions
-- **************************************************************************
function updateCurrentPlayerProfessions(unit)
  --- TODO fix professions for classic
  if(GSaddOn.isClassic) then
    return
  end

  if(unit == GS_TEXT_PLAYER) then
    GS.currentPlayer.professions = {}
  
    prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
    if(prof1) then
      name1, texture1, rank1, maxRank1, numSpells1, spelloffset1, skillLine1, rankModifier1 = GetProfessionInfo(prof1)
      debugMessage("\nProfession 1:\nName: "..name1.."\nTexture: "..texture1.."\nRank: "..rank1.."\nMax rank: "..maxRank1.."\nNum. spells: "..numSpells1.."\nSpellOffset: "..spelloffset1.."\nSkill-line: "..skillLine1.."\nRankModifier: "..rankModifier1, 0)
      GS.currentPlayer.professions.profession1 = {};
      GS.currentPlayer.professions.profession1.name = name1;
      GS.currentPlayer.professions.profession1.rank = rank1;
      GS.currentPlayer.professions.profession1.rankModifier = rankModifier1;
      GS.currentPlayer.professions.profession1.maxRank = maxRank1;
    end
    if(prof2) then
      name2, texture2, rank2, maxRank2, numSpells2, spelloffset2, skillLine2, rankModifier2 = GetProfessionInfo(prof2)
      debugMessage("\nProfession 2:\nName: "..name2.."\nTexture: "..texture2.."\nRank: "..rank2.."\nMax rank: "..maxRank2.."\nNum. spells: "..numSpells2.."\nSpellOffset: "..spelloffset2.."\nSkill-line: "..skillLine2.."\nRankModifier: "..rankModifier2, 0)
      GS.currentPlayer.professions.profession2 = {};
      GS.currentPlayer.professions.profession2.name = name2;
      GS.currentPlayer.professions.profession2.rank = rank2;
      GS.currentPlayer.professions.profession2.rankModifier = rankModifier2;
      GS.currentPlayer.professions.profession2.maxRank = maxRank2;
    end
    if(archaeology) then
      name3, texture3, rank3, maxRank3, numSpells3, spelloffset3, skillLine3, rankModifier3 = GetProfessionInfo(archaeology)
      debugMessage("\nArchaeology:\nName: "..name3.."\nTexture: "..texture3.."\nRank: "..rank3.."\nMax rank: "..maxRank3.."\nNum. spells: "..numSpells3.."\nSpellOffset: "..spelloffset3.."\nSkill-line: "..skillLine3.."\nRankModifier: "..rankModifier3, 0)
      GS.currentPlayer.professions.archaeology = {};
      GS.currentPlayer.professions.archaeology.name = name3;
      GS.currentPlayer.professions.archaeology.rank = rank3;
      GS.currentPlayer.professions.archaeology.rankModifier = rankModifier3;
      GS.currentPlayer.professions.archaeology.maxRank = maxRank3;
    end
    if(fishing) then
      name4, texture4, rank4, maxRank4, numSpells4, spelloffset4, skillLine4, rankModifier4 = GetProfessionInfo(fishing)
      debugMessage("\nFishing:\nName: "..name4.."\nTexture: "..texture4.."\nRank: "..rank4.."\nMax rank: "..maxRank4.."\nNum. spells: "..numSpells4.."\nSpellOffset: "..spelloffset4.."\nSkill-line: "..skillLine4.."\nRankModifier: "..rankModifier4, 0)
      GS.currentPlayer.professions.fishing = {};
      GS.currentPlayer.professions.fishing.name = name4;
      GS.currentPlayer.professions.fishing.rank = rank4;
      GS.currentPlayer.professions.fishing.rankModifier = rankModifier4;
      GS.currentPlayer.professions.fishing.maxRank = maxRank4;    
    end
    if(cooking) then
      name5, texture5, rank5, maxRank5, numSpells5, spelloffset5, skillLine5, rankModifier5 = GetProfessionInfo(cooking)
      debugMessage("\nCooking:\nName: "..name5.."\nTexture: "..texture5.."\nRank: "..rank5.."\nMax rank: "..maxRank5.."\nNum. spells: "..numSpells5.."\nSpellOffset: "..spelloffset5.."\nSkill-line: "..skillLine5.."\nRankModifier: "..rankModifier5, 0)
      GS.currentPlayer.professions.cooking = {};
      GS.currentPlayer.professions.cooking.name = name5;
      GS.currentPlayer.professions.cooking.rank = rank5;
      GS.currentPlayer.professions.cooking.rankModifier = rankModifier5;
      GS.currentPlayer.professions.cooking.maxRank = maxRank5;    
    end
  end
end

-- **************************************************************************
-- DESC : Updates GS.currentPlayer.itemList, GS.currentPlayer.totalItemLevel, GS.currentPlayer.totalItemScore,
--                GS.currentPlayer.averageItemLevel, GS.currentPlayer.averageItemScore
-- **************************************************************************
function updateCurrentPlayerItemList(unit)
  debugMessage("Updating gear", 0);
  local totalItemScore = 0;
  local totalItemLevel = 0;
  local averageItemScore = 0;
  local averageItemLevel = 0;
  local minItemLevel = 0;
  local maxItemLevel = 0;
  local twoHandWeapon = false;
  local unitLevel = UnitLevel(unit);
  local missingText = "";
  local legionArtifact = 0;
  GS.currentPlayer.itemList = {};
  local itemLevel = 0;
  
  for index in ipairs(GEARLIST) do
    GEARLIST[index].id = GetInventorySlotInfo(GEARLIST[index].name);
    local slotLink = GetInventoryItemLink(unit, GEARLIST[index].id);
    if (slotLink ~= nil) then
      local itemName, itemLink, itemRarity, iLvl, _, itemType, itemSubType = GetItemInfo(slotLink);
      if(itemLink ~= nil and (itemType == GEARTYPE_ARMOR or itemType == GEARTYPE_WEAPON)) then
        local actualItemLevel, _, _ = GetDetailedItemLevelInfo(itemLink)
        iLvl = actualItemLevel
      end
      local itemScore = 0;
      legionArtifact = legionArtifact + isLegionArtifactWeapon(GEARLIST[index].desc, itemName);

      if(GEARLIST[index].minLevel >= 0 and itemLink) then
        local enchantScore, enchantText = getItemEnchantScore(slotLink)
        local gemScore, gemText = getItemGemScore(slotLink)
        itemScore = getItemScore(slotLink) + enchantScore + gemScore

        -- compensate for 2H weapons
        if(isWeaponTwoHand(itemSubType) == 1) then
          twoHandWeapon = true;
        end
        -- compensate for warrior with dual 2H weapons equipped, show both
        if (twoHandWeapon and GEARLIST[index].name == GEARSLOT_OFFHAND) then
          twoHandWeapon = false;
        end

        missingText = missingText..enchantText..gemText;
        totalItemScore = totalItemScore + itemScore;
        -- fix for item-levels with '+', eg. 385+
        string.gsub(iLvl, "+", "")
        itemLevel = tonumber(iLvl)

        totalItemLevel = totalItemLevel + itemLevel;
        if (minItemLevel == 0 and itemLevel > 0 and GEARLIST[index].minLevel > 0) then
          minItemLevel = itemLevel
        elseif(itemLevel < minItemLevel and itemLevel > 0 and GEARLIST[index].minLevel > 0) then
          minItemLevel = itemLevel
        end
        if(itemLevel > maxItemLevel) then
          maxItemLevel = itemLevel
        end
        debugMessage("itemName: "..itemName.." - score: "..itemScore, 0)

        -- Update cache
        GS.currentPlayer.itemList[GEARLIST[index].name] = {};
        GS.currentPlayer.itemList[GEARLIST[index].name].itemName = itemName;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemLink = itemLink;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemRarity = itemRarity;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemLevel = itemLevel;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemType = itemType;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemSubType = itemSubType;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemScore = itemScore;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemMissingText = missingText;
        GS.currentPlayer.itemList[GEARLIST[index].name].levelColor = colorBlue;
        missingText = "";
      else -- set passive legion artifact itemSlot to empty
        GS.currentPlayer.itemList[GEARLIST[index].name] = {};
        GS.currentPlayer.itemList[GEARLIST[index].name].itemName = TEXT_NO_ITEM_EQUIPPED;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemLink = "";
        GS.currentPlayer.itemList[GEARLIST[index].name].itemRarity = "";
        GS.currentPlayer.itemList[GEARLIST[index].name].itemLevel = 0;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemType = "";
        GS.currentPlayer.itemList[GEARLIST[index].name].itemSubType = "";
        GS.currentPlayer.itemList[GEARLIST[index].name].itemScore = 0;
        GS.currentPlayer.itemList[GEARLIST[index].name].itemMissingText = "";
        GS.currentPlayer.itemList[GEARLIST[index].name].levelColor = colorBlue;
      end
    else
      GS.currentPlayer.itemList[GEARLIST[index].name] = {};
      GS.currentPlayer.itemList[GEARLIST[index].name].itemName = TEXT_NO_ITEM_EQUIPPED;
      GS.currentPlayer.itemList[GEARLIST[index].name].itemLink = "";
      GS.currentPlayer.itemList[GEARLIST[index].name].itemRarity = "";
      GS.currentPlayer.itemList[GEARLIST[index].name].itemLevel = 0;
      GS.currentPlayer.itemList[GEARLIST[index].name].itemType = "";
      GS.currentPlayer.itemList[GEARLIST[index].name].itemSubType = "";
      GS.currentPlayer.itemList[GEARLIST[index].name].itemScore = 0;
      GS.currentPlayer.itemList[GEARLIST[index].name].itemMissingText = "";
      GS.currentPlayer.itemList[GEARLIST[index].name].levelColor = colorBlue;
    end
  end

  -- Calculate score
  local itemCount = getMaxItemsForLevel(unitLevel);

  -- compensate for two hand weapon
  if(twoHandWeapon == true or legionArtifact > 0) then
    itemCount = itemCount -1;
    GS.currentPlayer.twoHandWeapon = true;
  end
  
  averageItemLevel = totalItemLevel/itemCount;
  averageItemScore = totalItemScore/itemCount;

  -- Update cache
  for index in ipairs(GEARLIST) do
    if (GS.currentPlayer.itemList[GEARLIST[index].name].itemName ~= TEXT_NO_ITEM_EQUIPPED) then
      debugMessage("itemName: "..GS.currentPlayer.itemList[GEARLIST[index].name].itemName, 0)
      debugMessage("itemLevel: "..GS.currentPlayer.itemList[GEARLIST[index].name].itemLevel, 0)
      debugMessage("averageItemLevel: "..averageItemLevel, 0)
      GS.currentPlayer.itemList[GEARLIST[index].name].levelColor =
                                       getLevelColor(GS.currentPlayer.itemList[GEARLIST[index].name].itemLevel, averageItemLevel);
    end
  end
  GS.currentPlayer.averageItemScore = averageItemScore;
  GS.currentPlayer.averageItemLevel = averageItemLevel;
  GS.currentPlayer.minItemLevel = minItemLevel;
  GS.currentPlayer.maxItemLevel = maxItemLevel;
  GS.currentPlayer.totalItemScore = totalItemScore;
  GS.currentPlayer.totalItemLevel = totalItemLevel;
  
  debugMessage("Update complete", 0)
end

-- **************************************************************************
-- DESC : Returns 1, if the weapon is a legion artifact (two hand equipped as 1-hand).
--         in order to only show ilvl and score for 1 slot, main or offhand, depending on the weapon
-- **************************************************************************
function isLegionArtifactWeapon(itemSlot, itemName)
  if(itemSlot and itemName and (itemSlot == GEAR_OFFHAND or itemSlot == GEAR_MAINHAND)) then
    debugMessage("Legion artifact, slot: "..itemSlot.." - itemName: "..itemName, 0)
    for index in ipairs(ARTIFACT_WEAPONS) do
      if (itemName == ARTIFACT_WEAPONS[index].text) then
        debugMessage("Legion weapon found", 0)
        return 1;
      end
    end
  end
  return 0;
end

-- **************************************************************************
-- DESC : Returns score for enchants, text if enchant is missing and possible
-- **************************************************************************
function getItemEnchantScore(itemLink)
  return 0, ""
  
  --TODO EnchantScore
end


-- **************************************************************************
-- DESC : Returns score for gems, text if gem is possible and missing
-- **************************************************************************
function getItemGemScore(itemLink)
  return 0, ""
  
  --TODO GemScore
end


-- **************************************************************************
-- DESC : Returns the combined stats for the item, for the stats defined in STATTYPES
-- **************************************************************************
function getItemScore(itemLink)
  local score = 0

  -- Create the tooltip:
  local scantip = CreateFrame("GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate")
  scantip:SetOwner(UIParent, "ANCHOR_NONE")

  -- Pass the item link to the tooltip:
  scantip:SetHyperlink(itemLink)

  -- Scan the tooltip:
  for i = 2, scantip:NumLines() do -- Line 1 is always the name so you can skip it.
    local text = _G["MyScanningTooltipTextLeft"..i]:GetText()
    debugMessage("debug text: "..text.." - numlines: "..i.."/"..scantip:NumLines(), 0)

    for index in ipairs(STATTYPES) do
      local statText = string.match(text, " "..STATTYPES[index].text)
      if(statText) then
        debugMessage("STATTYPE: "..STATTYPES[index].text.." - text: "..text, 0)
        debugMessage("STATTYPE: "..STATTYPES[index].text.." - StatText: "..statText, 0)
        text = string.gsub(text, statText, "")
        text = string.gsub(text, "+", "")
        text = string.gsub(text, ",", "")
        local number = tonumber(text)
        if not number then
          number = 0
        end
        score = score + number
        debugMessage("Number: "..number.." - Score: "..score, 0)
      end
    end
  end
  return score;
end

-- **************************************************************************
-- DESC : Returns 1 if the itemSubType is a twohand weapon
-- **************************************************************************
function isWeaponTwoHand(itemSubType)
  debugMessage("itemSubType: "..itemSubType, 0)

  for index in ipairs(TWOHAND_WEAPONS) do
    debugMessage("Loop - itemSubType: "..itemSubType, 0)
    debugMessage("Loop - match value: "..TWOHAND_WEAPONS[index].text, 0)
    if (itemSubType == TWOHAND_WEAPONS[index].text) then
      debugMessage("Match found", 0)
      return 1;
    end
  end
  
  return 0;
end

-- **************************************************************************
-- DESC : Returns maximum possible gear items for the given level
-- **************************************************************************
function getMaxItemsForLevel(level)
  local count = 0;
  for index in ipairs(GEARLIST) do
    if (GEARLIST[index].minLevel > 0 and GEARLIST[index].minLevel <= level) then
      count = count +1;
    end 
  end
  debugMessage("GetMaxItemsForLevel: "..level.." is returning: "..count, 0);
  return count;
end

-- **************************************************************************
-- DESC : Get color for tooltip, based on the players average ilvl and the items iLlv
-- **************************************************************************
function getLevelColor(itemLevel, playerAverageItemLevel)

  if (itemLevel == nil or playerAverageItemLevel == nil) then
    return colorBlue;
  end

  local iLevelDiff = itemLevel-playerAverageItemLevel;
  debugMessage("iLevelDiff: ".. iLevelDiff, 0)

  return calculateColor(iLevelDiff);
end

-- **************************************************************************
-- DESC :Get  color for tooltip, based on the difference in ilvl for the players equipped gear
-- colors and limits for colors defined in variables.lua TOTAL_GEAR_ILVL_COLOR_LIMIT
-- the function is used by TitanGearStatistics
-- **************************************************************************
function calculateColor(iLevelDiff)
  local color = colorGrey;

  if (iLevelDiff == nil) then
    return colorBlue;
  end

  for index in ipairs(TOTAL_GEAR_ILVL_COLOR_LIMIT) do
    if (iLevelDiff > TOTAL_GEAR_ILVL_COLOR_LIMIT[index].limit) then
      return TOTAL_GEAR_ILVL_COLOR_LIMIT[index].color;
    end
  end

  return color;
end

-- **************************************************************************
-- DESC : DEBUG, show detailed information
-- **************************************************************************
function showCurrentPlayerData()
  -- write currentPlayer data to chat
  DEFAULT_CHAT_FRAME:AddMessage("Realm: "..GS.currentPlayer.realmName);
  DEFAULT_CHAT_FRAME:AddMessage("Faction: "..GS.currentPlayer.faction);
  DEFAULT_CHAT_FRAME:AddMessage("Player name: "..GS.currentPlayer.playerName);
  DEFAULT_CHAT_FRAME:AddMessage("Player level: "..GS.currentPlayer.playerLevel);
  DEFAULT_CHAT_FRAME:AddMessage("Class: "..GS.currentPlayer.class);
  DEFAULT_CHAT_FRAME:AddMessage("Gender: "..GS.currentPlayer.gender);
  DEFAULT_CHAT_FRAME:AddMessage("Race: "..GS.currentPlayer.race);
  DEFAULT_CHAT_FRAME:AddMessage("Guild: "..GS.currentPlayer.guild);
  DEFAULT_CHAT_FRAME:AddMessage("totalItemLevel: "..GS.currentPlayer.totalItemLevel);
  DEFAULT_CHAT_FRAME:AddMessage("totalItemScore: "..GS.currentPlayer.totalItemScore);
  DEFAULT_CHAT_FRAME:AddMessage("averageItemLevel: "..GS.currentPlayer.averageItemLevel);
  DEFAULT_CHAT_FRAME:AddMessage("averageItemScore: "..GS.currentPlayer.averageItemScore);
  DEFAULT_CHAT_FRAME:AddMessage("minItemLevel: "..GS.currentPlayer.minItemLevel);
  DEFAULT_CHAT_FRAME:AddMessage("maxItemLevel: "..GS.currentPlayer.maxItemLevel);
  DEFAULT_CHAT_FRAME:AddMessage("recordedTime: "..GS.currentPlayer.recordedTime);
  DEFAULT_CHAT_FRAME:AddMessage("twohand: "..tostring(GS.currentPlayer.twoHandWeapon));
  for index in ipairs(GEARLIST) do
    if(GS.currentPlayer.itemList[GEARLIST[index].name].itemName) then
      DEFAULT_CHAT_FRAME:AddMessage("itemList: "..GS.currentPlayer.itemList[GEARLIST[index].name].itemName);
    end
  end
  
  DEFAULT_CHAT_FRAME:AddMessage("Data.Version: "..GS.Data.version);
end
