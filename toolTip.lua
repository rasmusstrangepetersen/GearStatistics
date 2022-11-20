-- *** Local variables


-- *** Functions

-- **************************************************************************
-- DESC : Hook the item tooltip
-- **************************************************************************
function GS_HookTooltips()
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



  
