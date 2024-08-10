local _, addonTable = ...
local addOn = addonTable.addOn

addOn.PetJournal = {}

-- Iterates over ALL Pets in PetJounal, returning all values from GetPetInfoByIndex.
-- see: https://warcraft.wiki.gg/wiki/API_C_PetJournal.GetPetInfoByIndex
function addOn.PetJournal:CompanionIterator()
  local iterator = 0
  local numPets, numOwned = C_PetJournal.GetNumPets();
  -- Clear Filters, if We dont' do this, we may not find any pets in the filter
  C_PetJournal.ClearSearchFilter()

  if not C_PetJournal.IsUsingDefaultFilters() then
    C_PetJournal.SetDefaultFilters()
  end
  return function()
    iterator = iterator + 1
    if iterator <= numPets then
      return C_PetJournal.GetPetInfoByIndex(iterator)
    end
  end
end

function addOn.PetJournal:GetSimplePetTable(petID)
  local wowPetTable = C_PetJournal.GetPetInfoTableByPetID(petID)

  return {
    petID = petID,
    customName = wowPetTable["customName"],
    displayID = wowPetTable["displayID"],
    isFavorite = wowPetTable["isFavorite"],
    icon = wowPetTable["icon"],
    name = wowPetTable["name"],
  }
end
