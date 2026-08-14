local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local Utilities = addOn.Utilities

function Utilities:DispatchIfInCombatLockdown(action, msg)
  if InCombatLockdown() then
    addOn:Print(msg);
    addOn:RegisterEvent("PLAYER_REGEN_ENABLED", function(...)
      addOn:UnregisterEvent("PLAYER_REGEN_ENABLED")
      action()
    end)
  else
    action()
  end
end
