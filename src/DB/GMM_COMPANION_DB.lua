local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local default =
{
  meta = {
    schemaVersion = 1,
    createdAt = time(),
    lastUpdated = time(),
  },
  ["profile"] = {

    global = {
      pets = { -- to set: [petGUID] = true

      },
      order = {},
      total = 0
    },
    continents = {
      -- keyed using UiMapID
      -- [12] = { pets = {}} (Kalimdor)

    },
    zones = {
      -- zones[continentID][zoneUiMapID] = { pets = {}}
      --[[
      [101] = { -- Outland
      [107] = { -- Nagrand
      pets = { }
      },
      [104] = { -- Shadowmoon Valley (Outland)
      pets = { }
      }
      }
      ]] --
    }
  },
  ["char"] = {
    outfits = {
      -- [outfitID] = { pets = {}, order = {}, total = 0}
    }
  }
}

function mod:RefreshProfilePointers()
  self.dbp = self.CompanionDB.profile
  self.dbc = self.CompanionDB.char
end

function mod:InitializeCompanionDatabase()
  self.CompanionDB = LibStub("AceDB-3.0"):New("GMM_COMPANIONS_DB", default, true)
  self:RefreshProfilePointers()

  self.CompanionDB.RegisterCallback(self, "OnProfileChanged", "OnAceDBProfileEvent")
  self.CompanionDB.RegisterCallback(self, "OnProfileCopied", "OnAceDBProfileEvent")
  self.CompanionDB.RegisterCallback(self, "OnProfileReset", "OnAceDBProfileEvent")
  self:EnsureGlobal()
end

function mod:OnAceDBProfileEvent(...)
  self:RefreshProfilePointers()
  -- self:RefreshUI() if UI References Data
end

function mod:EnsureGlobal()
  local g = self.dbp.global or { pets = {}, order = {}, total = 0 }

  g.pets = g.pets or {}
  g.order = g.order or {}
  g.total = g.total or 0

  self.dbp.global = g
  return g
end

function mod:EnsureContinent(continentID)
  self.dbp.continents = self.dbp.continents or {}
  local c = self.dbp.continents[continentID]
  if not c then
    c = { pets = {}, order = {}, total = 0 }
    self.dbp.continents[continentID] = c
  end
  return c
end

function mod:EnsureZone(continentID, zoneID)
  self.dbp.zones = self.dbp.zones or {}
  self.dbp.zones[continentID] = self.dbp.zones[continentID] or {}
  local z = self.dbp.zones[continentID][zoneID]
  if not z then
    z = { pets = {}, order = {}, total = 0 }
  end
  return z
end

function mod:EnsureOutfit(outfitID)
  self.dbc.outfits = self.dbc.outfits or {}
  local o = self.dbc.outfits[outfitID]
  if not o then
    o = { pets = {}, order = {}, total = 0 }
    self.dbc.outfits[outfitID] = o
  end
  return o
end

function mod:AddPet(list, petGUID)
  list.pets = list.pets or {}
  list.order = list.order or {}
  list.total = list.total or 0

  if not list.pets[petGUID] then
    list.pets[petGUID] = true
    table.insert(list.order, petGUID)
    list.total = (list.total or 0) + 1
    return true
  end
  return false
end

function mod:RemovePet(list, petGUID)
  if list and list.pets and list.pets[petGUID] then
    list.pets[petGUID] = nil
    for i, id in ipairs(list.order) do
      if id == petGUID then
        table.remove(list.order, i)
        break
      end
    end
    list.total = math.max((list.total or 1) - 1, 0)
    return true
  end
  return false
end

function mod:GetCurrentPetList(mapID, outfitID, continentID)
  -- 1) Outfit
  if outfitID and self.dbc.outfits and self.dbc.outfits[outfitID] then
    return self.dbc.outfits[outfitID]
  end

  -- 2) Zone
  if continentID and mapID and self.dbp.zones and self.dbp.zones[continentID] then
    local zl = self.dbp.zones[continentID][mapID]
    if zl then return zl end
  end

  -- 3) Continent
  if continentID and self.dbp.continents and self.dbp.continents[continentID] then
    return self.dbp.continents[continentID]
  end

  -- 4 ) Global Default
  return self:EnsureGlobal()
end
