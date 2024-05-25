-- *** Local variables


-- *** Functions

-- **************************************************************************
-- DESC : Hook the item tooltip
-- **************************************************************************
function hookTooltips()
  local function addGearstatToTooltip(tooltip, data)
 	 local gearScoreText = getTooltipText2(tooltip);
 	 if gearScoreText then
	  	 tooltip:AddDoubleLine(TOOLTIP_HEADLINE ..":", gearScoreText);
	 end
  end

  if GSaddOn.isRetail then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addGearstatToTooltip)
  elseif GSaddOn.isClassic then
    --- TODO fix classic tooltip, for know make titan plugin work
    GameTooltip:HookScript("OnShow", GS_Tooltip_OnShow);
  -- GameTooltip:HookScript("OnTooltipSetItem", GS_Tooltip_OnGameTooltipSetItem)
    GameTooltip:HookScript("OnHide", GS_Tooltip_OnHide)

  --  WorldMapTooltip:HookScript("OnShow", GS_Tooltip_OnShow);
  --  WorldMapTooltip:HookScript("OnTooltipSetItem", GS_WorldMapTooltip_OnGameTooltipSetItem)
  --  WorldMapTooltip:HookScript("OnHide", GS_Tooltip_OnHide)

  --  ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", GS_RefTooltip1_OnRefTooltipSetItem);
  --  ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", GS_RefTooltip2_OnRefTooltipSetItem);
  --  ShoppingTooltip1:HookScript("OnTooltipSetItem", GS_RefTooltip1_OnRefTooltipSetItem);
  --  ShoppingTooltip2:HookScript("OnTooltipSetItem", GS_RefTooltip2_OnRefTooltipSetItem);
  end
end

-- **************************************************************************
-- DESC : Show Tooltip
-- **************************************************************************
function GS_Tooltip_OnShow(tooltip, ...)
  tooltip:Show()
end

-- **************************************************************************
-- DESC : Show Tooltip
-- **************************************************************************
function GS_Tooltip_OnHide(tooltip, ...)
  tooltip:Hide()
end

-- **************************************************************************
-- DESC : Returns the text to add to the ToolTip
-- **************************************************************************
function getTooltipText(slotLink)
  local text = "";
  local success = 0;

  if (slotLink) then
    -- only add text to weapons and armor 
    debugMessage("getTooltipText: entering slot-link", 0)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, maxStack, equipSlot, texture, vendorprice = GetItemInfo(slotLink);
    if(itemType == GEARTYPE_ARMOR or itemType == GEARTYPE_WEAPON) then
      local iLevel = getItemLevel(slotLink)
      local levelColor = getLevelColor(iLevel, GS.currentPlayer.averageItemLevel);
      local enchantScore, enchantText = getItemEnchantScore(slotLink)
      local gemScore, gemText = getItemGemScore(slotLink)
      local itemScore = getItemScore(slotLink) + enchantScore + gemScore
              
      debugMessage("itemLevel: "..itemLevel.."  ilvl: "..iLevel, 0);
      if(iLevel ~= "0") then
        text = TOOLTIP_HEADLINE ..": ".."|c"..levelColor.."i"..iLevel.." ("..format("%.0f", itemScore)..")"
        end
        success = 1;
      end
    end
    
    return text, success;
  end

-- **************************************************************************
-- DESC : Returns the text to add to the ToolTip
-- **************************************************************************
function getTooltipText2(tooltip)
  local iName, iLink = TooltipUtil.GetDisplayedItem(tooltip);
  local text;

  if (iLink) then
    -- only add text to weapons and armor 
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType = GetItemInfo(iName);
    if(itemType == GEARTYPE_ARMOR or itemType == GEARTYPE_WEAPON) then
      -- get item level	
      local iLevel = scanTooltip(tooltip, ITEMTEXT_ILVL.." ")
      
      -- calculate levelColor
      local levelColor = getLevelColor(iLevel, GS.currentPlayer.averageItemLevel);
      
      -- calculate enchantScore INACTIVE
      local enchantScore, enchantText = getItemEnchantScore(iLink)

	  -- calculate gemScore INACTIVE	
      local gemScore, gemText = getItemGemScore(iLink)

	  -- calculate gear score
	  local gearScore =	0
	  for index in ipairs(STATTYPES) do
	    local statValue = tonumber(scanTooltip(tooltip, " "..STATTYPES[index].text))
	    -- in case the scan fails
	    if (statValue) then
    	  gearScore = gearScore + statValue
    	end
	  end

	  -- calculate total item score
      local itemScore = gearScore + enchantScore + gemScore
              
      if(iLevel) then
        text = "|c"..levelColor.."i"..iLevel.." ("..format("%.0f", itemScore)..")"
        end
      end
    end
    
    return text;
  end

-- **************************************************************************
-- DESC : Returns value right to the search text
-- **************************************************************************
function scanTooltip(scantip, searchstring)
  local value = 0
  
  if isTooltipUsable(scantip) then
    -- Scan the tooltip:
    for i = 2, scantip:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G[scantip:GetName()..TOOLTIP_TEXTLEFT..i]:GetText()
      debugMessage("debug text: "..text.." - numlines: "..i.."/"..scantip:NumLines(), 0)

      local match = strmatch(text, searchstring)
      if match and match ~= "" then
        value = gsub(text, searchstring, "")
      end
    end
  end
  
  if (value == nil) then value = 0 end
  return value
end

-- **************************************************************************
-- DESC : Check if the tooltip is in-game
-- **************************************************************************
function isTooltipUsable(scantip)
  
  if(scantip == GameTooltip) then return 1 end
  if(scantip == ShoppingTooltip1) then return 1 end
  if(scantip == ShoppingTooltip2) then return 1 end
  if(scantip == ItemRefTooltip) then return 1 end
  if(scantip == ItemRefShoppingTooltip1) then return 1 end
  if(scantip == ItemRefShoppingTooltip2) then return 1 end
  
  return nil
  
end
