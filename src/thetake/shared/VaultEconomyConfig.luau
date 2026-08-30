local Config = {
	StartingCash = 5000,
	ProfileStoreName = "TheTakeVaultProfile_v1",

	-- Keep the original item id so existing ownership data remains valid.
	DefaultGearId = "skins-default-crew",
	DefaultGearDisplayName = "Crew Standard",
	DefaultGearPrice = 0,
	DefaultGearCurrency = "Cash",
}

-- Legacy aliases for profiles/code created before SKINS was renamed to GEAR.
Config.DefaultSkinId = Config.DefaultGearId
Config.DefaultSkinDisplayName = Config.DefaultGearDisplayName
Config.DefaultSkinPrice = Config.DefaultGearPrice
Config.DefaultSkinCurrency = Config.DefaultGearCurrency

return Config
