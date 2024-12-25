--- support for TitanPanel
--- formerly a separate add-on (TitanGearStatistics)

-- *** TitanPanel plugin identity
TITAN_GS_ID = "GearStat";

-- *** Local variables
local updateFrame = CreateFrame("frame");

-- **************************************************************************
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
function TitanPanelGearStatButton_OnLoad(self)
    self.registry = {
        id = TITAN_GS_ID,
        category = TITAN_GS_CATEGORY,
        version = REVISION,
        menuText = TITAN_GS_TOOLTIP_TITLE,
        menuTextFunction = TitanPanelRightClickMenu_PrepareGearStatMenu,
        buttonTextFunction = TitanPanelGearStatButton_GetButtonText,
        tooltipTitle = TITAN_GS_TOOLTIP_TITLE,
        tooltipTextFunction = TitanPanelGearStatButton_GetTooltipText,
        icon = "Interface\\Icons\\INV_Chest_Samurai",
        iconWidth = 16,
        controlVariables = {
            ShowIcon = true,
            ShowLabelText = true,
            ShowRegularText = true,
            ShowColoredText = true,
            DisplayOnRightSide = false,
        },
        savedVariables = {
            ShowIcon = 1,
            ShowLabelText = 1,
            ShowRegularText = 1,
            ShowColoredText = 1,
        }
    };

    updateFrame:SetScript("OnUpdate", TitanPanelGearStatButton_OnUpdate)

    debugMessage("TitanPanelGearStat loaded", 0);
end

-- **************************************************************************
-- DESC : Right click menu in titanbar
-- **************************************************************************
function TitanPanelRightClickMenu_PrepareGearStatMenu()
    debugMessage("Preparing right-click menu", 0);

    TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_GS_ID].menuText);
    TitanPanelRightClickMenu_AddControlVars(TITAN_GS_ID)
end

-- **************************************************************************
-- DESC : Open main UI on left click
-- **************************************************************************
function TitanPanelGearStatButton_OnClick(_, button)
    debugMessage("Entering GS_OnClick, button: "..button, 0);

    if (button == TITAN_GS_LEFT_BUTTON) then
        GS_CharFrame_Toggle();
    end
end

-- **************************************************************************
-- DESC : Update Titan Panel button text
-- VARS : id = plugin id
-- **************************************************************************
function TitanPanelGearStatButton_GetButtonText(id)
    debugMessage("Entering TitanPanelGearStatButton_GetButtonText, ShowRegularText - button id: "..id, 0);

    out = ""

    if (TitanGetVar(TITAN_GS_ID, TITAN_GS_SHOW_REGULAR_TEXT)) then
        out = TitanPanelGS_GetScore(TitanGetVar(TITAN_GS_ID, TITAN_GS_SHOW_COLORED_TEXT))
    end

    return TITAN_GS_LABEL_TEXT, out
end

-- **************************************************************************
-- DESC : Update tooltip text
-- **************************************************************************
function TitanPanelGearStatButton_GetTooltipText()
    debugMessage("Entering: TitanPanelGearStatButton_GetTooltipText", 0);

    TitanPanelButton_UpdateButton(TITAN_GS_ID);
    TitanPanelButton_UpdateTooltip(self);

    out = TitanPanelGS_GetPlayerGear()
    out = out.."\n".."|c"..colorBlue..TITAN_GS_GEAR_CLICK

    return out;
end

-- **************************************************************************
-- DESC : Return the players current gear score as formatted text
-- VARS : inColor, if 1 then return the text in right colour
-- **************************************************************************
function TitanPanelGS_GetScore(inColor)
    if(GS.currentPlayer.averageItemLevel == 0 or GS.currentPlayer.averageItemLevel == nil) then
        updateGearScore("player", 1);
    end

    local averageItemScore = 0;
    if (GS.currentPlayer.averageItemLevel > 0) then
        averageItemScore = "i"..format("%.0f", tonumber(GS.currentPlayer.averageItemLevel))
    end

    if(inColor) then
        local color = TitanPanelGS_GetColorByScore(GS.currentPlayer);
        averageItemScore = "|c"..color..averageItemScore
    end

    return averageItemScore
end

-- **************************************************************************
-- DESC : Get color for tooltip, based on the difference in ilvl for the players equipped gear
-- colors and limits for colors defined in variables.lua AVG_GEAR_ILVL_COLOR_LIMIT in GearStatistics
-- **************************************************************************
function TitanPanelGS_GetColorByScore(playerRecord)

    if (playerRecord == nil) then
        return colorBlue;
    end

    return calculateColor(playerRecord.maxItemLevel - playerRecord.minItemLevel)
end

-- **************************************************************************
-- DESC : Return the players current gear with itemLevel and score as formatted text
-- **************************************************************************
function TitanPanelGS_GetPlayerGear()
    debugMessage("Returning player gear", 0);

    text = ""
    local iName = ""

    for index in ipairs(GEARLIST) do
        GEARLIST[index].id = GetInventorySlotInfo(GEARLIST[index].name);
        local slotLink = GetInventoryItemLink(UnitName("player"), GEARLIST[index].id);
        if (slotLink ~= nil) then
            local itemName, itemLink, _, itemLevel, _, _, _ = GetItemInfo(slotLink);
            local effectiveILvl, _, _ = GetDetailedItemLevelInfo(slotLink)
            itemLevel = effectiveILvl
            local itemScore = 0;
            iName = itemName;
            if(GEARLIST[index].minLevel > 0 and itemLink) then
                text = text..GEARLIST[index].desc..": "..GS.currentPlayer.itemList[GEARLIST[index].name].itemLink
                local missingEnchantsAndGems = GS.currentPlayer.itemList[GEARLIST[index].name].itemMissingText;
                itemLevel = GS.currentPlayer.itemList[GEARLIST[index].name].itemLevel
                itemScore = GS.currentPlayer.itemList[GEARLIST[index].name].itemScore
                if(itemScore == nil) then
                    itemScore = 0;
                end
                local levelColor = GS.currentPlayer.itemList[GEARLIST[index].name].levelColor

                text = text.."\t".."|c"..levelColor..missingEnchantsAndGems;
                text = text.." i"..itemLevel.." ("..format("%.0f", tonumber(itemScore))..")"
                text = text.."\n";
            end
        else
            -- Don't write "empty offhand slot", if two hand weapon is equipped and don't write empty tabard and shirt
            -- (not (GEARLIST[index].desc == GS_OFFHAND and GS.currentPlayer.twoHandWeapon == true)) and
            if(GEARLIST[index].minLevel <= GS.currentPlayer.playerLevel
                    --        and isLegionArtifactWeapon(GEARLIST[index].desc, iName)==0
                    and GEARLIST[index].minLevel > 0
                    and (not(GEARLIST[index].desc == GEAR_OFFHAND and GS.currentPlayer.twoHandWeapon == true))) then
                text = text..GEARLIST[index].desc..": ".."|c"..colorGrey..TITAN_GS_NO.." "..GEARLIST[index].desc.." "..TITAN_GS_EQUIPPED
                text = text.."\n"
            end
        end
    end
    text = text.." ".."\t"..TITAN_GS_AVERAGE..": i"..format("%.0f", GS.currentPlayer.averageItemLevel).." ("..format("%.0f", GS.currentPlayer.averageItemScore)..")";

    return text
end
