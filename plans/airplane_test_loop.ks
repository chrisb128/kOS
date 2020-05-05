run once mission.

run once "0:/flight_paths/med_loop.ks".

clearscreen.

local cfg is lexicon(
    "rollRange", 40,
    "rollResponse", 0.5,
    "pitchRange", 30,
    "ascentMinPitch", 8,
    "attitudeResponse", 1,
    "stoppingTime", 2
).

local plan is mission("Airplane Test Loop",
    list(
        missionStep(MissionStepTypes:Stage),
        missionStep(MissionStepTypes:AirplaneFlightPlan, lexicon("config", cfg, "plan", med_loop(), "initMode", "ascent"))
    )
).

plan:serialize("1:/mission.json").

print "Mission Loaded: " + plan:name.
print "Reboot to execute.".