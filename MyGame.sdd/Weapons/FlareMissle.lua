local weaponName="FlareMissle"
local weaponDef={
name = "Missle",
weaponType = [[MissileLauncher]],

Accuracy = 0,

--Physic/flight path
range=700,
reloadtime=2.8,
weaponVelocity=350,
startVelocity=350,
weaponAcceleration=200,
flightTime=3.5,
BurnBlow=0,
FixedLauncher=true,
dance=  0.1,
wobble= 0.1,
tracks= true,
Turnrate = 16000,
Tolerance = 16000,
collideFriendly=true,
avoidfriendly 	= true,
--soundStart = [[]],
--soundHit = [[]],
--soundStartVolume = 4,
--soundHitVolume = 4,
cegTag = [[Rocket_trail]],
explosionGenerator = [[custom:Lightmissleflash]],
----APPEARANCE
smokeTrail= false,
model="Rocket.s3o",

----TARGETING
turret=true,
CylinderTargetting=true,
avoidFeature=false,
avoidFriendly=true,


--commandfire=true,

----DAMAGE
damage={
default = 36,
AIR = 72, --does double damage against air
},
areaOfEffect=8,
craterMult=0,

--?FIXME***
lineOfSight=true,


}

return lowerkeys ({[weaponName]=weaponDef})