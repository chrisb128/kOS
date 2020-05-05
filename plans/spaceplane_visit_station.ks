run once mission.

clearscreen.

local plan is mission("Kerbin Station Spaceplane Visit",
    list(
        missionStep(MissionStepTypes:Stage),
        missionStep(MissionStepTypes:SpaceplaneAscent, lexicon("targetAp", 75000)),
        missionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", nodeTimeOptions(NodeTimeType:Apoapsis))),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", false)),
        missionStep(MissionStepTypes:AutoRendezvous, lexicon("target", "Kerbin Station", "distance", 200)),
        missionStep(MissionStepTypes:AutoDock, lexicon("control", "vesselDock", "target", "Kerbin Station", "targetDock", "targetDock"))
    )
).

plan:serialize("1:/mission.json").

print "Mission Loaded: " + plan:name.
print "Reboot to execute.".