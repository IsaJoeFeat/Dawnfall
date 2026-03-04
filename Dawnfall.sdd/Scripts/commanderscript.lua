-- Body and gun
local Base = piece "Base"
local Body = piece "Body"
local Turret = piece "Turret"
local MiniTurret1 = piece "MiniTurret1"
local MiniTurret2 = piece "MiniTurret2"
local MiniTurretMuzzle1 = piece "MiniTurretMuzzle1"
local MiniTurretMuzzle2 = piece "MiniTurretMuzzle2"
local Flare1 = piece "Flare1"
local Flare2 = piece "Flare2"
local Flare3 = piece "Flare3"
local Laser = 1
local LaserNumber = 2
aimSpeed = 3.0
local on = true
Spring.SetUnitNanoPieces(unitID, { Flare3 })

local SIG_AIM = 1
local SIG_BUILD = 2
local function Restore1()
Sleep(2000)
    Turn(Turret, y_axis, 0, aimSpeed)
    Turn(MiniTurret1, x_axis, 0, aimSpeed)
	Turn(MiniTurret2, x_axis, 0, aimSpeed)
    WaitForTurn(Turret, y_axis)
	WaitForTurn(MiniTurret1, x_axis)
	WaitForTurn(MiniTurret2, x_axis)
end



local function Restore2()
Signal (SIG_BUILD)
	SetSignalMask (SIG_BUILD)
Sleep(3000)
     Turn(Turret, y_axis, 0, aimSpeed)
	WaitForTurn(Turret, y_axis)
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
    Turn(Turret, y_axis, heading, aimSpeed)
	WaitForTurn(Turret, y_axis)
    SetUnitValue(COB.INBUILDSTANCE, 1)

end

function script.StopBuilding()
SetUnitValue(COB.INBUILDSTANCE, 0)
StartThread(Restore2)
end


----aimining & fire weapon
function script.AimFromWeapon1() 
	return Turret
	
end

function script.QueryWeapon1()
	if (Laser == 1) then return Flare1 end
	if (Laser == 2) then return Flare2 end
end

function script.AimWeapon1( heading, pitch )
	Signal(SIG_AIM)
    SetSignalMask(SIG_AIM)
    Turn(Turret, y_axis, heading, aimSpeed)
    Turn(MiniTurret1, x_axis, -pitch, aimSpeed)
	Turn(MiniTurret2, x_axis, -pitch, aimSpeed)
    WaitForTurn(Turret, y_axis)
	StartThread(Restore1)
    return true

end

function script.FireWeapon1()	
	--switch to the next barrel:
	Laser = Laser + 1
	--if all barrels have fired, start the cyclus from the beginning:
	if (Laser > LaserNumber) then Laser = 1 end
end

----aimining & fire weapon
function script.AimFromWeapon2() 
	return Turret
	
end

function script.QueryWeapon2()
	 return Flare3 
end

function script.AimWeapon2( heading, pitch )
	Signal(SIG_AIM)
    SetSignalMask(SIG_AIM)
    Turn(Turret, y_axis, heading, aimSpeed)
    WaitForTurn(Turret, y_axis)
	StartThread(Restore1)
    return true

end

function script.FireWeapon2()	

end

function script.Killed(recentDamage, maxHealth, corpsetype)
	Explode (Body, SFX.SHATTER)
	local severity = recentDamage / maxHealth
	if severity <= 0.33 then
	return 1
	else
	return 2 
	end
end