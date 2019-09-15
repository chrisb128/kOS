run once ascent.
run once maneuvers.
run once executenode.
run once logging.
run once time.
run once hohmann.
run once inclination.
run once vec.
run once draw.
run once optimizers.

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

    
    if (abs(ship:obt:apoapsis - ship:obt:periapsis) / (ship:obt:semimajoraxis-ship:obt:body:radius) > 0.025) {
        logStatus("Recircularizing").
        addCircularizeNodeAtAp().
        executeNode().
    }
}

global function zeroInclination {        
    logStatus("Zero inclination").

    addZeroInclinationNode().    
    executeNode().
    wait 10.

    if (abs(ship:obt:apoapsis - ship:obt:periapsis) / (ship:obt:semimajoraxis-ship:obt:body:radius) > 0.025) {
        logStatus("Recircularizing").
        addCircularizeNodeAtPe().
        executeNode().
    }
}

global function matchInclination {
    parameter tgt.

    local to is tgt:obt.
    local so is ship:obt.
    if vAng(obtNormal(to:inclination, to:lan, to:body), obtNormal(so:inclination, so:lan, so:body)) > 0.1 {
        logStatus("Match inclination with target").
        addMatchInclinationNode(tgt).
        executeNode().
        wait 10.
        
        // assumes we started circular
        if (abs(ship:obt:apoapsis - ship:obt:periapsis) / (ship:obt:semimajoraxis-ship:obt:body:radius) > 0.05) {
            logStatus("Circularizing").
            addCircularizeNodeAtPe().
            executeNode().
        }
    }
}

global function warpToSoi {
    logStatus("Warping to SOI").        
    local soiTime is eta:transition + time:seconds.
    until (time:seconds > soiTime) {
        logInfo("Time to SOI: " + eta:transition, 1).
        autoWarp(soiTime).
        wait 10.
    }
}

global function transferToSatellite {
    parameter targetBody is mun.
    parameter orbitAp is 30000.

    lexicon(
        "action", { parameter args. _launchToOrbit(args). },
        "args", lexicon("targetBody", targetBody, "targetAp", orbitAp)
    ).
}

global function _transferToSatellite {
    parameter args is lexicon("targetBody", mun, "targetAp", 30000).
    
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
    
    logStatus("Executing transfer").
    addRendezvousTransferNode(targetBody).
    executeNode().
    wait 10.

    if ship:orbit:hasNextPatch {
        warpToSoi().

        set kUniverse:timeWarp:warp to 0.
        
    } else {
        logStatus("!!!!! No encounter found !!!!!").
        return.
    }

    if (ship:obt:body:name <> targetBody:name) {
        logStatus("Waiting for SOI change").

        until ship:obt:body:name = targetBody:name {        
            logInfo("Time to SOI: " + eta:transition, 1).
            logInfo("Time now: " + time:seconds, 2).
            wait 1.
        }
    }
    
    logStatus("Adjusting periapsis").
    local nodeTime is time:seconds + 180.
    addSetHyperbolicPeriapsisNode(args:targetAp, nodeTime).
    executeNode().
    wait 10.

    logStatus("Circularizing").
    addCircularizeNodeAtPe().
    executeNode().
    wait 10.

    if (abs(args:targetAp - ship:apoapsis) > (args:targetAp * 0.05)) {

        logStatus("Moving to target Orbit").
        logInfo("- Changing Periapsis to target at Apoapsis").
        local dV1 is -hohmannDV2(targetBody:mu, args:targetAp + targetBody:radius, ship:obt:semimajoraxis).
        
        add node(eta:apoapsis + time:seconds, 0, 0, dV1).
        executeNode().
        
        if (abs(args:targetAp - ship:apoapsis) > abs(args:targetAp - ship:periapsis)) {
            logInfo("- Circularizing at Periapsis").
            addCircularizeNodeAtPe().        
            executeNode().
        }
        else if (abs(args:targetAp - ship:apoapsis) < abs(args:targetAp - ship:periapsis)) {
            logInfo("- Circularizing at Apoapsis").
            addCircularizeNodeAtAp().
            executeNode().
        }
    }

    if (abs(ship:obt:inclination) > 0.2) {        
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
    wait until ship:bounds:bottomaltradar < 1.

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

global function autoRendezvous {
    parameter tgt.

    matchInclination(tgt).

    addRendezvousTransferNode(tgt).
    executeNode().
    wait 1.

    addMatchVelocityAtClosestApproachNode(tgt).
    executeNode().
    wait 1.
    
    if (tgt:velocity:orbit - ship:velocity:orbit):mag > 0.5 {
        addMatchVelocityAtClosestApproachNode(tgt).
        executeNode().
        wait 1.
    }

    closeDistanceToTarget(tgt, 150).
}