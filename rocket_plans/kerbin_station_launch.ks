run once mission.

clearscreen.

local ascentOptions is newAscentOptions(110000).
set ascentOptions:roll to 0.
set ascentOptions:deployFairings to false.
set ascentOptions:deploySolarPanels to false.
set ascentOptions:deployAntennas to false.

local mission is newMission("Kerbin Station Launch",
    list(
        newMissionStep(MissionStepTypes:Stage),
        newMissionStep(MissionStepTypes:Ascend, ascentOptions),
        newMissionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", newNodeTimeOptions(NodeTimeType:Apoapsis))),
        newMissionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", false))
    )
).

mission:serialize("1:/mission.json").

print "Mission Loaded: " + mission:name.
print "Reboot to execute.".