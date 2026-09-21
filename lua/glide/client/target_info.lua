local TEXT_COLOR = Color( 255, 255, 255, 255 )
local BG_COLOR = Color( 20, 20, 20, 230 )

local Floor = math.floor
local Clamp = math.Clamp

local GetTextSize = surface.GetTextSize
local DrawRoundedBox = draw.RoundedBoxEx
local DrawSimpleText = draw.SimpleText

local DrawRect = surface.DrawRect
local SetColor = surface.SetDrawColor

local function DrawPlayerTag( ply, health, pos )
    pos = pos:ToScreen()

    local nick = ply:Nick()
    local screenH = ScrH()

    local color = TEXT_COLOR
    local returnedColor, returnedName = hook.Run( "Glide_PlayerTagColor", ply, nick, health )
    if returnedColor and IsColor( returnedColor ) then
        color = returnedColor
    end
    if returnedName and isstring( returnedName ) then
        nick = returnedName
    end

    surface.SetFont( "GlideSelectedWeapon" )

    local w, h = GetTextSize( nick )
    local minW = Floor( screenH * 0.15 )
    local padding = Floor( screenH * 0.004 )

    w = Clamp( w, minW, screenH ) + padding * 2
    h = h + padding * 2

    local x = pos.x - w * 0.5
    local y = pos.y - h * 1.5

    DrawRoundedBox( screenH * 0.005, x, y, w, h, BG_COLOR, true, true, false, false )
    DrawSimpleText( nick, "GlideSelectedWeapon", x + w * 0.5, y + h * 0.5, color, 1, 1 )

    if health < 0 then return x, y + h, w end

    y = y + h
    h = h * 0.25

    SetColor( 0, 0, 0, 255 )
    DrawRect( x, y, w, h )

    SetColor( 255 * ( 1 - health ), 255 * health, 0, 255 )
    DrawRect( x, y, w * health, h )

    return x, y + h, w
end

local IsValid = IsValid
local FrameTime = FrameTime
local LocalPlayer = LocalPlayer
local SetAlphaMultiplier = surface.SetAlphaMultiplier

local Config = Glide.Config
local Camera = Glide.Camera
local lastTarget, alpha = NULL, 0

hook.Add( "HUDDrawTargetID", "Glide.HUDDrawTargetID", function()
    return 
end, HOOK_HIGH )
