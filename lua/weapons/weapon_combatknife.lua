if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Combat Knife"
SWEP.Instructions = "A military grade combat knife designed to neutralize the enemy during combat operations and special operations.\n\nLMB to attack.\nHold LMB to charge a thrust, release to attack.\nLMB then R to change attack mode.\nRMB to block."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 1

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.WorldModel = "models/weapons/combatknife/tactical_knife_iw7_wm.mdl"
SWEP.WorldModelReal = "models/weapons/combatknife/tactical_knife_iw7_vm.mdl"
SWEP.WorldModelExchange = false
SWEP.ViewModel = ""
SWEP.HoldType = "knife"
SWEP.weight = 0.4

SWEP.ImmobilizationMul = 2
SWEP.StaminaMul = 0.5
SWEP.BreakBoneMul = 0.5
SWEP.ShockMultiplier = 0.5
SWEP.PainMultiplier = 2

SWEP.AnimList = {
    ["idle"] = "vm_knifeonly_idle",
    ["deploy"] = "vm_knifeonly_raise",
    ["attack"] = "vm_knifeonly_stab",
    ["attack2"] = "vm_knifeonly_swipe",
    ["charge_begin"] = "vm_knifeonly_raise",
    ["charge_idle"] = "vm_knifeonly_idle",
    ["charge_end"] = "vm_knifeonly_stab",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_iw7_tactical_knife")
	SWEP.IconOverride = "vgui/hud/tfa_iw7_tactical_knife.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.AttackSwing = "weapons/slam/throw.wav"
SWEP.AttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
SWEP.AttackHitFlesh = "snd_jack_hmcd_knifestab.wav"
SWEP.Attack2HitFlesh = "snd_jack_hmcd_slash.wav"
SWEP.DeploySnd = "snd_jack_hmcd_knifedraw.wav"
SWEP.BackstabSound = "trb_backstab.ogg"

SWEP.SuicidePos = Vector(5, -24, 5)
SWEP.SuicideAng = Angle(0, 90, 20)
SWEP.SuicideCutVec = Vector(2, -5, 6)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.CanSuicide = true

SWEP.AttackTime = 0.2
SWEP.AnimTime1 = 0.7
SWEP.WaitTime1 = 0.5
SWEP.AttackLen1 = 55

SWEP.Attack2Time = 0.1
SWEP.AnimTime2 = 0.6
SWEP.WaitTime2 = 0.4
SWEP.AttackLen2 = 45

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 15
SWEP.DamageSecondary = 8

SWEP.PenetrationPrimary = 8
SWEP.PenetrationSecondary = 4

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 0.75
SWEP.PenetrationSizeSecondary = 2.5

SWEP.StaminaPrimary = 10
SWEP.StaminaSecondary = 8.5

SWEP.ViewPunch1 = Angle(2,0,0)
SWEP.ViewPunch2 = Angle(0,1,0)

SWEP.AttackSize = 5

SWEP.canchargeattack = false
SWEP.ChargeAnimTimeBegin = 0.25
SWEP.ChargeAnimTimeIdle = 0.35
SWEP.ChargeAnimTimeEnd = 0.55
SWEP.ChargeFullTime = 0.5
SWEP.ChargeAttackTime = 0.2
SWEP.ChargeWaitTime = 0.5
SWEP.ChargeAttackLen = 65
SWEP.ChargeAttackTimeLength = 0.15
SWEP.ChargeAttackRads = 30
SWEP.ChargeSwingAng = -90
SWEP.ChargeStamina = 18
SWEP.ChargePenetration = 12
SWEP.ChargePenetrationSize = 0.6
SWEP.ChargeDamageMul = 1.7
SWEP.ChargeBreakBoneMul = 1.35
SWEP.ChargeTapCancelTime = 0.25
SWEP.ChargeViewPunch = Angle(4,0,0)
SWEP.ChargeHoldPos = Vector(-12,3,-3)
SWEP.ChargeHoldAng = Angle(-14,7,0)
SWEP.ChargeHoldLerpSpeed = 0.12
SWEP.ChargeAttackSwing = "weapons/slam/throw.wav"
SWEP.ChargeAttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.ChargeAttackHitFlesh = "snd_jack_hmcd_knifestab.wav"

SWEP.weaponPos = Vector(2,0.1,-0.8)
SWEP.weaponAng = Angle(180,90,90)

SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false

SWEP.attack_ang = Angle(-55,-3,0)
SWEP.sprint_ang = Angle(30,0,0)

SWEP.HoldPos = Vector(-10,3,-2)
SWEP.HoldAng = Angle(-10,5,0)

SWEP.basebone = 1

SWEP.AttackPos = Vector(0,0,-10)
SWEP.AttackingPos = Vector(16,0,0)

SWEP.WorkWithFake = true

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_ATTACK) then
            self:CancelChargeAttack(false)
            self:SetNetVar("mode", not self:GetNetVar("mode"))
            self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
        end
    end
end

function SWEP:CanPrimaryAttack()
    if hg.KeyDown(self:GetOwner(), IN_RELOAD) then return end
    if not self:GetNetVar("mode") then
        return true
    else
        self.allowsec = true
        self:SecondaryAttack(true)
        self.allowsec = nil
        return false
    end
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

function SWEP:CustomBlockAnim(addPosLerp, addAngLerp)
    addPosLerp.z = addPosLerp.z + (self:GetBlocking() and 5 or 0)
    addPosLerp.x = addPosLerp.x + (self:GetBlocking() and 2 or 0)
    addPosLerp.y = addPosLerp.y + (self:GetBlocking() and -18 or 0)
    addAngLerp.r = addAngLerp.r + (self:GetBlocking() and 20 or 0)
    addAngLerp.y = addAngLerp.y + (self:GetBlocking() and 60 or 0)

    return true
end
