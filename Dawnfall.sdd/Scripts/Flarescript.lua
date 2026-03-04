-- Body and gun
local Base = piece "Base"
local Body = piece "Body"
local Turret = piece "Turret"
local TurretMuzzle = piece "TurretMuzzle"
local Flare = piece "Flare"
-- Wheels
local Wheel1 = piece "Wheel1"
local Wheel2 = piece "Wheel2"
local wheel_speed = math.rad(200)
aimSpeed = 4.0
--effects
--local huntermuzzleflash = SFX.CEG

function script.Create()
	
end

SIG_DELAYEDSTOP = 1
SIG_AIM = 2
local function RestoreAfterDelay()
Sleep(2000)
Turn(Turret, y_axis, 0, aimSpeed)
Turn(TurretMuzzle, x_axis, 0, aimSpeed)
    WaitForTurn(Turret, y_axis)
	WaitForTurn(TurretMuzzle, x_axis)
end

function script.StartMoving()
    Signal(SIG_DELAYEDSTOP)
    Spin(Wheel1, x_axis, wheel_speed)
    Spin(Wheel2, x_axis, wheel_speed)
end

function script.StopMoving()
    StartThread(delayedStopAnimation)
end


function delayedStopAnimation()
    Signal(SIG_DELAYEDSTOP)
    SetSignalMask(SIG_DELAYEDSTOP)
    Sleep(250)
    StopSpin (Wheel1,x_axis)
    StopSpin (Wheel2,x_axis)
end

----aimining & fire weapon
function script.AimFromWeapon1() 
	return Turret
	
end

function script.QueryWeapon1() 
	return Flare 
end

function script.AimWeapon1( heading, pitch )
	Signal(SIG_AIM)
    SetSignalMask(SIG_AIM)
    Turn(Turret, y_axis, heading, aimSpeed)
    Turn(TurretMuzzle, x_axis, -pitch, aimSpeed)
    WaitForTurn(Turret, y_axis)
	StartThread(RestoreAfterDelay)
    return true
end

function script.FireWeapon1()
		--EmitSfx(Flare, huntermuzzleflash)
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