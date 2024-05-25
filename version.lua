--- Check if for client version
GSaddOn = {}
--- Addon is running on Classic Wrath client
--- @type boolean
GSaddOn.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

--- Addon is running on Classic "Vanilla" client: Means Classic Era and its seasons like SoM
---@type boolean
GSaddOn.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

--- Addon is running on Classic TBC client
--- client not supported/tested
---@type boolean
GSaddOn.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
