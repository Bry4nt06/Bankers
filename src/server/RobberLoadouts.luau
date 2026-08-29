local RobberLoadouts = {}

-- Optional per-rig override. Add a String attribute named "BankersLoadout"
-- to a Workspace Rig and set it to one of the loadout names below.
RobberLoadouts.AttributeName = "BankersLoadout"

-- Dark base layer so uncovered R15 body sections do not remain mannequin-gray.
RobberLoadouts.DefaultBaseColor = Color3.fromRGB(31, 32, 35)

-- First-pass catalog set. These are intentionally centralized so we can swap
-- individual pieces without touching the outfitting logic.
--
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

-- HumanoidDescription accessory properties use comma-separated catalog asset IDs.
-- AccessoryAssets remains available for game-owned/custom accessory assets loaded
-- directly through InsertService.
RobberLoadouts.Loadouts = {
	{
		Name = "CrewLeader",
		DisplayName = "Crew Leader",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
			HatAccessory = "4036737464",
			FaceAccessory = "8029037582",
			FrontAccessory = "14121776793",
			BackAccessory = "",
			WaistAccessory = "",
			JacketAccessory = "",
			ShirtAccessory = "",
			PantsAccessory = "",
			LeftShoeAccessory = "",
			RightShoeAccessory = "",
		},
		AccessoryAssets = {
			Mask = 0,
			Headgear = 0,
			PlateCarrier = 0,
			Gloves = 0,
			Radio = 0,
			KneePads = 0,
			Bag = 0,
		},
	},
	{
		Name = "Breacher",
		DisplayName = "Breacher",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
			HatAccessory = "108580204164661",
			FaceAccessory = "",
			FrontAccessory = "18760009752",
			BackAccessory = "",
			WaistAccessory = "",
			JacketAccessory = "",
			ShirtAccessory = "",
			PantsAccessory = "",
			LeftShoeAccessory = "",
			RightShoeAccessory = "",
		},
		AccessoryAssets = {
			Mask = 0,
			Headgear = 0,
			PlateCarrier = 0,
			Gloves = 0,
			Radio = 0,
			KneePads = 0,
			Bag = 0,
		},
	},
	{
		Name = "Bagman",
		DisplayName = "Bagman",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
			HatAccessory = "",
			FaceAccessory = "11625241138",
			FrontAccessory = "7436118586",
			BackAccessory = "13612166113",
			WaistAccessory = "",
			JacketAccessory = "",
			ShirtAccessory = "",
			PantsAccessory = "",
			LeftShoeAccessory = "",
			RightShoeAccessory = "",
		},
		AccessoryAssets = {
			Mask = 0,
			Headgear = 0,
			PlateCarrier = 0,
			Gloves = 0,
			Radio = 0,
			KneePads = 0,
			Bag = 0,
		},
	},
	{
		Name = "Lookout",
		DisplayName = "Lookout",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
			HatAccessory = "15554854767",
			FaceAccessory = "135255866303272",
			FrontAccessory = "10313042102",
			BackAccessory = "",
			WaistAccessory = "",
			JacketAccessory = "",
			ShirtAccessory = "",
			PantsAccessory = "",
			LeftShoeAccessory = "",
			RightShoeAccessory = "",
		},
		AccessoryAssets = {
			Mask = 0,
			Headgear = 0,
			PlateCarrier = 0,
			Gloves = 0,
			Radio = 0,
			KneePads = 0,
			Bag = 0,
		},
	},
	{
		Name = "Driver",
		DisplayName = "Driver",
		Description = {
			Shirt = 0,
			Pants = 0,
			GraphicTShirt = 0,
			HatAccessory = "4036737464",
			FaceAccessory = "13767886091",
			FrontAccessory = "14976131187",
			BackAccessory = "",
			WaistAccessory = "",
			JacketAccessory = "",
			ShirtAccessory = "",
			PantsAccessory = "",
			LeftShoeAccessory = "",
			RightShoeAccessory = "",
		},
		AccessoryAssets = {
			Mask = 0,
			Headgear = 0,
			PlateCarrier = 0,
			Gloves = 0,
			Radio = 0,
			KneePads = 0,
			Bag = 0,
		},
	},
}

return RobberLoadouts
