TS_DeathAnim = TS_DeathAnim or {}

TS_DeathAnim.HeadClub = {
	Rate = 0.95,
	FaceHoldChance = 0.65,
	Model = "models/teeth/tooth.mdl",
	SubModels = 4,
	BodyGroup = 0,
	TeethMin = 7,
	TeethMax = 11,
	TeethStep = 0.045,
	TeethScaleMin = 1,
	TeethScaleMax = 1.8,
	TeethMass = 0.05,
	TeethSpeedMin = 55,
	TeethSpeedMax = 130,
	TeethLife = 40,
	TeethMaxLive = 72,
	BluntSound = "kill/blunt/trb_bluntkill.wav",
	TeethSound = "kill/blunt/trb_teethout.wav",
	MouthMale = Vector(5, 0, 1.5),
	MouthFemale = Vector(4, 0, 1),
	GoreTime = 12,
	MaxGore = 8,
	DrawDist = 1000
}
