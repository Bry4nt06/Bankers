local PvPConfig = {}

PvPConfig.Mode = "FFA"
PvPConfig.RespawnSeconds = 3
PvPConfig.SpawnProtectionSeconds = 2
PvPConfig.MaxHealth = 100

PvPConfig.Movement = {
	WalkSpeed = 15.5,
	SprintSpeed = 23,
	CrouchSpeed = 9,
	JumpPower = 48,
	SlideSpeed = 30,
	SlideEndSpeed = 16,
	SlideDuration = 0.55,
	SlideCooldown = 1.0,
	ADSMoveMultiplier = 0.72,
}

PvPConfig.Camera = {
	BaseFov = 72,
	SprintFov = 78,
	ADSFov = 58,
	CrouchOffset = Vector3.new(0, -1.1, 0),
	ShoulderOffset = Vector3.new(1.9, 0.8, 0),
	HipZoomMin = 7,
	HipZoomMax = 9,
	ADSZoomMin = 5.5,
	ADSZoomMax = 6.5,
}

return PvPConfig
