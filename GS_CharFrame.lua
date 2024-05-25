-- *** Local variables
local _G = getfenv(0);

-- *** Functions
  
-- **************************************************************************
-- DESC : Setup CharFrame to match the playerName
-- **************************************************************************
function GS_CharFrame_OnShow(self, playerName)
  debugMessage("CharFrame OnShow", 0);

  if(not playerName) then
    playerName = UnitName(GS_TEXT_PLAYER);
  end
  
  local race, fileName = UnitRace(GS_TEXT_PLAYER);
  SetPortraitTexture(GS_CharFramePaperDollFramePortrait, GS_TEXT_PLAYER);
  GS_CharFrameDressUpFrameTitleText:SetText(playerName);

  local playerRecord = getPlayerRecord(playerName);

  GS_CharFrameDressUpFrameDescriptionText:SetText("Level "..playerRecord.playerLevel.." "..playerRecord.race.." "..playerRecord.class);
  GS_CharFrameDressUpFrameGuildText:SetText(playerRecord.guild)

  local texture = DressUpTexturePath(fileName);
  GS_CharFrameDressUpBackgroundTopLeft:SetTexture(texture..1);
  GS_CharFrameDressUpBackgroundTopRight:SetTexture(texture..2);
  GS_CharFrameDressUpBackgroundBotLeft:SetTexture(texture..3);
  GS_CharFrameDressUpBackgroundBotRight:SetTexture(texture..4);

  GS_CharFrameDressUpFrameAverageScore:SetText(CHARFRAME_AVERAGE_SCORE ..": i"..format("%.0f", playerRecord.averageItemLevel).." ("..format("%.0f", playerRecord.averageItemScore)..")");
  GS_CharFrameDressUpFrameTotalScore:SetText(CHARFRAME_TOTAL_SCORE ..": i"..format("%.0f", playerRecord.totalItemLevel).." ("..format("%.0f", playerRecord.totalItemScore)..")");

  for index in ipairs(GEARLIST) do
    debugMessage("ready to update gear, index: "..index, 0)
    local itemColor = colorNone;
    local itemScore = 0;    
    local slotName = GEARLIST[index].name;
    debugMessage("Slot: "..slotName, 0);
    button = _G["GS_Character"..slotName];

    debugMessage("playerRecord.itemList[slotName].itemName "..playerRecord.itemList[slotName].itemName, 0);
    
    if(playerRecord.itemList and playerRecord.itemList[slotName] and playerRecord.itemList[slotName].itemName ~= TEXT_NO_ITEM_EQUIPPED) then
      debugMessage("creating "..playerRecord.itemList[slotName].itemName, 0);
      button.link = playerRecord.itemList[slotName].itemLink;
      local itemRarity = playerRecord.itemList[slotName].itemRarity;
      if(ITEM_RARITY[itemRarity] and ITEM_RARITY[itemRarity].color) then
        itemColor = ITEM_RARITY[itemRarity].color
      end
      if(playerRecord.itemList[slotName].itemScore) then
        itemScore = "|c"..playerRecord.itemList[slotName].levelColor..format("%.0f", playerRecord.itemList[slotName].itemScore);
      end
      GS_UpdateItemSlot(button, ITEM_RARITY[playerRecord.itemList[slotName].itemRarity+1].color, playerRecord.itemList[slotName].itemLevel, itemScore, playerRecord.playerLevel, playerRecord.twoHandWeapon);
      button:Show();
    else
      debugMessage("No gear item found", 0);
      button.link = nil;
      GS_UpdateItemSlot(button, 0, 0, 0, playerRecord.playerLevel, playerRecord.twoHandWeapon);
      button:Show();
    end
  end
end

-- **************************************************************************
-- DESC : Load background for item slots
-- **************************************************************************
function GS_ItemButton_OnLoad(self)
  local buttonName = self:GetName();
  local slotId;
  if(buttonName) then
    self.slotName = strsub(buttonName, 13);
    slotId, self.backgroundTextureName = GetInventorySlotInfo(self.slotName);
    _G[buttonName.."IconTexture"]:SetTexture(self.backgroundTextureName);
    self:SetID(slotId);
  end
end

-- **************************************************************************
-- DESC : Show tooltip for item or slot
-- **************************************************************************
function GS_ItemButton_OnEnter(self)
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
  if (self.link) then
    if (GetItemInfo(self.link)) then
      GameTooltip:SetHyperlink(self.link);  -- if item slot button has link show it in tooltip 
    else
      GameTooltip:SetText("|c".. colorRed ..GS_TEXT_UNSAFELINK.."|c".. colorYellow .." - "..GS_TEXT_DISCONNECT);
    end
  else
    GameTooltip:SetText(_G[self.slotName:upper()]); -- otherwise just show slot name
  end
  if(self.link and IsShiftKeyDown()) then
    ItemRefShoppingTooltip1:SetHyperlink(self.link);
    ItemRefShoppingTooltip2:SetHyperlink(self.link);
  end
end

-- **************************************************************************
-- DESC : Hide tooltip
-- **************************************************************************
function GS_ItemButton_OnLeave(self)
  ResetCursor();
  GameTooltip:Hide();
end

-- **************************************************************************
-- DESC : Enable chat-link and dress-up
-- **************************************************************************
function GS_ItemButton_OnClick(self,button)
  if( button == "LeftButton" and self.link) then
    if( IsShiftKeyDown() ) then
      ChatEdit_InsertLink(self.link);
    elseif( IsControlKeyDown() ) then
      DressUpItemLink(self.link);
    end
  end
end

-- **************************************************************************
-- DESC : update gearslot graphic in CharFrame
-- **************************************************************************
function GS_UpdateItemSlot(button, itemColor, itemLevel, itemScore, playerLevel, twoHand)
  
  debugMessage("Entering update",0);

  if(not playerLevel) then
    playerLevel = -1;
  end
  if(not twoHand) then
    twoHand = false;
  end
  local border = _G[button:GetName().."BorderTexture"];
  local ignoreOverlayer = _G[button:GetName().."IgnoreTexture"];
  local itemScoreText = _G[button:GetName().."ItemScore"];
  local itemLevelText = _G[button:GetName().."ItemLevel"];
   
  if (button.link) then
    ignoreOverlayer:Hide();
    if(itemScore) then
      itemScoreText:SetText(itemScore);
      itemScoreText:Show();
    end
    if(itemLevel) then
      itemLevelText:SetText("i"..itemLevel);
      itemLevelText:Show();
    end   
    -- Only scan the item if it's in the users local cache, to avoid DC's
    if (GetItemInfo(button.link) and border) then
      -- Set Border Color
      if (itemColor == colorBlue) then
        border:SetVertexColor(0.1255,0.8157,1);
      elseif(itemColor == colorGrey) then
        border:SetVertexColor(0.6157,0.6157,0.6157);
      elseif(itemColor == colorWhite) then
        border:SetVertexColor(1,1,1);
      elseif(itemColor == colorGreen) then
        border:SetVertexColor(0.1176,1,0);
      elseif(itemColor == colorDarkBlue) then
        border:SetVertexColor(0,0.4392,0.8667);
      elseif(itemColor == colorPurple) then
        border:SetVertexColor(0.6392,0.2078,0.9333);
      elseif(itemColor == colorOrange) then
        border:SetVertexColor(1,0.502,0);
      elseif(itemColor == colorGold) then
        border:SetVertexColor(0.898,0.8,0.502);
      else
        border:SetVertexColor(0.502,0.502,0.502);
      end
      border:Show();
      -- Set Texture
      local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(button.link);
      SetItemButtonTexture(button, itemTexture or button.backgroundTextureName);
    else
      -- Cannot find link in local cache so potentially unsafe therefore border blue
      SetItemButtonTexture(button,button.backgroundTextureName);
      border:SetVertexColor(0.1255,0.8157,1);
      border:Show();
    end
  else
    debugMessage("no button link", 0);
    SetItemButtonTexture(button,button.backgroundTextureName);
    for index in ipairs(GEARLIST) do
      -- if empty slot and player can equip slot, hide ignoreOverlayer or
      if(("GS_Character".. GEARLIST[index].name) == button:GetName() and GEARLIST[index].minLevel <= playerLevel) then
        ignoreOverlayer:Hide()
      elseif(("GS_Character".. GEARLIST[index].name) == button:GetName() and GEARLIST[index].minLevel > playerLevel) then
        ignoreOverlayer:Show()
      end
    end
    -- if offhand is empty and no twohand is equipped, hide overlayer
    if(button:GetName() == ("GS_Character".. GEARSLOT_OFFHAND) and twoHand == true) then
      ignoreOverlayer:Show()
    end
    border:Hide();
    itemScoreText:Hide();
    itemLevelText:Hide();
  end
end

-- **************************************************************************
-- DESC : Show/hide the character window
-- **************************************************************************
function GS_CharFrame_Toggle()
  debugMessage("Toggling Character frame", 0);

  if (GS_CharFrame:IsVisible()) then
    GS_CharFrame:Hide();
  else
    GS_CharFrame:Show();
  end
end

