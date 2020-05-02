run once mission.

clearscreen.

local mission is newMission("Kerbin Station Visit",
    list(
        newMissionStep(MissionStepTypes:AutoRendezvous, lexicon("target", "Kerbin Station", "distance", 200))
    )
).

mission:serialize("1:/mission.json").

print "Mission Loaded: " + mission:name.
print "Reboot to execute.".