-- *** Local variables


-- *** Functions

-- **************************************************************************
-- DESC : Hook the item tooltip
-- **************************************************************************
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
      
      -- calculate enchantScore INACTIVE
      local enchantScore, enchantText = GS_GetItemEnchantScore(iLink)

	  -- calculate gemScore INACTIVE	
      local gemScore, gemText = GS_GetItemGemScore(iLink)

	  -- calculate gear score
	  local gearScore =	0
	  for index in ipairs(GS_STATTYPES) do
	    local statValue = tonumber(GS_scanTooltip(tooltip, GS_STATTYPES[index].text))
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
function GS_scanTooltip(scantip, searchstring)
  local value = 0
  
  if GS_isTooltipUsable(scantip) then
    -- Scan the tooltip:
    for i = 2, scantip:NumLines() do -- Line 1 is always the name so you can skip it.
      local text = _G[scantip:GetName().."TextLeft"..i]:GetText()
      GS_Debug("debug text: "..text.." - numlines: "..i.."/"..scantip:NumLines(), 0)

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
-- DESC : Check if the tooltip is ingame
-- **************************************************************************
function GS_isTooltipUsable(scantip)
  
  if(scantip == GameTooltip) then return 1 end
  if(scantip == ShoppingTooltip1) then return 1 end
  if(scantip == ShoppingTooltip2) then return 1 end
  if(scantip == ItemRefTooltip) then return 1 end
  if(scantip == ItemRefShoppingTooltip1) then return 1 end
  if(scantip == ItemRefShoppingTooltip2) then return 1 end
  
  return nil
  
end


  