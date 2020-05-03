run once mission.

clearscreen.

local ascentOptions is ascentOptions(110000).
set ascentOptions:roll to 0.
set ascentOptions:deployFairings to false.
set ascentOptions:deploySolarPanels to false.
set ascentOptions:deployAntennas to false.

local plan is mission("Kerbin Station Launch",
    list(
        missionStep(MissionStepTypes:Stage),
        missionStep(MissionStepTypes:Ascend, ascentOptions),
        missionStep(MissionStepTypes:AddNodeCircularize, lexicon("nodeTime", nodeTimeOptions(NodeTimeType:Apoapsis))),
        missionStep(MissionStepTypes:ExecuteNode, lexicon("autoStage", false))
    )
).

mission:serialize("1:/mission.json").

print "Mission Loaded: " + mission:name.
print "Reboot to execute.".