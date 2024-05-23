--- Tables and colors used in the code

-- *** Used colors ***
colorRed        = "ffff0000"; -- red DEBUG text color and red gear (best)
colorOrange     = "ffff8000"; -- orange chat headline color and orange gear
colorYellow     = "ffffff00"; -- yellow chat text color and yellow gear
colorGreen      = "ff1eff00"; -- green gear, uncommon
colorWhite      = "ffffffff"; -- white gear, common
colorGrey       = "ff9d9d9d"; -- grey gear (worst)
colorBlue       = "ff20d0ff"; -- unknown gear, light blue
colorNone       = "ff808080";  -- default border color for gearslots on CharFrame
colorBlack      = "ff000000";
colorDarkBlue   = "ff0070dd";  -- item ITEM_RARITY rare dark blue
colorPurple     = "ffa335ee";  -- item ITEM_RARITY epic purple
colorGold       = "ffe5cc80";  -- item ITEM_RARITY artifact/heirloom gold

-- *** geartable
GEARLIST = {
    { name = GEARSLOT_HEAD, desc = GEAR_HEAD, minLevel = 1 },
    { name = GEARSLOT_NECK, desc = GEAR_NECK, minLevel = 1 },
    { name = GEARSLOT_SHOULDERS, desc = GEAR_SHOULDERS, minLevel = 1 },
    { name = GEARSLOT_BACK, desc = GEAR_BACK, minLevel = 1  },
    { name = GEARSLOT_CHEST, desc = GEAR_CHEST, minLevel = 1  },
    { name = GEARSLOT_SHIRT, desc = GEAR_SHIRT, minLevel = 0  }, -- minLevel = 0, since it's not a gear item with a gear score
    { name = GEARSLOT_TABARD, desc = GEAR_TABARD, minLevel = 0  }, -- minLevel = 0, since it's not a gear item with a gear score
    { name = GEARSLOT_WRIST, desc = GEAR_WRIST, minLevel = 1  },
    { name = GEARSLOT_HANDS, desc = GEAR_HANDS, minLevel = 1  },
    { name = GEARSLOT_WAIST, desc = GEAR_WAIST, minLevel = 1  },
    { name = GEARSLOT_LEGS, desc = GEAR_LEGS, minLevel = 1  },
    { name = GEARSLOT_FEET, desc = GEAR_FEET, minLevel = 1  },
    { name = GEARSLOT_FINGER1, desc = GEAR_FINGER1, minLevel = 1 },
    { name = GEARSLOT_FINGER2, desc = GEAR_FINGER2, minLevel = 1 },
    { name = GEARSLOT_TRINKET1, desc = GEAR_TRINKET1, minLevel = 1 },
    { name = GEARSLOT_TRINKET2, desc = GEAR_TRINKET2, minLevel = 1 },
    { name = GEARSLOT_MAINHAND, desc = GEAR_MAINHAND, minLevel = 1  },
    { name = GEARSLOT_OFFHAND, desc = GEAR_OFFHAND, minLevel = 1  }
};

-- set colors to match rarity
ITEM_RARITY = {
    { name= RARITY_POOR, color= colorGrey },
    { name= RARITY_COMMON, color= colorWhite },
    { name= RARITY_UNCOMMON, color= colorGreen },
    { name= RARITY_RARE, color= colorDarkBlue },
    { name= RARITY_EPIC, color= colorPurple },
    { name= RARITY_LEGENDARY, color= colorOrange },
    { name= RARITY_ARTIFACT, color= colorGold },
    { name= RARITY_HEIRLOOM, color= colorGold },
    { name= RARITY_UNKNOWN, color= colorBlue },
};

-- *** Gear stattypes
STATTYPES = {
    { text = STATTYPE_ARMOR },
    { text = STATYPE_STA },
    { text = STATYPE_INT },
    { text = STATYPE_AGI },
    { text = STATYPE_STR },
    { text = STATYPE_CRIT },
    { text = STATYPE_MASTERY },
    { text = STATYPE_VER },
    { text = STATYPE_HASTE },
    { text = STATYPE_BLOCK },
    { text = STATYPE_DODGE },
    { text = STATYPE_AVOID }
};

-- *** Legion artifact weapons
ARTIFACT_WEAPONS = {
    { text = ARTIFACT_DH_HAVOC },
    { text = ARTIFACT_DH_VENGEANCE },
    { text = ARTIFACT_DRUID_FERAL },
    { text = ARTIFACT_DRUID_GUARDIAN },
    { text = ARTIFACT_SHAMAN_ELEMENTAL },
    { text = ARTIFACT_SHAMAN_ENHANCEMENT },
    { text = ARTIFACT_SHAMAN_RESTORATION },
    { text = ARTIFACT_MAGE_FIRE },
    { text = ARTIFACT_PALY_PROT },
    { text = ARTIFACT_WARLOCK_DEMONOLOGY },
    { text = ARTIFACT_MONK_WINDWALKER },
    { text = ARTIFACT_WARRIOR_FURY },
    { text = ARTIFACT_WARRIOR_PROTECTION },
    { text = ARTIFACT_PRIEST_SHADOW },
    { text = ARTIFACT_ROGUE_SUBTLETY },
    { text = ARTIFACT_ROGUE_OUTLAW },
    { text = ARTIFACT_ROGUE_ASSASSINATION },
    { text = ARTIFACT_DK_FROST }
};

-- *** Two hand weapons
TWOHAND_WEAPONS = {
    { text = TWOHAND_AXES },
    { text = TWOHAND_MACES },
    { text = TWOHAND_SWORDS },
    { text = TWOHAND_STAVES },
    { text = TWOHAND_POLEARMS },
    { text = TWOHAND_BOWS },
    { text = TWOHAND_CROSSBOWS },
    { text = TWOHAND_GUNS },
    { text = TWOHAND_FISHING_POLES }
};

-- iLevel difference in percentage - mapped to shown color
-- table must be ordered decending by limit for the function to work correctly
AVG_GEAR_ILVL_COLOR_LIMIT = {
    { color= colorGrey,     limit=20 },
    { color= colorWhite,    limit=10 },
    { color= colorGreen,    limit=5 },
    { color= colorDarkBlue, limit=1 },
    { color= colorPurple,   limit=0 }
};
