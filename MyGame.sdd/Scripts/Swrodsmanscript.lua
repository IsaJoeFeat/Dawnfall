-- Body and gun
local Base = piece "Base"

function script.AimFromWeapon1() 
	return Base
	
end

function script.QueryWeapon1() 
	return Base
end

function script.AimWeapon1( heading, pitch )
    return true
end

function script.FireWeapon1()
		--EmitSfx(Flare, huntermuzzleflash)
end

death animation
function script.Killed(recentDamage, maxHealth, corpsetype)
	Explode (Body, SFX.SHATTER)
	local severity = recentDamage / maxHealth
	if severity <= 0.33 then
	return 1
	else
	return 2 
	end 
end