run once mission.

clearscreen.

local ascentOptions is ascentOptions(75000).
set ascentOptions:roll to 0.

local plan is mission("Kerbin Station Visit",
    list(
        missionStep(MissionStepTypes:Stage),
        missionStep(MissionStepTypes:Ascend, ascentOptions),
        missionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", nodeTimeOptions(NodeTimeType:Apoapsis))),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        missionStep(MissionStepTypes:AutoRendezvous, lexicon("target", "Kerbin Station", "distance", 200)),
        missionStep(MissionStepTypes:AutoDock, lexicon("control", "vesselDock", "target", "Kerbin Station", "targetDock", "targetDock"))
    )
).

plan:serialize("1:/mission.json").

print "Mission Loaded: " + plan:name.
print "Reboot to execute.".