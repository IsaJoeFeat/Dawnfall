-- Body and gun
local Base = piece "Base"
local Body = piece "Body"
local Turret = piece "Turret"
local TurretBuilder = piece "TurretMuzzle"
local Flare = piece "Flare"
local Stem = piece "Stem"
local Door1 = piece "Door1"
local Door2 = piece "Door2"
local DoorHolder1 = piece "DoorHolder1"
local DoorHolder2 = piece "DoorHolder2"
aimSpeed = 3.0

local SIG_BUILD = 1

Spring.SetUnitNanoPieces(unitID, { Flare })

local function Restore()
Signal (SIG_BUILD)
	SetSignalMask (SIG_BUILD)
Sleep(2000)
     Turn(Turret, y_axis, 0, aimSpeed)
    Turn(Flare, y_axis, 0, 1)
	WaitForTurn(Turret, y_axis)
	WaitForTurn(Flare, y_axis)
	Move(Stem, y_axis, 0,15)
	WaitForMove(Stem, y_axis)
	Turn(Door1, z_axis, math.rad(0), math.rad(300))
	Turn(Door2, z_axis, math.rad(0), math.rad(300))
	WaitForTurn(Door1, z_axis)
	WaitForTurn(Door2, z_axis)	
end

local function Startup()
	Turn(Door1, z_axis, math.rad(215), math.rad(300))
	Turn(Door2, z_axis, math.rad(-215), math.rad(300))
	WaitForTurn(Door1, z_axis)
	WaitForTurn(Door2, z_axis)
	Move(Stem, y_axis, 15,15)
	WaitForMove(Stem, y_axis)
	 SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.Create()
end


function script.QueryNanoPiece()
    local nano = nanoPieces[nanoNum]
    return nano
end

function script.StartBuilding(heading, pitch)
Signal (SIG_BUILD)
	SetSignalMask (SIG_BUILD)
	StartThread(Startup)
    Turn(Turret, y_axis, heading, aimSpeed)
    Turn(Flare, y_axis, math.rad(heading), 1)
	WaitForTurn(Turret, y_axis)
    SetUnitValue(COB.INBUILDSTANCE, 1)

end

function script.StopBuilding()
SetUnitValue(COB.INBUILDSTANCE, 0)
StartThread(Restore)
end


---death animation
function script.Killed(recentDamage, maxHealth, corpsetype)
	Explode (Body, SFX.SHATTER)
	local severity = recentDamage / maxHealth
	if severity <= 0.33 then
	return 1
	else
	return 2 
	end         
end