run once mission.

clearscreen.

local ascentOptions is ascentOptions(90000).
set ascentOptions:roll to 0.

local plan is mission("Minmus Station Visit",
    list(
        missionStep(MissionStepTypes:Stage),
        missionStep(MissionStepTypes:Ascend, ascentOptions),
        missionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", nodeTimeOptions(NodeTimeType:Apoapsis))),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        missionStep(MissionStepTypes:AddNodeMatchInclination, lexicon("target", minmus:name)),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        missionStep(MissionStepTypes:Quicksave),
        missionStep(MissionStepTypes:Pause),
        missionStep(MissionStepTypes:AddNodeRendezvousTransfer, lexicon("target", minmus:name)),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        missionStep(MissionStepTypes:WarpToSoi),
        missionStep(MissionStepTypes:AddNodeSetPeriapsis, lexicon("nodeTime", nodeTimeOptions(NodeTimeType:Time, 180), "targetPe", 200000)),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        missionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", nodeTimeOptions(NodeTimeType:Periapsis))),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        missionStep(MissionStepTypes:AutoRendezvous, lexicon("target", "Minmus Station", "distance", 200))
    )
).

plan:serialize("1:/mission.json").

print "Mission Loaded: " + plan:name.
print "Reboot to execute.".