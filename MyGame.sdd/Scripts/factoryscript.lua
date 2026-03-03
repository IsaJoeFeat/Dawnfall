-- Body
local Base = piece "Base"
local Wall1 = piece "Wall1"
local Wall2 = piece "Wall2"
local Turret1 = piece "Turret1"
local Turret2 = piece "Turret2"
local Turret3 = piece "Turret3"
local Turret4 = piece "Turret4"
local Flare1 = piece "Flare1"
local Flare2 = piece "Flare2"
local Flare3 = piece "Flare3"
local Flare4 = piece "Flare4"
local BuildSpot = piece "BuildSpot"
aimSpeed = 3.0


function script.Create()

end

function script.QueryBuildInfo() 
	return BuildSpot
end

local function Open()
Move(Wall1, x_axis, 25, 25)
Move(Wall2, x_axis, -25, 25)
WaitForMove(Wall1, x_axis)
WaitForMove(Wall2, x_axis)
SetUnitValue(COB.INBUILDSTANCE, 1)
SetUnitValue(COB.YARD_OPEN, 1)
SetUnitValue(COB.BUGGER_OFF, 1)
end

local function Close()
Move(Wall1, x_axis, 0, 25)
Move(Wall2, x_axis, -0, 25)
WaitForMove(Wall1, x_axis)
WaitForMove(Wall2, x_axis)
SetUnitValue(COB.INBUILDSTANCE, 0)
SetUnitValue(COB.YARD_OPEN, 0)
SetUnitValue(COB.BUGGER_OFF, 0)
end

function script.QueryNanoPiece()
local dice = math.random (1,4)
	if (dice == 1) then return Flare1
	end
	if (dice == 2) then return Flare2
	end
	if (dice == 3) then return Flare3
	end
	if (dice == 4) then return Flare4
	end
end
function script.Activate()
StartThread(Open)
return 1
end

function script.Deactivate()
StartThread(Close)
return 0
end

function script.StartBuilding(heading, pitch)
    
end

function script.StopBuilding()

end


---death animation
function script.Killed(recentDamage, maxHealth, corpsetype)
	Explode (Base, SFX.SHATTER)
	local severity = recentDamage / maxHealth
	if severity <= 0.33 then
	return 1
	else
	return 2 
	end
end