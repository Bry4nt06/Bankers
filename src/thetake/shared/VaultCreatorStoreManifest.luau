local Manifest = {}

Manifest.Guns = {
	{assetId = 9153033862, itemId = "guns-compact-pistol", displayName = "Compact Pistol", subcategory = "Pistols", price = 750, creator = "@BrusselsFries"},
	{assetId = 5049754378, itemId = "guns-service-pistol", displayName = "Service Pistol", subcategory = "Pistols", price = 900, creator = "@FROSTYKZO"},
	{assetId = 432325599, itemId = "guns-pp19-smg", displayName = "PP-19 SMG", subcategory = "SMGs", price = 1400, creator = "@powphenom"},
	{assetId = 6095882053, itemId = "guns-ak47", displayName = "AK-47 Assault Rifle", subcategory = "Rifles", price = 2200, creator = "@lngram_Mac10"},
	{assetId = 8112820067, itemId = "guns-m16", displayName = "M16 Assault Rifle", subcategory = "Rifles", price = 2400, creator = "@FreerideFriendsYT"},
	{assetId = 108367100177607, itemId = "guns-t91", displayName = "T91 Assault Rifle", subcategory = "Rifles", price = 2600, creator = "@noobjrtge"},
	{assetId = 15814262005, itemId = "guns-trench-shotgun", displayName = "Trench Shotgun", subcategory = "Shotguns", price = 1900, creator = "@NitroQite"},
	{assetId = 16982970383, itemId = "guns-shotgun", displayName = "Tactical Shotgun", subcategory = "Shotguns", price = 2100, creator = "@LUTEN3310"},
	{assetId = 5659336337, itemId = "guns-sniper-rifle", displayName = "Sniper Rifle", subcategory = "SnipersHeavy", price = 3000, creator = "@KittensWarrior"},
	{assetId = 464785640, itemId = "guns-ksr29", displayName = "KSR-29 Sniper Rifle", subcategory = "SnipersHeavy", price = 3400, creator = "@whyatt"},
}

-- Gear is assigned to explicit wardrobe slots so only one item can occupy each
-- physical region. Fit hints are intentionally conservative because the importer
-- may resolve a different free-model source when a listed Store asset is unavailable.
Manifest.Gear = {
	{assetId = 4353344617, itemId = "gear-american-tactical-vest", displayName = "American Tactical Vest", price = 900, creator = "@ryan6475h", gearSlot = "Vest", fitScale = 0.90},
	{assetId = 8623886809, itemId = "gear-iotv", displayName = "IOTV Carrier", price = 1600, creator = "@pug1003", gearSlot = "Vest", fitScale = 0.88},
	{assetId = 71696740279397, itemId = "gear-plate-carrier", displayName = "Tactical Plate Carrier", price = 1500, creator = "@CyberLight6870", gearSlot = "Vest", fitScale = 0.90},
	{assetId = 7959512734, itemId = "gear-tactical-helmet", displayName = "Tactical Helmet", price = 850, creator = "@jmackity", gearSlot = "Headwear", fitScale = 0.92, fitOffsetY = 0.04},
	{assetId = 15823732569, itemId = "gear-ir-helmet", displayName = "IR Tactical Helmet", price = 950, creator = "@HC_x1269", gearSlot = "Headwear", fitScale = 0.92, fitOffsetY = 0.04},
	{assetId = 955376292, itemId = "gear-helmet-model", displayName = "Field Helmet", price = 650, creator = "@CastTorras", gearSlot = "Headwear", fitScale = 0.92, fitOffsetY = 0.03},
	{assetId = 18904041627, itemId = "gear-backpack", displayName = "Tactical Backpack", price = 800, creator = "@maurodebrawler", gearSlot = "Back", fitScale = 0.90},
	{assetId = 12198170201, itemId = "gear-mask", displayName = "Tactical Mask", price = 600, creator = "@Abs0lute_S0lver1", gearSlot = "FaceMask", fitScale = 0.88},
	{assetId = 14560919367, itemId = "gear-m50-mask", displayName = "M50 Gas Mask", price = 1100, creator = "@sanyigame1", gearSlot = "FaceMask", fitScale = 0.86},
}

Manifest.Emotes = {
	{assetId = 5582191351, itemId = "emote-animation-sauce", displayName = "Animation Sauce Pack", price = 450, creator = "@BaconChiips"},
	{assetId = 337428975, itemId = "emote-sit-classic", displayName = "Classic Sit", price = 250, creator = "@l7_7l"},
	{assetId = 12452064144, itemId = "emote-sit-updated", displayName = "Relaxed Sit", price = 300, creator = "X+ Interactive"},
	{assetId = 12400229318, itemId = "emote-sit-rigs", displayName = "Sit Pose Pack", price = 350, creator = "@dR44SH3r"},
	{assetId = 13865122898, itemId = "emote-sit-pack", displayName = "Social Sit Pack", price = 450, creator = "@BlibBlobfish"},
	{assetId = 5320687396, itemId = "emote-sitting", displayName = "Low Sit", price = 250, creator = "@mr_cheetozz"},
	{assetId = 4448247465, itemId = "emote-thriller", displayName = "Thriller Dance", price = 650, creator = "@UN_RBLX"},
	{assetId = 18877813560, itemId = "emote-dance-pack", displayName = "Dance Emote Pack", price = 700, creator = "@Manestronomer"},
	{assetId = 14998510373, itemId = "emote-dash-pack", displayName = "Dash Pose Pack", price = 500, creator = "@miklol45"},
	{assetId = 14879742898, itemId = "emote-movement-pack", displayName = "Movement Animation Pack", price = 750, creator = "@rladudtjs1999"},
}

Manifest.SafehouseFurniture = {
	{assetId = 92831953854222, itemId = "furniture-red-sofa", displayName = "Red Safehouse Sofa", price = 900, creator = "@MOMAZOSGG5"},
	{assetId = 11998719910, itemId = "furniture-modern-sofa", displayName = "Modern Sofa", price = 1100, creator = "@iLegend66"},
	{assetId = 14472011447, itemId = "furniture-compact-sofa", displayName = "Compact Sofa", price = 800, creator = "@slavik11omg"},
	{assetId = 70612024, itemId = "furniture-classic-sofa", displayName = "Classic Sofa", price = 650, creator = "@chilledjimmy6"},
	{assetId = 15132466502, itemId = "furniture-block-sofa", displayName = "Block Sofa", price = 700, creator = "@C_KS2009"},
	{assetId = 5724837940, itemId = "furniture-laptop-mesh", displayName = "Operations Laptop", price = 1200, creator = "@vicvic800"},
	{assetId = 97337325, itemId = "furniture-laptop", displayName = "Safehouse Laptop", price = 1000, creator = "@ihaveamac"},
	{assetId = 2639099812, itemId = "furniture-laptop-alt", displayName = "Intel Laptop", price = 1100, creator = "@Acura_ILX"},
	{assetId = 3745880927, itemId = "furniture-locker", displayName = "Equipment Locker", price = 950, creator = "@LocalGambino"},
	{assetId = 18170976469, itemId = "furniture-lockers", displayName = "Locker Bank", price = 1400, creator = "@seen_ees"},
}

Manifest.Loadouts = {
	{itemId = "loadout-street-entry", displayName = "Street Entry", price = 0, role = "Starter"},
	{itemId = "loadout-sidearm", displayName = "Sidearm Only", price = 300, role = "Pistol"},
	{itemId = "loadout-breacher", displayName = "Breacher", price = 800, role = "CloseQuarters"},
	{itemId = "loadout-rifleman", displayName = "Rifleman", price = 900, role = "Assault"},
	{itemId = "loadout-cqb", displayName = "Close Quarters", price = 1000, role = "CloseQuarters"},
	{itemId = "loadout-scout", displayName = "Scout", price = 950, role = "Mobility"},
	{itemId = "loadout-marksman", displayName = "Marksman", price = 1300, role = "Precision"},
	{itemId = "loadout-heavy", displayName = "Heavy", price = 1500, role = "Support"},
	{itemId = "loadout-stealth", displayName = "Stealth", price = 1250, role = "Infiltration"},
	{itemId = "loadout-crew-leader", displayName = "Crew Leader", price = 1750, role = "Command"},
}

return Manifest
