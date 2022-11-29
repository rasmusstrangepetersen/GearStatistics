-- *** Local variables


-- *** Functions

-- **************************************************************************
-- DESC : Hook the item tooltip
-- **************************************************************************
function GS_HookTooltipsOld()
  -- **** Make sure tooltiptext stay while mouseover is active ***
  local function OnTooltipSetItem(tooltip, data)
   	if tooltip == GameTooltip then
   	  GS_setTooltip(tooltip)
    end
  end
	
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)

  -- hook normal tooltip from bags and character
  GameTooltip:HookScript("OnShow", GS_setTooltip);
  
  
  -- Dropped trying to add score on compareitems, it seems you will have to recreate the compared item, in order to add text

end

function GS_HookTooltips()
	
  local function addGearstatToTooltip(tooltip, data)
 	 local gearScoreText = GS_GetTooltipText2(tooltip);
 	 if gearScoreText then
	  	 tooltip:AddDoubleLine(GS_TOOLTIP_HEADLINE..":", gearScoreText);
	 end
  end
	
	
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addGearstatToTooltip)

end



-- **************************************************************************
-- DESC : Add GearStatistics values to the tooltip
-- **************************************************************************
function GS_setTooltip(tooltip)
  GS_Debug("entering setTooltip", 0)
  
  -- only process if for a game item 
  local itemName, itemLink = tooltip:GetItem()
  
  if itemLink then
    local text, success = GS_GetTooltipText(itemLink);

    -- add score to tooltip if the tooltip has at least 1 line
    local GS_tooltip = getglobal(tooltip:GetName().."TextLeft1");

    if (GS_tooltip and success == 1) then
      GS_Debug("Tooltip on show itemScore: "..text.." : success: "..success.."itemlink: "..itemLink, 0);
     
      -- only show tooltip, if success in getting text
      tooltip:AddDoubleLine(" ", text);
    end
  end
	
  tooltip:Show()
end

-- **************************************************************************
-- DESC : Returns the text to add to the ToolTip
-- **************************************************************************
function GS_GetTooltipText(slotLink)
  local text = "";
  local success = 0;

  if (slotLink) then
    -- only add text to weapons and armor 
    GS_Debug("GS_GetTooltipText: entering slotlink", 0)
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
-- DESC : Returns the text to add to the ToolTip
-- **************************************************************************
function GS_GetTooltipText2(tooltip)
  local iName, iLink = TooltipUtil.GetDisplayedItem(tooltip);

  local text = nil;

  if (iLink) then
    -- only add text to weapons and armor 
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType = GetItemInfo(iName);
    if(itemType == GS_ARMOR or itemType == GS_WEAPON) then
      -- get item level	
      local iLevel = GS_scanTooltip(tooltip, "Item Level ")
      
      -- calculate levelColor
      local levelColor = GS_GetLevelColor(iLevel, GS.currentPlayer.averageItemLevel);
--      local levelColor = GS_colorYellow
      
      -- calculate enchantScore INACTIVE
      local enchantScore, enchantText = GS_GetItemEnchantScore(iLink)

	  -- calculate gemScore INACTIVE	
      local gemScore, gemText = GS_GetItemGemScore(iLink)

	  -- calculate gear score
	  local gearScore =	0
	  for index in ipairs(GS_STATTYPES) do
    	gearScore = gearScore + tonumber(GS_scanTooltip(tooltip, GS_STATTYPES[index].text))
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
function GS_scanTooltip(scantip, searchstring)
	
  local value = 0

  if scantip == GameTooltip then
    -- Scan the tooltip:
    for i = 2, GameTooltip:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G["GameTooltipTextLeft"..i]:GetText()
      GS_Debug("debug text: "..text.." - numlines: "..i.."/"..GameTooltip:NumLines(), 0)

      local match = strmatch(text, searchstring)
      if match and match ~= "" then
        value = gsub(text, searchstring, "")
      end
    end
  elseif (scantip == ShoppingTooltip1) then
    -- Scan the tooltip:
    for i = 2, ShoppingTooltip1:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G["ShoppingTooltip1TextLeft"..i]:GetText()

      local match = strmatch(text, searchstring)
      if match and match ~= "" then
        value = gsub(text, searchstring, "")
      end
    end
  elseif (scantip == ShoppingTooltip2) then
    -- Scan the tooltip:
    for i = 2, ShoppingTooltip2:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G["ShoppingTooltip2TextLeft"..i]:GetText()

      local match = strmatch(text, searchstring)
      if match and match ~= "" then
        value = gsub(text, searchstring, "")
      end
    end
  elseif (scantip == ItemRefTooltip) then
    -- Scan the tooltip:
    for i = 2, ItemRefTooltip:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G["ItemRefTooltipTextLeft"..i]:GetText()

      local match = strmatch(text, searchstring)
      if match and match ~= "" then
        value = gsub(text, searchstring, "")
      end
    end
  elseif (scantip == ItemRefShoppingTooltip1) then
    -- Scan the tooltip:
    for i = 2, ItemRefShoppingTooltip1:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G["ItemRefShoppingTooltip1TextLeft"..i]:GetText()

      local match = strmatch(text, searchstring)
      if match and match ~= "" then
        value = gsub(text, searchstring, "")
      end
    end
  elseif (scantip == ItemRefShoppingTooltip2) then
    -- Scan the tooltip:
    for i = 2, ItemRefShoppingTooltip2:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G["ItemRefShoppingTooltip2TextLeft"..i]:GetText()

      local match = strmatch(text, searchstring)
      if match and match ~= "" then
        value = gsub(text, searchstring, "")
      end
    end
  end
  
  if (value == nil) then value = 0 end
  
  return value
end
