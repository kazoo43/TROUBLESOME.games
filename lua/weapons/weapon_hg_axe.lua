if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Woodcutting axe"
SWEP.Instructions = "An axe is an implement that has been used for millennia to shape, split, and cut wood. Can break down doors.\n\nLMB to attack.\nRMB to block."
SWEP.Category = "Weapons - Melee"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/props/cs_militia/axe.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_bat_metal.mdl"
SWEP.WorldModelExchange = "models/props/cs_militia/axe.mdl"
SWEP.ViewModel = ""

SWEP.SuicidePos = Vector(0, -1, -26)
SWEP.SuicideAng = Angle(-70, 50, -30)
SWEP.SuicideCutVec = Vector(-2, 4, -3)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "player/flesh/flesh_bullet_impact_03.wav"
SWEP.CanSuicide = true
SWEP.SuicideNoLH = false
SWEP.SuicideHoldType = "slam"

SWEP.Weight = 0
SWEP.weight = 2.5

SWEP.HoldType = "pistol"

SWEP.HoldPos = Vector(-9, 0, 0)
SWEP.HoldAng = Angle(0, 0, -20)

SWEP.AttackTime = 0.48
SWEP.AnimTime1 = 2
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1, 1, -1)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0, 0, -2)

SWEP.attack_ang = Angle(0, 0, 0)
SWEP.sprint_ang = Angle(15, 0, 0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0, 0, 0.5)
SWEP.weaponAng = Angle(0, -90, -13)

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
    --[[ charge disabled, this model has no charge sequences, ported from remorseism weapon_hg_axe
    ["charge_begin"] = "Attack_Charge_Begin",
    ["charge_idle"] = "Attack_Charge_Idle",
    ["charge_end"] = "Attack_Charge_End",
    ]]
}

--[[ charge disabled, this model has no charge sequences, ported from remorseism weapon_hg_axe
SWEP.canchargeattack = true
SWEP.ChargeAnimTimeBegin = 0.55
SWEP.ChargeAnimTimeIdle = 0.6
SWEP.ChargeAnimTimeEnd = 0.95
SWEP.ChargeFullTime = 0.85
SWEP.ChargeAttackTime = 0.36
SWEP.ChargeWaitTime = 1.3
SWEP.ChargeAttackLen = 70
SWEP.ChargeAttackTimeLength = 0.24
SWEP.ChargeAttackRads = 85
SWEP.ChargeSwingAng = -78
SWEP.ChargeStamina = 48
SWEP.ChargePenetration = 8
SWEP.ChargePenetrationSize = 6.5
SWEP.ChargeDamage = 80
SWEP.ChargeTapCancelTime = 0.55
SWEP.ChargeViewPunch = Angle(12, 0, 0)
SWEP.ChargeHoldPos = Vector(-7, -5, -1)
SWEP.ChargeAttackHit = "Canister.ImpactHard"
SWEP.ChargeAttackHitFlesh = "snd_jack_hmcd_axehit.wav"
]]

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 42
SWEP.DamageSecondary = 14

SWEP.PenetrationPrimary = 10
SWEP.PenetrationSecondary = 3

SWEP.MaxPenLen = 10

SWEP.PenetrationSizePrimary = 5.5
SWEP.PenetrationSizeSecondary = 1.5

SWEP.StaminaPrimary = 40
SWEP.StaminaSecondary = 15

SWEP.AttackLen1 = 65
SWEP.AttackLen2 = 40

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_axe")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_axe"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true


SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)

SWEP.NoHolster = true

SWEP.AnimAlwaysBack = true

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 75
SWEP.AttackRads2 = 0

SWEP.SwingAng = -20
SWEP.SwingAng2 = 0

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end

--[[ function SWEP:CanChargeAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    self.ChargeAttackHit = "Canister.ImpactHard"
    self.ChargeAttackHitFlesh = "snd_jack_hmcd_axehit.wav"
    return true
end ]]

function SWEP:CanSecondaryAttack()
    --[[self.DamageType = DMG_CLUB
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"--]]
    return false
end

function SWEP:PrimaryAttackAdd(ent)
    if hgIsDoor(ent) and math.random(7) > 3 then
        hgBlastThatDoor(ent,self:GetOwner():GetAimVector() * 50 + self:GetOwner():GetVelocity())
    end
end

SWEP.MinSensivity = 0.7

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeVPShouldUseHand = false
SWEP.FakeViewBobBaseBone = "base"
SWEP.ViewPunchDiv = 50