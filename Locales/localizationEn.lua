if GetLocale() ~= "enUS" then return end -- When adding a new language, remember to add the localization file to the .toc file

-- *** Version information
GS_VERSION_TEXT = "GearStatistics version: ";
GS_VERSION_WOWVERSION = " - Dragonflight"

-- *** AddOn information - chat messages
GS_CMD_VERSION = "version"
GS_CMD_UPDATE = "update"
GS_CMD_SHOW = "show"
GS_CMD_HIDE = "hide"
GS_CMD_RL = "rl"
GS_CMD_RELOADUI = "reloadui"
GS_CMD_TEXT_HEADLINE = "GearStatistics Commands:"
GS_CMD_TEXT_VERSION = "/gs version - shows version information"
GS_CMD_TEXT_UPDATE = "/gs update - updates the current players gearstatistics"
GS_CMD_TEXT_SHOW = "/gs show or hide - toggles character frame with gearstatistics"
GS_CMD_TEXT_RL = "/gs rl or reloadui - reloads the ui"
GS_LOADED = "GearStatistics loaded, version: "
GS_USE_COMMANDS = ", use command: /gs"
GS_UPDATING_GEAR = "Updating record of your gear."

-- *** GS variable texts 
GS_NO_GUILD = " - No Guild recorded - "
GS_NO_ITEM_EQUIPPED = "No item Equipped"

-- *** Item rarity
GS_POOR = "Poor"
GS_COMMON = "Common"
GS_UNCOMMON = "Uncommon"
GS_RARE = "Rare"
GS_EPIC = "Epic"
GS_LEGENDARY = "Legendary"
GS_ARTIFACT = "Artifact"
GS_HEIRLOOM = "Heirloom"
GS_UNKNOWN = "Unknown"

-- *** GearList
GS_HEAD = "Head"
GS_NECK = "Neck"
GS_SHOULDERS = "Shoulders"
GS_BACK  = "Back"
GS_CHEST = "Chest"
GS_SHIRT = "Shirt"
GS_TABARD = "Tabard"
GS_WRIST = "Wrist"
GS_HANDS = "Hands"
GS_WAIST = "Waist"
GS_LEGS = "Legs"
GS_FEET = "Feet"
GS_FINGER1 = "1st Finger"
GS_FINGER2 = "2nd Finger"
GS_TRINKET1 = "1st Trinket"
GS_TRINKET2 = "2nd Trinket"
GS_MAINHAND = "Main Hand"
GS_OFFHAND = "Off Hand"

-- TODO move *** GearList
GEARSTAT_OFFHANDSLOT = "SecondaryHandSlot"

GS_GEARLIST = {
    { name = "HeadSlot" ,         desc = GS_HEAD,       minLevel = 1 },
    { name = "NeckSlot" ,         desc = GS_NECK,       minLevel = 1 },
    { name = "ShoulderSlot" ,     desc = GS_SHOULDERS,  minLevel = 1 },
    { name = "BackSlot" ,         desc = GS_BACK,       minLevel = 1  },
    { name = "ChestSlot" ,        desc = GS_CHEST,      minLevel = 1  },
    { name = "ShirtSlot" ,        desc = GS_SHIRT,      minLevel = 0  }, -- minLevel = 0, since it's not a gear item with a gear score
    { name = "TabardSlot" ,       desc = GS_TABARD,     minLevel = 0  }, -- minLevel = 0, since it's not a gear item with a gear score
    { name = "WristSlot" ,        desc = GS_WRIST,      minLevel = 1  },
    { name = "HandsSlot" ,        desc = GS_HANDS,      minLevel = 1  },
    { name = "WaistSlot" ,        desc = GS_WAIST,      minLevel = 1  },
    { name = "LegsSlot" ,         desc = GS_LEGS,       minLevel = 1  },
    { name = "FeetSlot" ,         desc = GS_FEET,       minLevel = 1  },
    { name = "Finger0Slot" ,      desc = GS_FINGER1,    minLevel = 1 },
    { name = "Finger1Slot" ,      desc = GS_FINGER2,    minLevel = 1 },
    { name = "Trinket0Slot" ,     desc = GS_TRINKET1,   minLevel = 1 },
    { name = "Trinket1Slot" ,     desc = GS_TRINKET2,   minLevel = 1 },
    { name = "MainHandSlot" ,     desc = GS_MAINHAND,   minLevel = 1  },
    { name = GEARSTAT_OFFHANDSLOT,desc = GS_OFFHAND,    minLevel = 1  }
}

-- *** Gear stattypes
GS_STATTYPES = {
    { text = " Armor" },
    { text = " Stamina" },
    { text = " Intellect" },
    { text = " Agility" },
    { text = " Strength" },
    { text = " Critical Strike" },
    { text = " Mastery" },
    { text = " Versatility" },
    { text = " Haste" },
    { text = " Block"},
    { text = " Dodge"},
    { text = " Avoidance"}
}

-- TODO move
ITEM_RARITY = {
  { name=GS_POOR,      color=GS_colorGrey },
  { name=GS_COMMON,    color=GS_colorWhite },
  { name=GS_UNCOMMON,  color=GS_colorGreen },
  { name=GS_RARE,      color=GS_colorDarkBlue },
  { name=GS_EPIC,      color=GS_colorPurple },
  { name=GS_LEGENDARY, color=GS_colorOrange },
  { name=GS_ARTIFACT,  color=GS_colorGold },
  { name=GS_HEIRLOOM,  color=GS_colorGold },
  { name=GS_UNKNOWN,   color=GS_colorBlue },
}

-- *** Legion artifact weapons, dual wield but 1 weapon 
GS_DH_HAVOC = "Twinblades of the Deceiver"
GS_DH_VENGEANCE = "Aldrachi Warblades"
GS_DRUID_FERAL = "Fangs of Ashamane"
GS_DRUID_GUARDIAN = "Claws of Ursoc"
GS_SHAMAN_ELEMENTAL = "The Highkeeper's Ward"
GS_SHAMAN_ENHANCEMENT = "Fury of the Stonemother"
GS_SHAMAN_RESTORATION = "Shield of the Sea Queen"
GS_MAGE_FIRE = "Heart of the Phoenix"
GS_PALY_PROT = "Oathseeker"
GS_WARLOCK_DEMONOLOGY = "Spine of Thal'kiel"
GS_MONK_WINDWALKER = "Fists of the Heavens"
GS_WARRIOR_FURY = "Warswords of the Valarjar"
GS_WARRIOR_PROTECTION = "Scaleshard"
GS_PRIEST_SHADOW = "Secrets of the Void"
GS_ROGUE_SUBTLETY = "Fangs of the Devourer"
GS_ROGUE_OUTLAW = "The Dreadblades"
GS_ROGUE_ASSASSINATION = "The Kingslayers"
GS_DK_FROST = "Blades of the Fallen Prince"  

-- *** Two Hand weapon, subtypes
GS_TWOHAND_AXE = "Two-Handed Axes"
GS_TWOHAND_MACE = "Two-Handed Maces"
GS_TWOHAND_SWORD = "Two-Handed Swords"
GS_STAVES = "Staves"
GS_POLEARMS = "Polearms"
GS_BOWS = "Bows"
GS_CROSSBOWS = "Crossbows"
GS_GUNS = "Guns"
GS_FISHING = "Fishing Poles"

-- *** CharFrame texts
GS_CHARFRAME_PLAYERNAME = "Player name"
GS_CHARFRAME_LEVELRACECLASS = "Level <level> <race> <class>"
GS_CHARFRAME_GUILD = "Guild name"
GS_CHARFRAME_TOTALSCORE = "Total"
GS_CHARFRAME_AVERAGESCORE = "Average"

-- *** Tooltip text
GS_ARMOR = "Armor"
GS_WEAPON = "Weapon"
GS_TOOLTIP_HEADLINE = "GearStat"

-- *** Locale for Titan plugin
TITAN_GS_TOOLTIP_TITLE = "Gear Statistics"
TITAN_GS_LABEL_TEXT = "Gear Score: "
TITAN_GS_GEAR_CLICK = "Click".."|r ".."to open the main window."
TITAN_GS_NO = "No"
TITAN_GS_EQUIPPED = "equipped"
TITAN_GS_AVERAGE = "Average"
TITAN_GS_TOTAL = "Total"
