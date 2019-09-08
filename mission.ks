run once ascent.
run once circularize.
run once executenode.
run once logging.
run once time.
run once hohmann.
run once vec.

declare function executeSequence {
    parameter l.
    for i in l {
        runStep(i).
    }
}

global function runStep {
    parameter st.

    st:action:call(st:args).
}

global function launchToOrbit {
    parameter ap is 90000.
    parameter autoStage is true.
    parameter deployFairings is true.
    parameter deployAntennas is true.
    parameter deploySolarPanels is true.
    parameter countdown is 10.

    return lexicon(
        "action", { parameter args. _launchToOrbit(args). },
        "args", lexicon(
            "targetAp", ap, 
            "autoStage", autoStage, 
            "deployFairings", deployFairings, 
            "deployAntennas", deployAntennas, 
            "deploySolarPanels", deploySolarPanels, 
            "countdown", countdown)
    ).
}

local function _launchToOrbit {
    parameter args is lexicon("targetAp", 90000, "autoStage", true, "deployFairings", true, "deployAntennas", true, "deploySolarPanels", true, "countdown", 10).

    logStatus("Counting down").
    countdown(args:countdown).

    if args:autoStage {
        on stageFlameout() {
            stage.
            wait 1.
        }
    }

    ascent(args:targetAp).

    logStatus("Out of atmosphere").
    wait 5.

    if (args:deployFairings) {
        logInfo("Deploying fairings...").
        
        for fairing in ship:modulesNamed("ModuleProceduralFairing") {
            fairing:doEvent("deploy").
        }

        wait 2.
    }

    if (args:deployAntennas) {
        for antenna in ship:modulesNamed("ModuleRTAntenna") {
            if antenna:hasEvent("activate") {
                antenna:doEvent("activate").
            }
        }

        for antenna in ship:modulesNamed("ModuleDeployableAntenna") {
            if antenna:hasEvent("extend antenna") {
                antenna:doEvent("extend antenna").
            }
        }
        wait 2.
    }

    if (args:deploySolarPanels) {
        for panel in ship:modulesNamed("ModuleDeployableSolarPanel") {
            if panel:hasEvent("extend solar panel") {
                panel:doEvent("extend solar panel").
            }
        }
        wait 2.
    }

    logStatus("Circularizing").
    addCircularizeNodeAtAp().
    executeNode().

}

global function zeroInclination {        
    logStatus("Zero inclination").

    addZeroInclinationNode().    
    executeNode().
    wait 10.

    if (abs(ship:obt:apoapsis - ship:obt:periapsis) / (ship:obt:semimajoraxis-ship:obt:body:radius) > 0.05) {
        logStatus("Circularizing").
        addCircularizeNodeAtPe().
        executeNode().
    }
}

global function matchInclination {
    parameter args is lexicon("targetBody", mun).
        
    logStatus("Match inclination with target").

    addMatchInclinationNode(args:targetBody).
    executeNode().
    wait 10.

    if (abs(ship:obt:apoapsis - ship:obt:periapsis) / (ship:obt:semimajoraxis-ship:obt:body:radius) > 0.05) {
        logStatus("Circularizing").
        addCircularizeNodeAtPe().
        executeNode().
    }

}

global function transferToSatellite {
    parameter args is lexicon("targetBody", mun, "targetAp", 30000, "autoWarpToSoi", true).
    
    logStatus("Waiting to start transfer").

    local targetBody is args:targetBody.
    set target to targetBody.
    local parentBody is args:targetBody:body.

    if ship:body:name <> parentBody:name {
        logStatus("!!!! Ship not in orbit of target's parent !!!!").
        return.
    }

    logStatus("Clearing all maneuver nodes").
    until not hasnode {
        remove nextnode.
    }
    
    logStatus("Computing Hohmann Transfer").
    addHohmannTransferNode(targetBody).

    logStatus("Executing Transfer").
    executeNode().
    wait 10.

    if ship:orbit:hasNextPatch {
        if args:autoWarpToSoi {
            logStatus("Warping to SOI").
            
            local soiTime is eta:transition + time:seconds.
            until (time:seconds > soiTime) {
                logInfo("Time to SOI: " + eta:transition, 1).
                autoWarp(soiTime).
                wait 10.
            }

            set kUniverse:timeWarp:warp to 0.
        }
    } else {
        logStatus("!!!!! No encounter found !!!!!").
        return.
    }

    if (ship:obt:body:name <> targetBody:name) {
        logStatus("Waiting for SOI change").

        until ship:obt:body:name = targetBody:name {        
            logInfo("Time to SOI: " + eta:transition, 1).
            logInfo("Time now: " + time:seconds, 2).
        }
    }

    if ship:apoapsis < 0 {

        local nt is time:seconds + 180. // now + 3 min    

        local i is ship:obt:inclination.
        if i > 90 {
            set i to 180 - i.
        }

        local Vt is trueAnomalyFromEccentricAnomaly(eccentricAnomalyFromMeanAnomaly(meanAnomalyAtTime(ship:obt, nt), ship:obt:eccentricity), ship:obt:eccentricity).
        local w is clamp360(Vt + ship:obt:argumentOfPeriapsis).
        local lan is ship:obt:lan.
        local newPe is ship:body:radius + 30000.
        local newPos is positionAt(ship, nt).
        local newAp is (newPos - ship:body:position):mag.
        local e is eFromApPe(newAp, newPe).
        local sma is smaFromApPe(newAp, newPe).

        local newVecs is stateVectorsAtTrueAnomaly(e, sma, w, lan, i, 180, ship:body).
        local cVec is velocityAt(ship, nt):orbit.
        local dVec is newVecs[1] - cVec.

        logStatus("Capturing around target body").
        add nodeFromVector(dVec, nt).
        executeNode().

        logStatus("Circularizing").
        addCircularizeNodeAtPe().
        executeNode().

    }

    if (abs(args:targetAp - ship:apoapsis) > 2000) {
        logStatus("Moving to target Orbit").
        logInfo("- Changing Periapsis to target at Apoapsis").
        local dV1 is -hohmannDV2(targetBody:mu, args:targetAp + targetBody:radius, ship:obt:semimajoraxis).
        
        add node(eta:apoapsis + time:seconds, 0, 0, dV1).
        executeNode().
        
        logInfo("- Circularizing at Periapsis").
        addCircularizeNodeAtPe().
        executeNode().
    }

    if (abs(ship:obt:inclination) > 1) {        
        zeroInclination().
    }
    
}

global function returnFromSatellite {
    parameter args is lexicon("targetPe", 90000).

    local b is ship:body.
    logStatus("Computing exit maneuver").
    
    lock steering to ship:prograde.
    local exitDV is hohmannDV1(b:mu, ship:obt:semimajoraxis, ship:body:soiradius * 1.1).
    logInfo("Exit dV: " + exitDV).

    logStatus("Waiting for proper time").
    
    until vAng(ship:position - b:position, b:orbit:velocity:orbit) < 10 {
        logInfo("vAng ship pos/mun vel: " + vAng(ship:position - b:position, b:orbit:velocity:orbit), 1).
        set kuniverse:timewarp:warp to round(vAng(ship:position - b:position, b:orbit:velocity:orbit) / 10, 0) + 1.
    }
    set kuniverse:timewarp:warp to 0.

    local burnTime is maneuverTime(exitDV / 2).
    add node(time:seconds + burnTime + 10, 0, 0, exitDV).
    unlock steering.
    executeNode().

    if ship:orbit:hasnextpatch {
        
        logStatus("Dropping Periapsis").
        lock steering to ship:prograde.
        local throttleLock is 0.
        lock throttle to throttleLock.

        until vAng(ship:position - b:position, b:orbit:velocity:orbit) > 90 {
            logInfo("vAng ship pos/mun vel: " + vAng(ship:position - b:position, b:orbit:velocity:orbit), 1).
            set kuniverse:timewarp:warp to 3.
        }.
        set kuniverse:timewarp:warp to 0.

        until ship:orbit:nextpatch:periapsis < args:targetPe {
            
            set throttleLock to min((ship:orbit:nextpatch:periapsis - args:targetPe) / args:targetPe, 1).

            logInfo("Kerbin Pe: " + ship:orbit:nextpatch:periapsis).
        }

        lock throttle to 0.
        unlock steering.
        unlock throttle.

        logStatus("Warping to SOI").        
        
        until (eta:transition < 0) {
            autoWarp(eta:transition + time:seconds).
        }
    } else {
        logStatus("!!!!! Didn't exit SOI !!!!!").
    }
}

global function landSomewhere {

    logStatus("Deorbiting").
    lock steering to ship:retrograde.

    // drop periapsis to 1km below surface
    local deorbitDV is -hohmannDV2(ship:body:mu, ship:body:radius - 1000, ship:obt:semimajoraxis).
    local burnTime is maneuverTime(deorbitDV / 2).
    add node(time:seconds + burnTime + 120, 0, 0, deorbitDV).
    unlock steering.
    executeNode().

    until (ship:bounds:bottomaltradar < 5000) {
        set kuniverse:timewarp:warp to 3.
    }

    set kuniverse:timewarp:warp to 0.

    logStatus("Killing horizontal velocity").
    local steerLock to heading(270, 0).
    lock steering to steerLock.

    wait until vAng(ship:facing:forevector, steerLock:forevector) < 1.
    
    local throttleLock is 0.
    lock throttle to throttleLock.
    local maxAccel to ship:availableThrust / ship:mass.
    local origHvel to vxcl(up:forevector, ship:velocity:surface).
    local horizVel to origHvel:vec.

    until vDot(origHvel, horizVel) < 0 {
        set horizVel to vxcl(up:forevector, ship:velocity:surface).
        set maxAccel to ship:availableThrust / ship:mass.

        if (horizVel:mag > 2) {
            set throttleLock to min(horizVel:mag / maxAccel, 1).
        }

        logInfo("hVel: " + round(horizVel:mag, 3), 1).
        logInfo("maxAcc: " + round(maxAccel, 3), 2).
        logInfo("throt: " + round(throttleLock, 3), 3).
    }
    set throttleLock to 0.

    on (alt:radar < 1000) {
        set gear to true.
    }

    logStatus("Landing.").
    
    logInfo("Killing vertical velocity").
    hoverslam(50).

    set steerLock to heading(270, 90).
    lock steering to steerLock.
    
    if ship:verticalspeed < -0.4 {
        hover(1.2).
        wait until ship:verticalspeed > -0.1.
    }

    hover().
    logInfo("Hovering").
    wait 10.

    logInfo("Soft descent").
    
    hover(.70).
    wait until ship:verticalspeed < -5.
    hover().
    wait until ship:bounds:bottomaltradar <= 15.
    
    hover(.70).
    wait until ship:verticalspeed < -1.
    hover().
    wait until ship:bounds:bottomaltradar <= 5.

    hover(.70).
    wait until ship:verticalspeed < -0.4.
    hover().    
    wait until ship:bounds:bottomaltradar < 0.25.

    lock throttle to 0.
    unlock all.

    set steerLock to heading(270, 90).
    lock steering to steerLock.
    logStatus("Waiting for stability...").

    wait until ship:status = "LANDED" and abs(ship:velocity:surface:mag) < 0.1.
    logStatus("Landed on the target!").
}

global function landAt {

    // assume circular starting orbit
    // change inclination
}

global function addMatchVelocityAtClosestApproachNode {
    parameter tgt.

    local function distanceToTargetAtTime {
        parameter t.

        local sv0 is stateVectorsAtTime(ship:obt, t).
        local tv0 is stateVectorsAtTime(tgt:obt, t).
        return (tv0[0] - sv0[0]):mag.
    }

    // first guess is near ship Ap
    local travelTime is eta:apoapsis + time:seconds.
    set travelTime to hillClimber({ parameter x. return distanceToTargetAtTime(x). }, travelTime, 2, -4, round(ship:obt:period)).

    local shipVecAtTime is stateVectorsAtTime(ship:obt, travelTime).
    local targetVecAtTime is stateVectorsAtTime(tgt:obt, travelTime).
    local deltaV is targetVecAtTime[1] - shipVecAtTime[1].
    add nodeFromVector(deltaV, travelTime, shipVecAtTime[0], shipVecAtTime[1], false).
}

global function closeDistanceToTarget {
    parameter tgt.
    parameter dist.

    local closeSpeed is 30.

    lock currentDist to tgt:position:mag.

    if currentDist < 500 {
        set closeSpeed to 10.
    } else if currentDist < 50 {
        set closeSpeed to 5.
    } else if currentDist < 10 {
        set closeSpeed to 1.
    }

    if currentDist <= dist { return. }

    lock steering to tgt:position:normalized.

    wait until vAng(ship:facing:forevector, tgt:position) < 0.1.

    local kickTime is maneuverTime(closeSpeed).
    local kickStart is time:seconds.
    lock throttle to 1.
    wait until time:seconds >= kickStart + kickTime.
    lock throttle to 0.

    local meetTime is time:seconds + currentDist / closeSpeed.    
    local stopTime is maneuverTime(closeSpeed).
    local nodeTime is meetTime - stopTime.

    local tgtVecAtNode is stateVectorsAtTime(tgt:obt, nodeTime).
    local shipVecAtNode is stateVectorsAtTime(ship:obt, nodeTime).

    add nodeFromVector(tgtVecAtNode[1] - shipVecAtNode[1], nodeTime, shipVecAtNode[0], shipVecAtNode[1], false).
    executeNode().
    wait 1.

    set tgtVecAtNode to stateVectorsAtTime(tgt:obt, time:seconds).
    set shipVecAtNode to stateVectorsAtTime(ship:obt, time:seconds).
    add nodeFromVector(tgtVecAtNode[1] - shipVecAtNode[1], nodeTime, shipVecAtNode[0], shipVecAtNode[1], false).
    executeNode().

    unlock currentDist.
}