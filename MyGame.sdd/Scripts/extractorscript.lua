-- Thanks Piscasso for basically doing most of the script!
-- Body
local Base = piece "Base"
local TrueBase = piece "TrueBase"
local Stem = piece "Stem"
SIG_EXT = 1

local function Extract()
	Spin(Stem, y_axis, math.rad(135))
end 

local function StopExtract()
	Sleep(250)
	StopSpin (Stem,y_axis)
end 

function script.Create()

end


function script.Activate () 
    StartThread(Extract)
end

function script.Deactivate ()
      StartThread(StopExtract)
end

function script.ExtractionRateChanged()


end

---death animation
function script.Killed(recentDamage, maxHealth, corpsetype)
	Explode (TrueBase, SFX.SHATTER)
	local severity = recentDamage / maxHealth
	if severity <= 0.33 then
	return 1
	else
	return 2 
	end
end