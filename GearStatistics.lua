-- *** Version information
GS_VERSION = "10.0.2";

-- *** Used colors ***
GS_colorRed    = "ffff0000"; -- red DEBUG text color and red gear (best)
GS_colorOrange = "ffff8000"; -- orange chat headline color and orange gear
GS_colorYellow = "ffffff00"; -- yellow chat text color and yellow gear
GS_colorGreen  = "ff1eff00"; -- green gear, uncommon
GS_colorWhite  = "ffffffff"; -- white gear, common
GS_colorGrey   = "ff9d9d9d"; -- grey gear (worst)
GS_colorBlue   = "ff20d0ff"; -- unknown gear, light blue
GS_colorNone   = "ff808080";  -- default border color for gearslots on CharFrame
GS_colorBlack  = "ff000000";
GS_colorDarkBlue = "ff0070dd";  -- item ITEM_RARITY rare dark blue
GS_colorPurple   = "ffa335ee";  -- item ITEM_RARITY epic purple
GS_colorGold     = "ffe5cc80";  -- item ITEM_RARITY artifact/heirloom gold

-- *** Local variables
local GS_showDebug = 0; -- 1 = show debugs in general chat, 0 turns off debug
local initialized = false;
local GS_Cycle = 0;
local GS_TimeCounter = 0;
local GS_UpdateFrame = CreateFrame("frame");
local GS_UpdateDelay = 2;
local lastTooltipText = ""
local lastRefTooltipText1 = ""
local lastRefTooltipText2 = ""
local lastWorldMapTooltipText = ""

-- *** Functions

-- **************************************************************************
-- DESC : Debug function to print message to chat frame
-- VARS : Message = message to print to chat frame
-- **************************************************************************
function GS_Debug(Message, override)
  if (GS_showDebug == 1 or override == 1) then
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorRed.."GS: " .. Message);
  end
end

-- **************************************************************************
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
function GS_OnLoad(self)
  GS_Debug("Loading GearStatistics", 0);
  
    -- Register the events we need
  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("PLAYER_LOGOUT");
  self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
  self:RegisterEvent("PLAYER_LEVEL_UP");
end

-- **************************************************************************
-- DESC : GearStat event handler
-- **************************************************************************
function GS_OnEvent(self, event, a1, ...)

  GS_Debug("Event: "..event, 0)

  -- Handle events
  if (initialized == true and (event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_LEVEL_UP")) then
    GS_UpdatePlayer("player", 0);
    if (GS_CharFrame:IsVisible()) then
      GS_CharFrame:Hide();
      GS_CharFrame:Show();
    end
    GS_ResetTooltip();
    return;
  end
    
  if (event == "PLAYER_ENTERING_WORLD") then
    self:UnregisterEvent("PLAYER_ENTERING_WORLD");
    
    GS_Initialise();
    initialized = true;
    return;
  end

  if (event == "PLAYER_LOGOUT") then
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:UnregisterEvent("PLAYER_LEVEL_UP");
      
    GS.currentPlayer = {};
    return;
  end
end

-- **************************************************************************
-- DESC : Initialise GearStatistics
-- **************************************************************************
function GS_Initialise()
  GS_Debug("Initialising GearStatistics", 0);
  
  -- setup data block
  if (GS == nil) then
    GS = {};
    GS.currentPlayer = {};
    GS.Data = {};
  end
  if(GS.Data.version == nil or not (GS.Data.version == GS_VERSION)) then
    GS = {};
    GS.currentPlayer = {};
    GS.Data = {}; -- zap all prior history if not current version
    GS.Data.version = GS_VERSION;
    GS.Data.lastUpdated = time();
  end
  GS.thisRealm = GetRealmName();
  if(GS.Data[GS.thisRealm] == nil) then
    GS.Data[GS.thisRealm] = {};
  end
  
  -- Register our slash command
  SlashCmdList["GEARSTATISTICS"] = function(msg)
    GS_SlashCommandHandler(msg);
  end
  SLASH_GEARSTATISTICS1 = "/gs";

  GS_HookTooltips(); 
  GS_Frame:Hide();
  
  GS_UpdateFrame:SetScript("OnUpdate", GS_OnUpdate) 
  GS_Debug("slash registered", 0);
  DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorOrange..""..GS_LOADED..GS_VERSION..GS_USE_COMMANDS);

end


-- **************************************************************************
-- DESC : Handle slash commands
-- **************************************************************************
function GS_SlashCommandHandler(msg)
  GS_Debug("Received slash command: "..msg, 0);
  
  -- handles slash commands
  msg = string.lower(msg)
  if(msg == GS_CMD_VERSION) then
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorYellow..GS_VERSION_TEXT..GS_VERSION..GS_VERSION_WOWVERSION);
  elseif(msg == GS_CMD_RELOADUI or msg == GS_CMD_RL) then
    ReloadUI();
  elseif(msg == "debug") then
    GS_ShowCurrentPlayerData();
  elseif(msg == GS_CMD_SHOW or msg == GS_CMD_HIDE) then
    GS_CharFrame_Toggle();
  elseif(msg == GS_CMD_UPDATE) then
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorYellow..GS_UPDATING_GEAR);
    GS_UpdatePlayer("player", 1);
--  elseif(msg == "showdb") then
-- TODO    GearStat_ShowDB();
  else
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorOrange..GS_CMD_TEXT_HEADLINE);
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorYellow..GS_CMD_TEXT_VERSION);
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorYellow..GS_CMD_TEXT_UPDATE);
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorYellow..GS_CMD_TEXT_SHOW);
    DEFAULT_CHAT_FRAME:AddMessage("|c"..GS_colorYellow..GS_CMD_TEXT_RL);
  end
end


-- **************************************************************************
-- DESC : Update cache after <GS_UpdateDelay> seconds
-- **************************************************************************
function GS_OnUpdate(self, elapsed)
  GS_Debug("Trying to update gear cache", 0);
  
  if (elapsed == nil ) then
    elapsed = 0.01
  end
  GS_TimeCounter = GS_TimeCounter + elapsed
  if (GS_TimeCounter >= GS_UpdateDelay and GS_Cycle == 0) then
    GS_Debug("first update!", 0)
    GS_TimeCounter = 0
    GS_Cycle = 1;
  end
  if (GS_TimeCounter >= GS_UpdateDelay and GS_Cycle == 1) then
    GS_Debug("second update! - updating gear, timecounter: "..GS_TimeCounter, 0)
    GS_UpdatePlayer("player", 1);
    GS_TimeCounter = 0
    GS_UpdateFrame:SetScript("OnUpdate", nil)
  end
end

-- **************************************************************************
-- DESC : Show/hide the character window
-- **************************************************************************
function GS_CharFrame_Toggle()
  GS_Debug("Toggling Character frame", 0);

  if (GS_CharFrame:IsVisible()) then
    GS_CharFrame:Hide();
  else
    GS_CharFrame:Show();
  end
end

-- **************************************************************************
-- DESC : Update database with player stats
-- **************************************************************************
function GS_UpdatePlayer(unit, override)
  GS_Debug("Updating unit: "..unit.." - override: "..override, 0);

  if ((UnitExists(unit) and UnitIsPlayer(unit)) or override == 1) then
    local name = UnitName(unit);
    GS_Debug("Updating data for "..name, 0);
    
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
      GS.currentPlayer.guild = GS_NO_GUILD;
    end
    GS.currentPlayer.twoHandWeapon = false;
    GS_UpdateCurrentPlayerProfessions(unit);
    GS_UpdateCurrentPlayerItemList(unit);
    GS.currentPlayer.recordedTime = time();
    GS_AddPlayerRecord(GS.currentPlayer);
    
    if(unit ~= "player") then
      GS.currentPlayer = GS_GetPlayerRecord(UnitName("player"));
    end
  end
end


-- **************************************************************************
-- DESC : Add player record to Data
-- **************************************************************************
function GS_AddPlayerRecord(playerRecord)
  -- will check if player exists if not adds player to array.
  if (playerRecord ~= nil) then
    if(GS.Data[GS.thisRealm][playerRecord.playerName] == nil) then
      GS.Data[GS.thisRealm][playerRecord.playerName] = {};
    end
    GS_Debug("Adding player record: "..playerRecord.playerName.." to saved variables", 0 )
    GS.Data[GS.thisRealm][playerRecord.playerName] = playerRecord;
    GS.Data.lastUpdated = time();
  end
end


-- **************************************************************************
-- DESC : return the player record from variables
-- **************************************************************************
function GS_GetPlayerRecord(playerName, currentPlayer)
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
function GS_UpdateCurrentPlayerProfessions(unit)
  if(unit == "player") then
    GS.currentPlayer.professions = {}
  
    prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
    if(prof1) then
      name1, texture1, rank1, maxRank1, numSpells1, spelloffset1, skillLine1, rankModifier1 = GetProfessionInfo(prof1)
      GS_Debug("\nProfession 1:\nName: "..name1.."\nTexture: "..texture1.."\nRank: "..rank1.."\nMax rank: "..maxRank1.."\nNum. spells: "..numSpells1.."\nSpellOffset: "..spelloffset1.."\nSkillline: "..skillLine1.."\nRankModifier: "..rankModifier1, 0)
      GS.currentPlayer.professions.profession1 = {};
      GS.currentPlayer.professions.profession1.name = name1;
      GS.currentPlayer.professions.profession1.rank = rank1;
      GS.currentPlayer.professions.profession1.rankModifier = rankModifier1;
      GS.currentPlayer.professions.profession1.maxRank = maxRank1;
    end
    if(prof2) then
      name2, texture2, rank2, maxRank2, numSpells2, spelloffset2, skillLine2, rankModifier2 = GetProfessionInfo(prof2)
      GS_Debug("\nProfession 2:\nName: "..name2.."\nTexture: "..texture2.."\nRank: "..rank2.."\nMax rank: "..maxRank2.."\nNum. spells: "..numSpells2.."\nSpellOffset: "..spelloffset2.."\nSkillline: "..skillLine2.."\nRankModifier: "..rankModifier2, 0)
      GS.currentPlayer.professions.profession2 = {};
      GS.currentPlayer.professions.profession2.name = name2;
      GS.currentPlayer.professions.profession2.rank = rank2;
      GS.currentPlayer.professions.profession2.rankModifier = rankModifier2;
      GS.currentPlayer.professions.profession2.maxRank = maxRank2;
    end
    if(archaeology) then
      name3, texture3, rank3, maxRank3, numSpells3, spelloffset3, skillLine3, rankModifier3 = GetProfessionInfo(archaeology)
      GS_Debug("\nArchaeology:\nName: "..name3.."\nTexture: "..texture3.."\nRank: "..rank3.."\nMax rank: "..maxRank3.."\nNum. spells: "..numSpells3.."\nSpellOffset: "..spelloffset3.."\nSkillline: "..skillLine3.."\nRankModifier: "..rankModifier3, 0)
      GS.currentPlayer.professions.archaeology = {};
      GS.currentPlayer.professions.archaeology.name = name3;
      GS.currentPlayer.professions.archaeology.rank = rank3;
      GS.currentPlayer.professions.archaeology.rankModifier = rankModifier3;
      GS.currentPlayer.professions.archaeology.maxRank = maxRank3;
    end
    if(fishing) then
      name4, texture4, rank4, maxRank4, numSpells4, spelloffset4, skillLine4, rankModifier4 = GetProfessionInfo(fishing)
      GS_Debug("\nFishing:\nName: "..name4.."\nTexture: "..texture4.."\nRank: "..rank4.."\nMax rank: "..maxRank4.."\nNum. spells: "..numSpells4.."\nSpellOffset: "..spelloffset4.."\nSkillline: "..skillLine4.."\nRankModifier: "..rankModifier4, 0)
      GS.currentPlayer.professions.fishing = {};
      GS.currentPlayer.professions.fishing.name = name4;
      GS.currentPlayer.professions.fishing.rank = rank4;
      GS.currentPlayer.professions.fishing.rankModifier = rankModifier4;
      GS.currentPlayer.professions.fishing.maxRank = maxRank4;    
    end
    if(cooking) then
      name5, texture5, rank5, maxRank5, numSpells5, spelloffset5, skillLine5, rankModifier5 = GetProfessionInfo(cooking)
      GS_Debug("\nCooking:\nName: "..name5.."\nTexture: "..texture5.."\nRank: "..rank5.."\nMax rank: "..maxRank5.."\nNum. spells: "..numSpells5.."\nSpellOffset: "..spelloffset5.."\nSkillline: "..skillLine5.."\nRankModifier: "..rankModifier5, 0)
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
function GS_UpdateCurrentPlayerItemList(unit)
  GS_Debug("Updating gear", 0);
  local totalItemScore = 0;
  local totalItemLevel = 0;
  local averageItemScore = 0;
  local averageItemLevel = 0;
  local twoHandWeapon = false;
  local unitLevel = UnitLevel(unit);
  local missingText = "";
  local legionArtifact = 0;
  GS.currentPlayer.itemList = {};
  
  for index in ipairs(GS_GEARLIST) do 
    GS_GEARLIST[index].id = GetInventorySlotInfo(GS_GEARLIST[index].name);
    local slotLink = GetInventoryItemLink(unit, GS_GEARLIST[index].id);
    if (slotLink ~= nil) then
      local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType = GetItemInfo(slotLink);
      local itemScore = 0;
      legionArtifact = legionArtifact + GS_isLegionArtifactWeapon(GS_GEARLIST[index].desc, itemName);

      if(GS_GEARLIST[index].minLevel >= 0 and itemLink and GS_isLegionArtifactWeapon(GS_GEARLIST[index].desc, itemName) == 0) then 
        itemLevel = GS_GetItemLevel(itemLink)
        local enchantScore, enchantText = GS_GetItemEnchantScore(slotLink)
        local gemScore, gemText = GS_GetItemGemScore(slotLink)
        local itemScore = GS_GetItemScore(slotLink) + enchantScore + gemScore
      
        -- compensate for 2H weapons
        if(GS_isTwoHand(itemSubType) == 1) then
          -- compensate for warrior with dual 2H weapons equipped
          if(twoHandWeapon == true) then
            twoHandWeapon = false;
          else    
            twoHandWeapon = true;
          end
        end

        missingText = missingText..enchantText..gemText;
        totalItemScore = totalItemScore + itemScore;
        totalItemLevel = totalItemLevel + itemLevel;

        -- Update cache
        GS.currentPlayer.itemList[GS_GEARLIST[index].name] = {};
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemName = itemName;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLink = itemLink;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemRarity = itemRarity;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLevel = itemLevel;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemType = itemType;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemSubType = itemSubType;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemScore = itemScore;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemMissingText = missingText;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].levelColor = GS_colorBlue;
        missingText = "";
      else -- set passive legion artifact itemSlot to empty
        GS.currentPlayer.itemList[GS_GEARLIST[index].name] = {};
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemName = GS_NO_ITEM_EQUIPPED;
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLink = "";
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemRarity = "";
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLevel = "";
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemType = "";
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemSubType = "";
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemScore = "";
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemMissingText = "";
        GS.currentPlayer.itemList[GS_GEARLIST[index].name].levelColor = GS_colorBlue;
      end
    else
      GS.currentPlayer.itemList[GS_GEARLIST[index].name] = {};
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemName = GS_NO_ITEM_EQUIPPED;
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLink = "";
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemRarity = "";
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLevel = "";
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemType = "";
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemSubType = "";
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemScore = "";
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemMissingText = "";
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].levelColor = GS_colorBlue;
    end
  end

  -- Calculate score
  local itemCount = GS_GetMaxItemsForLevel(unitLevel);

  -- compensate for two hand weapon
  if(twoHandWeapon == true or legionArtifact == 1) then
    itemCount = itemCount -1;
    GS.currentPlayer.twoHandWeapon = true;
  end
  
  averageItemLevel = totalItemLevel/itemCount;
  averageItemScore = totalItemScore/itemCount;

  -- Update cache
  for index in ipairs(GS_GEARLIST) do 
    if (GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemName ~= GS_NO_ITEM_EQUIPPED) then
      GS_Debug("itemName: "..GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemName, 0)
      GS_Debug("itemLevel: "..GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLevel, 0)
      GS_Debug("averageItemLevel: "..averageItemLevel, 0)
      GS.currentPlayer.itemList[GS_GEARLIST[index].name].levelColor = 
                                       GS_GetLevelColor(GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemLevel, averageItemLevel);
    end
  end
  GS.currentPlayer.averageItemScore = averageItemScore;
  GS.currentPlayer.averageItemLevel = averageItemLevel;
  GS.currentPlayer.totalItemScore = totalItemScore;
  GS.currentPlayer.totalItemLevel = totalItemLevel;
  
  GS_Debug("Update complete", 0)
end


-- **************************************************************************
-- DESC : Returns true, if the weapon is a legion artifact (two hand equipped as 1-hand). 
--         in order to only show ilvl and score for 1 slot, main or offhand, depending on the weapon
-- **************************************************************************
function GS_isLegionArtifactWeapon(itemSlot, itemName) 
  
  GS_Debug("Legion artifact, slot: "..itemSlot.." - itemName: "..itemName, 0)
  
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_DH_HAVOC) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_DH_VENGEANCE) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_DRUID_FERAL) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_DRUID_GUARDIAN) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_SHAMAN_ELEMENTAL) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_SHAMAN_ENHANCEMENT) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_SHAMAN_RESTORATION) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_MAGE_FIRE) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_MAGE_FIRE) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_MAINHAND and itemName == GS_PALY_PROT) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_MAINHAND and itemName == GS_WARLOCK_DEMONOLOGY) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_MONK_WINDWALKER) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_WARRIOR_FURY) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_MAINHAND and itemName == GS_WARRIOR_PROTECTION) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_PRIEST_SHADOW) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_ROGUE_SUBTLETY) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_ROGUE_OUTLAW) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_ROGUE_ASSASSINATION) then
    return 1;
  end
  if(itemSlot and itemName and itemSlot == GS_OFFHAND and itemName == GS_DK_FROST) then
    return 1;
  end

  return 0;
end


-- **************************************************************************
-- DESC : Returns the itemLevel
-- **************************************************************************
function GS_GetItemLevel(itemLink)
  GS_Debug("get itemlevel for "..itemLink, 0)
  -- Construct your search pattern 
  local searchstring = "Item Level "

  -- Create the tooltip:
  local scantip = CreateFrame("GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate")
  scantip:SetOwner(UIParent, "ANCHOR_NONE")
  
  -- Pass the item link to the tooltip:
  scantip:SetHyperlink(itemLink)
  
  -- Scan the tooltip:
  for i = 2, scantip:NumLines() do -- Line 1 is always the name so you can skip it.
    local text = _G["MyScanningTooltipTextLeft"..i]:GetText()
    GS_Debug("debug text: "..text.." - numlines: "..i.."/"..scantip:NumLines(), 0)

    local match = strmatch(text, searchstring)
    if match and match ~= "" then
      local itemLevel = gsub(text, searchstring, "", 1)
      GS_Debug("debug itemlevelLine: "..itemLevel, 0)
      return itemLevel
    end
  end

  return 0
end


-- **************************************************************************
-- DESC : Returns score for enchants, text if enchant is missing and possible
-- **************************************************************************
function GS_GetItemEnchantScore(itemLink)
  return 0, ""
  
  --TODO EnchantScore
end


-- **************************************************************************
-- DESC : Returns score for gems, text if gem is possible and missing
-- **************************************************************************
function GS_GetItemGemScore(itemLink)
  return 0, ""
  
  --TODO GemScore
end


-- **************************************************************************
-- DESC : Returns the combined stats for the item, int+agi+sta+armor+crit+haste+mastery+versatility
-- **************************************************************************
function GS_GetItemScore(itemLink)
  local score = 0

  -- Create the tooltip:
  local scantip = CreateFrame("GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate")
  scantip:SetOwner(UIParent, "ANCHOR_NONE")

  -- Pass the item link to the tooltip:
  scantip:SetHyperlink(itemLink)

  -- Scan the tooltip:
  for i = 2, scantip:NumLines() do -- Line 1 is always the name so you can skip it.
    local text = _G["MyScanningTooltipTextLeft"..i]:GetText()
    GS_Debug("debug text: "..text.." - numlines: "..i.."/"..scantip:NumLines(), 0)

    for index in ipairs(GS_STATTYPES) do
      for w in gmatch(text, "([%d,%d-]+)"..GS_STATTYPES[index].text) do
        w = gsub(w, ",", "", 1)
        local num = tonumber(w)
        if(num) then
          score = score + num
        end
        GS_Debug("text: "..text.." - w: "..w.." - score: "..score, 0)
      end
    end    
  end
  return score
end

-- **************************************************************************
-- DESC : Returns 1 if the itemSubType is a twohand weapon
-- **************************************************************************
function GS_isTwoHand(itemSubType)
  GS_Debug("itemSubType: "..itemSubType, 0)
  if(itemSubType == GS_TWOHAND_AXE or itemSubType == GS_TWOHAND_MACE or itemSubType == GS_TWOHAND_SWORD 
          or itemSubType == GS_STAVES or itemSubType == GS_POLEARMS or itemSubType == GS_BOWS 
          or itemSubType == GS_CROSSBOWS or itemSubType == GS_GUNS or itemSubType == GS_FISHING) then
    return 1;
  end
  
  return 0;
end

-- **************************************************************************
-- DESC : Returns maximum possible gear items for the given level
-- **************************************************************************
function GS_GetMaxItemsForLevel(level)
  local count = 0;
  for index in ipairs(GS_GEARLIST) do 
    if (GS_GEARLIST[index].minLevel > 0 and GS_GEARLIST[index].minLevel <= level) then
      count = count +1;
    end 
  end
  GS_Debug("GetMaxItemsForLevel: "..level.." is returning: "..count, 0);
  return count;
end

-- **************************************************************************
-- DESC : Get color for tooltip, based on the players AiLlv and the items iLlv
-- Red:    + 20 iLevels
-- Orange: + 10 iLevels
-- Yellow: + 3  iLevels
-- Green:  - 3 -> +3 (average)
-- White:  - 3 iLevels
-- Grey:   - 10 iLevels
-- **************************************************************************
function GS_GetLevelColor(itemLevel, playerAverageItemLevel)
  local color = GS_colorBlue;

  if (itemLevel == nil or playerAverageItemLevel == nil) then
    return GS_colorBlue;
  end
  
  -- fix for itemlevels with '+', eg. 385+
  string.gsub(itemLevel, "+", "")
  
--  local iLevelDiff = ((itemLevel-playerAverageItemLevel)/playerAverageItemLevel)*100;
  local iLevelDiff = (itemLevel-playerAverageItemLevel);
  GS_Debug("iLevelDiff: "..iLevelDiff, 0)
  if (iLevelDiff >= 20) then
    color = GS_colorRed;
  elseif (iLevelDiff < 20 and iLevelDiff >= 10) then
    color = GS_colorOrange;
  elseif (iLevelDiff < 10 and iLevelDiff >= 3) then
    color = GS_colorYellow;
  elseif (iLevelDiff < 3 and iLevelDiff >-3) then
    color = GS_colorGreen;
  elseif (iLevelDiff <= -3 and iLevelDiff >=-10) then
    color = GS_colorWhite;
  else
    color = GS_colorGrey;
  end

  GS_Debug("Get level color for itemLevel: "..itemLevel..", playerAverageItemLevel: "..playerAverageItemLevel..", ".."|c"..color.."returning this color", 0);
  
  return color;
end 

-- **************************************************************************
-- DESC : Hook the item tooltip
-- **************************************************************************

local isTooltipDone

function GS_HookTooltips()
--  GameTooltip:HookScript("OnShow", GS_Tooltip_OnShow);
--  GameTooltip:HookScript("OnTooltipSetItem", GS_Tooltip_OnGameTooltipSetItem)
--  GameTooltip:HookScript("OnHide", GS_Tooltip_OnHide)

  GameTooltip:HookScript("OnShow", GS_setTooltip);
  GameTooltip:HookScript("OnTooltipCleared", GS_Tooltip_OnHide)  
	
--  ShoppingTooltip:HookScript("OnShow", GS_setTooltip);
--  ShoppingTooltip:HookScript("OnTooltipCleared", GS_Tooltip_OnHide)  
	
  
--  WorldMapTooltip:HookScript("OnShow", GS_WorldMapTooltip_OnShow);
--  WorldMapTooltip:HookScript("OnTooltipSetItem", GS_WorldMapTooltip_OnGameTooltipSetItem)
--  WorldMapTooltip:HookScript("OnHide", GS_WorldMapTooltip_OnHide)
  
--  ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", GS_RefTooltip1_OnRefTooltipSetItem);
--  ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", GS_RefTooltip2_OnRefTooltipSetItem);
--  ShoppingTooltip1:HookScript("OnTooltipSetItem", GS_RefTooltip1_OnRefTooltipSetItem);
--  ShoppingTooltip2:HookScript("OnTooltipSetItem", GS_RefTooltip2_OnRefTooltipSetItem);


	local function OnTooltipSetItem(self, data)
		if (not isTooltipDone) and self then
			isTooltipDone = true

			local _, link = GetItemInfo(data.id)

			if link then
				GS_setTooltip(self, link)
			end
		end			
	end
	
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)



end

-- **************************************************************************
-- DESC : Add GearStatistics values to the GameToolTip
-- **************************************************************************
function GS_setTooltip(tooltip, ...)
  GS_Debug("entering setTooltip", 0)

  if (lastTooltipText == "") then
    if (not tooltip) then
      tooltip = GameTooltip
    end

    -- only process if for a game item 
    local itemName, itemLink = tooltip:GetItem()
    GS_Debug("GetItem", 0)
    GS_Debug("itemname: "..itemName.." - itemLink: "..itemLink, 0)
  
    if itemLink then
      local text, success = GS_GetGameTooltipText(itemLink);
      -- add score to tooltip if the tooltip has at least 1 line
      local GS_tooltip = getglobal(tooltip:GetName().."TextLeft1");
      if (GS_tooltip and success == 1) then
        GS_Debug("Tooltip on show itemScore: "..text.." : success: "..success.."itemlink: "..itemLink, 0);
     
        -- only show tooltip, if success in getting text
        lastTooltipText = text;
        tooltip:AddDoubleLine(" ", lastTooltipText);
      end
    end
  	GS_Debug("tooltip created: "..lastTooltipText, 0)
    
  else
    tooltip:AddLine(" ", lastTooltipText);
  	GS_Debug("last tooltip used"..lastTooltipText, 0)
  end
	
  tooltip:Show()
end




-- **************************************************************************
-- DESC : Reset GameToolTip
-- **************************************************************************
function GS_ResetTooltip()
  GS_Debug("resetting tooltip", 0)
  lastTooltipText = ""
  lastRefTooltipText1 = ""
  lastRefTooltipText2 = ""
  lastWorldMapTooltipText = ""
  isTooltipDone = nil
end

-- **************************************************************************
-- DESC : Show WorldMapToolTip
-- **************************************************************************
function GS_WorldMapTooltip_OnShow(tooltip, ...)
  GS_Debug("show WorldMap tooltip", 0)

  tooltip:Show()
end

-- **************************************************************************
-- DESC : Clear GameToolTip
-- **************************************************************************
function GS_WorldMapTooltip_OnHide(tooltip, ...)
  GS_Debug("clear WorldMap tooltip", 0)

  GS_ResetTooltip();
end

-- **************************************************************************
-- DESC : Add GearStatistics values to the GameToolTip
-- **************************************************************************
function GS_WorldMapTooltip_OnGameTooltipSetItem(tooltip, ...)
  GS_Debug("entering set item WorldMap tooltip", 0)

  if (lastWorldMapTooltipText == "") then
    GS_Debug("set item tooltip", 0)

    if (not tooltip) then
      tooltip = WorldMapTooltip
    end
  
    -- only process if for a game item 
    local itemName, itemLink = tooltip:GetItem()
  
    if itemLink then
      local text, success = GS_GetGameTooltipText(itemLink);
      -- add score to tooltip if the tooltip has at least 1 line
      local GS_tooltip = getglobal(tooltip:GetName().."TextLeft1");
      if (GS_tooltip and success == 1) then
        GS_Debug("Tooltip on show itemScore: "..text.." : success: "..success.."itemlink: "..itemLink, 0);
     
        -- only show tooltip, if success in getting text
        lastWorldMapTooltipText = text;
        tooltip:AddLine(" ", lastWorldMapTooltipText);
      end
    end
  else
    tooltip:AddLine(" ", lastWorldMapTooltipText);
  end
end

-- **************************************************************************
-- DESC : Show GameToolTip
-- **************************************************************************
function GS_Tooltip_OnShow(tooltip, ...)
  GS_Debug("show tooltip", 1)
  
  GS_Tooltip_OnGameTooltipSetItem(tooltip, ...)
  
  tooltip:Show()
end

-- **************************************************************************
-- DESC : Clear GameToolTip
-- **************************************************************************
function GS_Tooltip_OnHide(tooltip, ...)
  GS_Debug("clear tooltip", 0)

  GS_ResetTooltip();
end

-- **************************************************************************
-- DESC : Add GearStatistics values to the GameToolTip
-- **************************************************************************
function GS_Tooltip_OnGameTooltipSetItem(tooltip, ...)
  GS_Debug("entering set item tooltip", 1)

  if (lastTooltipText == "") then
    GS_Debug("set item tooltip", 0)

    if (not tooltip) then
      tooltip = GameTooltip
    end
  
    -- only process if for a game item 
    local itemName, itemLink = tooltip:GetItem()
    GS_Debug("GetItem", 0)
    GS_Debug("itemname: "..itemName.." - itemLink: "..itemLink, 0)
  
    if itemLink then
      local text, success = GS_GetGameTooltipText(itemLink);
      -- add score to tooltip if the tooltip has at least 1 line
      local GS_tooltip = getglobal(tooltip:GetName().."TextLeft1");
      if (GS_tooltip and success == 1) then
        GS_Debug("Tooltip on show itemScore: "..text.." : success: "..success.."itemlink: "..itemLink, 0);
     
        -- only show tooltip, if success in getting text
        lastTooltipText = text;
        tooltip:AddDoubleLine(" ", lastTooltipText);

      end
    end
  else
    tooltip:AddDoubleLine(" ", lastTooltipText);
  end
end

-- **************************************************************************
-- DESC : Add GearStatistics values to the RefGameToolTip1
-- **************************************************************************
function GS_RefTooltip1_OnRefTooltipSetItem(tooltip, ...)
  GS_Debug("entering setup ref tooltip1", 1)
  
  if (lastRefTooltipText1 == "") then
    GS_Debug("setup ref tooltip", 0)

    if (not tooltip) then
      tooltip = GameTooltip
    end
    
    -- only process if for a game item 
    local itemName, itemLink = tooltip:GetItem()
  
    if itemLink then
      local text, success = GS_GetGameTooltipText(itemLink);
      -- add score to tooltip if the tooltip has at least 1 line
      local GS_tooltip = getglobal(tooltip:GetName().."TextLeft1");
      if (GS_tooltip and success == 1) then
        GS_Debug("Tooltip on show itemScore: "..text.." : success: "..success, 0);

        -- only show tooltip, if success in getting text
        lastRefTooltipText1 = text;
        tooltip:AddDoubleLine(" ", lastRefTooltipText1);
      end
    end
  else
    tooltip:AddDoubleLine(" ", lastRefTooltipText1);
  end
end

-- **************************************************************************
-- DESC : Add GearStatistics values to the RefGameToolTip2
-- **************************************************************************
function GS_RefTooltip2_OnRefTooltipSetItem(tooltip, ...)
  GS_Debug("entering setup ref tooltip2", 1)
  
  if (lastRefTooltipText2 == "") then
    GS_Debug("setup ref tooltip", 0)

    if (not tooltip) then
      tooltip = GameTooltip
    end
    
    -- only process if for a game item 
    local itemName, itemLink = tooltip:GetItem()
  
    if itemLink then
      local text, success = GS_GetGameTooltipText(itemLink);
      -- add score to tooltip if the tooltip has at least 1 line
      local GS_tooltip = getglobal(tooltip:GetName().."TextLeft1");
      if (GS_tooltip and success == 1) then
        GS_Debug("Tooltip on show itemScore: "..text.." : success: "..success, 0);

        -- only show tooltip, if success in getting text
        lastRefTooltipText2 = text;
        tooltip:AddDoubleLine(" ", lastRefTooltipText2);
      end
    end
  else
    tooltip:AddDoubleLine(" ", lastRefTooltipText2);
  end
end

-- **************************************************************************
-- DESC : Returns the text to add to the GameToolTip
-- **************************************************************************
function GS_GetGameTooltipText(slotLink)
  local text = "";
  local success = 0;

  if (slotLink) then
    -- only add text to weapons and armor 
    GS_Debug("GS_GetGameTooltipText: entering slotlink", 0)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, maxStack, equipSlot, texture, vendorprice = GetItemInfo(slotLink);
    if(itemType == GS_ARMOR or itemType == GS_WEAPON) then
      local iLevel = GS_GetItemLevel(slotLink)
      local levelColor = GS_GetLevelColor(iLevel, GS.currentPlayer.averageItemLevel);
      local enchantScore, enchantText = GS_GetItemEnchantScore(slotLink)
      local gemScore, gemText = GS_GetItemGemScore(slotLink)
      local itemScore = GS_GetItemScore(slotLink) + enchantScore + gemScore
              
      GS_Debug("itemLevel: "..itemLevel.."  ilvl: "..iLevel, 0);
      if(iLevel ~= "0") then
        text = GS_TOOLTIP_HEADLINE..": ".."|c"..levelColor.."i"..iLevel.." ("..format("%.0f", itemScore)..")"
        end
        success = 1;
      end
    end
    
    return text, success;
  end
  
-- **************************************************************************
-- DESC : DEBUG, show detailed information
-- **************************************************************************
function GS_ShowCurrentPlayerData()
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
  DEFAULT_CHAT_FRAME:AddMessage("recordedTime: "..GS.currentPlayer.recordedTime);
  for index in ipairs(GS_GEARLIST) do 
    if(GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemName) then
      DEFAULT_CHAT_FRAME:AddMessage("itemList: "..GS.currentPlayer.itemList[GS_GEARLIST[index].name].itemName);
    end
  end
  
  DEFAULT_CHAT_FRAME:AddMessage("Data.Version: "..GS.Data.version);
end