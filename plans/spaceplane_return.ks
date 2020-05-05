run once mission.

clearscreen.

local plan is mission("Kerbin Station Visit",
    list(
        missionStep(MissionStepTypes:SetPeriapsis, lexicon("targetPe", 22000)),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true))
    )
).

plan:serialize("1:/mission.json").

print "Mission Loaded: " + plan:name.
print "Reboot to execute.".