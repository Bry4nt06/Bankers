local RobberLoadouts = {}

-- Optional per-rig override. Add a String attribute named "BankersLoadout"
-- to a Workspace Rig and set it to one of the loadout names below.
RobberLoadouts.AttributeName = "BankersLoadout"

-- Dark base layer so uncovered body sections do not remain mannequin-gray.
RobberLoadouts.DefaultBaseColor = Color3.fromRGB(31, 32, 35)

-- Catalog accessories are intentionally stored as plain asset IDs. The outfit
-- service resolves each asset's real Roblox AvatarAssetType at runtime and maps
-- it to the correct AccessoryType before applying the HumanoidDescription.
-- This avoids brittle guesses such as forcing a plate carrier into FrontAccessory.
--
-- Current first-pass tactical set:
-- 8029037582      Black Balaclava Mask
-- 11625241138     Black Balaclava Mask (alternate)
-- 13767886091     Black Balaclava Fireproof
-- 135255866303272 Black Balaclava Goggles
-- 12346732650     Black Tactical Helmet
-- 108580204164661 Black Tactical Helmet w Face Cover
-- 4036737464      Black Tactical Headset
-- 14121776793     Black RBT 6094 Plate Carrier [REDUX]
-- 18760009752     Black ARK V2 Plate Carrier
-- 7436118586      Black Tactical Plate Carrier
-- 10313042102     Black Hexagonal Plate Carrier
-- 14976131187     Black Tactical Vest w/ C3PHONE
-- 13612166113     Black Military Duffel Bag
-- 15554854767     Black Beanie

RobberLoadouts.Loadouts = {
	{
		Name = "CrewLeader",
		DisplayName = "Crew Leader",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
		},
		CatalogAccessories = {
			4036737464,
			8029037582,
			14121776793,
		},
		AccessoryAssets = {},
	},
	{
		Name = "Breacher",
		DisplayName = "Breacher",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
		},
		CatalogAccessories = {
			108580204164661,
			18760009752,
		},
		AccessoryAssets = {},
	},
	{
		Name = "Bagman",
		DisplayName = "Bagman",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
		},
		CatalogAccessories = {
			11625241138,
			7436118586,
			13612166113,
		},
		AccessoryAssets = {},
	},
	{
		Name = "Lookout",
		DisplayName = "Lookout",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
		},
		CatalogAccessories = {
			15554854767,
			135255866303272,
			10313042102,
		},
		AccessoryAssets = {},
	},
	{
		Name = "Driver",
		DisplayName = "Driver",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
		},
		CatalogAccessories = {
			4036737464,
			13767886091,
			14976131187,
		},
		AccessoryAssets = {},
	},
}

return RobberLoadouts
