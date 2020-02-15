run once vessel.
run once executenode.
run once autostage.
run once ascent.
run once maneuvers.
run once inclination.
run once hohmann.
run once rendezvous.

// MISSION 
global function newMission {
    parameter name.
    parameter steps is list().
    
    local this is lexicon(
        "name", name,
        "steps", steps,
        "currentStep", 0
    ).

    local serialize to {parameter _this, out. missionSerialize(_this, out).}.
    set this["serialize"] to serialize:bind(this).
    
    local deserialize to {parameter _this, out. missionDeserialize(_this, out).}.
    set this["deserialize"] to deserialize:bind(this).

    local execute to { parameter _this, options. missionExecute(_this, options). }.
    set this["execute"] to execute:bind(this).

    return this.
}

global MissionStepTypes is lexicon(
    "Pause", missionStepTypePause(),
    "Quicksave", missionStepTypeQuicksave(),
    "Stage", missionStepTypeStage(),
    "Ascend", missionStepTypeAscent(),
    "ExecuteNode", missionStepTypeExecuteNode(),
    "AddNodeCircularize", missionStepTypeAddNodeCircularize(),
    "AddNodeSetPeriapsis", missionStepTypeAddNodeSetPeriapsis(),
    "AddNodeZeroInclination", missionStepTypeAddNodeZeroInclination(),
    "AddNodeMatchInclination", missionStepTypeAddNodeMatchInclination(),
    "AddNodeRendezvousTransfer", missionStepTypeAddNodeRendezvousTransfer(),
    "WarpToSoi", missionStepTypeWarpToSoi(),
    "GoToStep", missionStepTypeGoToStep(),
    "AutoRendezvous", missionStepTypeAutoRendezvous()
).

global function missionDeserialize {
    parameter this.
    parameter in.

    local serialized is readJson(in).

    set this:name to serialized:name.
    set this:currentStep to serialized:currentStep.
    set this:steps to list().

    for s in serialized:steps {
        if MissionStepTypes:hassuffix(s:key) {
            this:steps:add(newMissionStep(MissionStepTypes[s:key], s:params)).
        } else {
            print "Could not find step type: " + s:key.
        }
    }
}

local function missionSerialize {
    parameter this.
    parameter out.
    
    local serializable is lexicon().
    set serializable["name"] to this:name.
    set serializable["currentStep"] to this:currentStep.
    set serializable["steps"] to list().
    for ms in this:steps {
        serializable:steps:add(ms:type:serializable(ms)).
    }

    writeJson(serializable, out).
}

global function newMissionExecuteOptions {
    parameter afterStep is { }.
    parameter beforeStep is { }.

    return lexicon(
        "beforeStep", beforeStep,
        "afterStep", afterStep
    ).
}

global function missionExecute {
    parameter this.
    parameter options.

    until (this:currentStep >= this:steps:length) {
        options:beforeStep().
        this:steps[this:currentStep]:type:execute(this, this:steps[this:currentStep]).

        set this:currentStep to this:currentStep + 1.
        options:afterStep().
    }
}

// MISSION STEP
global function newMissionStep {
    parameter type, params is lexicon().

    local this is lexicon(
        "type", type,
        "params", params
    ).

    return this.
}

local function missionStepType {
    parameter key, name.
    
    local this is lexicon(
        "key", key,
        "name", name).

    set this["serializable"] to {
        parameter step.
        return lexicon("key", step:type:key, "params", step:params).
    }.
    
    set this["execute"] to {
        parameter mission.
        parameter step.
    }.
    
    return this.
}

local function missionStepTypePause {
    local this is missionStepType("Pause", "Pause").

    set this["execute"] to {
        parameter mission.
        parameter step.
        kUniverse:pause().
    }.

    return this.
}

local function missionStepTypeQuicksave {
    local this is missionStepType("Quicksave", "Quicksave").

    set this["execute"] to {
        parameter mission.
        parameter step.
        kUniverse:quickSave().
    }.
    
    return this.
}

local function missionStepTypeStage {
    local this is missionStepType("Stage", "Stage").

    set this["execute"] to {
        parameter mission.
        parameter step.
        stage.
    }.

    return this.
}

local function missionStepTypeAscent {
    local this is missionStepType("Ascend", "Ascend").

    set this["execute"] to {
        parameter mission.
        parameter step.
        if (step:params:autoStage) {
            enableAutoStager().
        }

        ascent(step:params).

        if (step:params:deployFairings) {
            deployFairings().
            wait 2.
        }
        if (step:params:deploySolarPanels) {
            deploySolarPanels().
            wait 2.
        }
        if (step:params:deployAntennas) {
            deployAntennas().
            wait 2.
        }                
        if (step:params:autoStage) {
            disableAutoStager().
        }
    }.

    return this.
}

global function newAscentOptions {
    parameter targetAp.
    parameter roll is 0.

    return lexicon(
        "targetAp", targetAp,
        "roll", roll,
        "autoStage", true,
        "deployFairings", true,
        "deploySolarPanels", true,
        "deployAntennas", true
    ).
}

local function missionStepTypeExecuteNode {
    local this is missionStepType("ExecuteNode", "Execute Node").
    
    set this["execute"] to {
        parameter mission.
        parameter step.
        if (step:params:autoStage) {
            enableAutoStager().
        }

        executeNode().

        if (step:params:autoStage) {
            disableAutoStager().
        }

    }.
    return this.
}

global function newNodeTimeOptions {
    parameter type.
    parameter arg is 0.

    return lexicon("type", type, "arg", arg).
}

global NodeTimeType is lexicon(
    "Apoapsis", "AP",
    "Periapsis", "PE",
    "Time", "TIME"
).

local function missionStepTypeAddNodeCircularize {
    local this is missionStepType("AddNodeCircularize", "Add Node - Circularize").
    
    set this["execute"] to {
        parameter mission.
        parameter step.

        if (step:params:nodeTime:type = "AP") {
            addCircularizeNodeAtAp().
        } else if (step:params:nodeTime:type = "PE") {
            addCircularizeNodeAtPe().
        }
    }.

    return this.
}

local function missionStepTypeAddNodeSetPeriapsis {
    local this is missionStepType("AddNodeSetPeriapsis", "Add Node - Set Periapsis").

    set this["execute"] to {
        parameter mission.
        parameter step.

        local nodeTime is step:params:nodeTime:arg + time:seconds.
        if (step:params:nodeTime:type = NodeTimeType:Apoapsis) {
            set nodeTime to eta:apoapsis + time:seconds.
            addSetPeriapsisNodeAtAp(step:params:targetPe).
        } else if (step:params:nodeTime:type = NodeTimeType:Time) {
            if (orbitAt(ship, nodeTime):apoapsis < 0) {
                addSetHyperbolicPeriapsisNode(step:params:targetPe, nodeTime).
            } else {
                addSetPeriapsisNode(step:params:targetPe, nodeTime).
            }
        }
    }.

    return this.
}

local function missionStepTypeAddNodeZeroInclination {
    local this is missionStepType("AddNodeZeroInclination", "Add Node - Zero Inclination").

    set this["execute"] to {
        parameter mission.
        parameter step.        
        addZeroInclinationNode().
    }.

    return this.
}

local function missionStepTypeAddNodeMatchInclination {
    local this is missionStepType("AddNodeMatchInclination", "Add Node - Match Inclination").

    set this["execute"] to {
        parameter mission.
        parameter step.

        if (bodyExists(step:params:target)) {
            addMatchInclinationNode(body(step:params:target)).
        } else {
            addMatchInclinationNode(vessel(ship:params:target)).
        }
    }.

    return this.
}

local function missionStepTypeAddNodeRendezvousTransfer {
    local this is missionStepType("AddNodeRendezvousTransfer", "Add Node - Rendezvous Transfer").

    set this["execute"] to {
        parameter mission.
        parameter step.

        if (bodyExists(step:params:target)) {
            addRendezvousTransferNode(body(step:params:target)).
        } else {
            addRendezvousTransferNode(vessel(ship:params:target)).
        }
    }.

    return this.
}

local function missionStepTypeWarpToSoi {
    local this is missionStepType("WarpToSoi", "Warp To SOI").

    set this["execute"] to {
        parameter mission.
        parameter step.
        warpToSoi().
    }.

    return this.
}

local function missionStepTypeGoToStep {
    local this is missionStepType("GoToStep", "Go to step").

    set this["execute"] to {
        parameter mission.
        parameter step.

        set mission:currentStep to step - 1.  // subtract one, because the mission executer will increment at the end of the step
    }.

    return this.
}

local function missionStepTypeAutoRendezvous {
    local this is missionStepType("AutoRendezvous", "Auto-rendezvous with target vessel").

    set this["execute"] to {
        parameter mission.
        parameter step.

        set tgt to vessel(step:params:target).

        addMatchInclinationNode(tgt).
        executeNode().
        
        addRendezvousTransferNode(tgt).
        executeNode().
        wait 1.

        addMatchVelocityAtClosestApproachNode(tgt).
        executeNode(true, 10, false).
        wait 1.
        
        if (tgt:velocity:orbit - ship:velocity:orbit):mag > 0.5 {
            addMatchVelocityAtClosestApproachNode(tgt).
            executeNode(true, 10, false).
            wait 1.
        }

        if (tgt:position:mag > step:params:distance) {
            closeDistanceToTarget(tgt, step:params:distance).
        }
    }.

    return this.
}