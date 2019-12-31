run once mission.

clearscreen.

local ascentOptions is newAscentOptions(90000).
local mission is newMission("Minmus Visit",
    list(
        newMissionStep(MissionStepTypes:Stage),
        newMissionStep(MissionStepTypes:Ascend, ascentOptions),
        newMissionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", newNodeTimeOptions(NodeTimeType:Apoapsis))),
        newMissionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        newMissionStep(MissionStepTypes:AddNodeMatchInclination, lexicon("target", minmus:name)),
        newMissionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        newMissionStep(MissionStepTypes:Quicksave),
        newMissionStep(MissionStepTypes:Pause),
        newMissionStep(MissionStepTypes:AddNodeRendezvousTransfer, lexicon("target", minmus:name)),
        newMissionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        newMissionStep(MissionStepTypes:WarpToSoi),
        newMissionStep(MissionStepTypes:AddNodeSetPeriapsis, lexicon("nodeTime", newNodeTimeOptions(NodeTimeType:Time, 180), "targetPe", 30000)),
        newMissionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true)),
        newMissionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", newNodeTimeOptions(NodeTimeType:Periapsis))),
        newMissionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", true))
    )
).

mission:serialize("1:/mission.json").

print "Mission Loaded: " + mission:name.
print "Reboot to execute.".