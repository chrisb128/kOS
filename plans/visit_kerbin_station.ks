run once mission.

clearscreen.

local plan is mission("Kerbin Station Visit",
    list(
        missionStep(MissionStepTypes:AutoRendezvous, lexicon("target", "Kerbin Station", "distance", 200)),
        missionStep(MissionStepTypes:AutoDock, lexicon("control", "vesselDock", "target", "Kerbin Station", "targetDock", "targetDock"))
    )
).

mission:serialize("1:/mission.json").

print "Mission Loaded: " + mission:name.
print "Reboot to execute.".