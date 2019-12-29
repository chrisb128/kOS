run once ascent.
run once maneuvers.
run once executenode.
run once logging.
run once time.
run once hohmann.
run once inclination.
run once vec.
run once draw.
run once rendezvous.
run once optimizers.
run once hoverslam.
run once vessel.

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

    logStatus("Deploy fairings").
    if (args:deployFairings) {
        deployFairings().
        wait 2.
    }

    logStatus("Deploy antennas").
    if (args:deployAntennas) {
        deployAntennas().
        wait 2.
    }

    logStatus("Deploy solar panels").
    if (args:deploySolarPanels) {
        deploySolarPanels().
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
    until vAng(obtNormal(to:inclination, to:lan, to:body), obtNormal(so:inclination, so:lan, so:body)) < 0.1 {
        logStatus("Match inclination with target").
        addMatchInclinationNode(tgt).
        executeNode().
        wait 10.
        
        // assumes we started circular
        if (abs(ship:obt:apoapsis - ship:obt:periapsis) / (ship:obt:semimajoraxis-ship:obt:body:radius) > 0.05) {
            logStatus("Circularizing").
            addCircularizeNodeAtPe().
            executeNode().
            wait 1.
        }
    }
}

global function transferToSatellite {
    parameter targetBody is mun.
    parameter orbitAp is 30000.

    return lexicon(
        "action", { parameter args. _transferToSatellite(args). },
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

    logStatus("Matching inclination").
    matchInclination(targetBody).
    
    logStatus("Clearing all maneuver nodes").
    until not hasnode {
        remove nextnode.
    }
    
    logStatus("Executing transfer").
    addRendezvousTransferNode(targetBody).
    executeNode(true, 10, true, { return ship:obt:periapsis < 0. }).
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
    
    killHorizontalVelocity().

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

local function killHorizontalVelocity {
    
    logStatus("Killing horizontal velocity").
    local horizVel to vxcl(up:forevector, ship:velocity:surface).
    local steerLock to lookDirUp(-horizVel, up:forevector).
    lock steering to steerLock.

    wait until vAng(ship:facing:forevector, steerLock:forevector) < 1.
    
    local throttleLock is 0.
    lock throttle to throttleLock.
    local maxAccel to ship:availableThrust / ship:mass.
    local origHvel to horizVel:vec.

    until vDot(origHvel, horizVel) < 0 {
        set horizVel to vxcl(up:forevector, ship:velocity:surface).
        set steerLock to lookDirUp(-horizVel, up:forevector).
        set maxAccel to ship:availableThrust / ship:mass.

        if (horizVel:mag > 2) {
            set throttleLock to min(horizVel:mag / maxAccel, 1).
        }

        logInfo("hVel: " + round(horizVel:mag, 3), 1).
        logInfo("maxAcc: " + round(maxAccel, 3), 2).
        logInfo("throt: " + round(throttleLock, 3), 3).
    }
    set throttleLock to 0.
}

global function landAt {
    parameter lat, lng.
    parameter b.
    // assume low circular starting orbit

    // wait until target is on day side

    // find inclination where orbit intersects latitude
    local deorbitInc is arcTan(2*tan(lat)).

    // find arg of periapsis and long of ascending node for inclined orbit that intersects longitude at stop radius    
    local deorbitRPe is b:radius / 2.
    local deorbitRAp is ship:obt:semimajoraxis.
    local deorbitSma is smaFromApPe(deorbitRAp, deorbitRPe).
    local deorbitE is eFromApPe(deorbitRAp, deorbitRPe).
    
    local deorbitStopHeight is b:radius + 5000.
    local deorbitTaAtStopR is trueAnomaliesWithRadius(deorbitSma, deorbitE, deorbitStopHeight)[1].

    local stopPos is (latlng(lat, lng):position - b:position).
    set stopPos:mag to deorbitStopHeight.
    local landingPosVd is vecDraw(
        b:position,
        stopPos,
        RGB(1, 0, 0), "", 1.2, true, 0.2, true, true
    ).
    set landingPosVd:startupdater to { return b:position. }.
    set landingPosVd:vecupdater to { 
        local x is (latlng(lat, lng):position - b:position).
        set x:mag to deorbitStopHeight.
        return x.
    }.

    local function deorbitScoring {
        parameter x.
    
        local deorbitLan is clamp360(x[0] + 360).

        local sv is stateVectorsAtTrueAnomaly(deorbitE, deorbitSma, 180, deorbitLan, deorbitInc, deorbitTaAtStopR, b).
        local travelTime is 360 / meanMotionK(b:mu, deorbitSma).
        
        local tgtRot is 360 * (travelTime / b:rotationPeriod).

        return ((latlng(lat, lng + tgtRot):position - b:position) - sv[0]):mag.
    }

    local wAndLan is steepestDescentHillClimb(
        { parameter x. return deorbitScoring(x). },
        list(0),
        list(10),
        0.1,
        1.17
    ).

    local deorbitLan is clamp360(wAndLan[0] + 360).
    local deorbitW is 180.

    local shipTa is convertTrueAnomalies(180, deorbitW, deorbitLan, ship:obt:argumentofperiapsis, ship:obt:lan).
    local sv is stateVectorsAtTrueAnomaly(deorbitE, deorbitSma, deorbitW, deorbitLan, deorbitInc, 180, b).
    //drawStateVectors(list(), sv, b, RGB(0, 0, 1)).
    
    local shipVec is stateVectorsAtTrueAnomaly(ship:obt:eccentricity, ship:obt:semimajoraxis, ship:obt:argumentofperiapsis, ship:obt:lan, ship:obt:inclination, shipTa, b).
    //drawStateVectors(list(), shipVec, b, RGB(0, 1, 0)).
    
    // estimate time to ta with mean motion because orbit should have started circular
    local nodeTime is time:seconds + (clamp360((shipTa - ship:obt:trueAnomaly) + 360) / meanMotion(ship:obt)).
    
    local diff is sv[1] - shipVec[1].
    add nodeFromVector(diff, nodeTime, shipVec[0], shipVec[1]).
    executeNode().
    
    wait 1.

    local horizVel is vxcl(up:forevector, ship:velocity:surface).
    local killVelTime is maneuverTime(horizVel:mag).
    
    local vertVel is vCrs(up:forevector, ship:velocity:surface).
    local secondsToAltitude is (ship:altitude - 5000) / vertVel:mag.

    local steerLock to heading(360-ship:bearing, 0).
    lock steering to steerLock.

    until secondsToAltitude < killVelTime {
        set vertVel to vCrs(up:forevector, ship:velocity:surface).
        set secondsToAltitude to (ship:altitude - 5000) / vertVel:mag.

        set horizVel to vxcl(up:forevector, ship:velocity:surface).
        logInfo("HVel: " + round(horizVel:mag), 2).

        set killVelTime to maneuverTime(horizVel:mag).
        logInfo("Kill Time: " + round(killVelTime), 3).
        logInfo("Seconds to Alt: T-" + round(secondsToAltitude), 4).

        if (secondsToAltitude > 30) {
            set kuniverse:timewarp:warp to 3.
        } else {
            set kuniverse:timewarp:warp to 0.
        }

        wait 0.
    }
    
    killHorizontalVelocity().
    
    on (alt:radar < 1000) {
        set gear to true.
    }

    logStatus("Landing.").
    
    
    logInfo("Hoverslam to 1km").
    hoverslam(1000).
    
    kUniverse:pause().

    logInfo("Hovering 3s").
    local hstart is time:seconds.
    hover({ return time:seconds < hstart + 3. }).
    

    until false {
        logInfo("Closing distance to landing target").
        local stopTarget to (latlng(lat, lng):position - b:position).
        set stopTarget:mag to deorbitStopHeight.

        local hoverSteerTarget is lookDirUp(stopTarget, ship:facing:upvector).
        lock steering to hoverSteerTarget.

        local lockSteering is false.
        on true {
            if lockSteering {
                preserve.
            }
        }

        hoverloop().
    }
    
    logInfo("Hoverslam to 50m").
    hoverslam(50).
    
    logInfo("Soft descent").    
    if ship:bounds:bottomaltradar > 100 {
        hover({ return ship:bounds:bottomaltradar < 100. }, -30).
    }
    hover({ return ship:bounds:bottomaltradar < 10. }, -10).
    gear on.
    hover({ return ship:bounds:bottomaltradar < 5. }, -1).
    hover({ return ship:bounds:bottomaltradar < 0.5. }, -0.5).

    lock throttle to 0.
    set lockSteering to false.
    unlock all.

    set steerLock to heading(270, 90).
    lock steering to steerLock.
    logStatus("Waiting for stability...").

    wait until ship:status = "LANDED" and abs(ship:velocity:surface:mag) < 0.1.
    logStatus("Landed at: " + ship:geoposition).
}

global function autoRendezvous {
    parameter tgt.

    set target to tgt.

    matchInclination(tgt).
    
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

    if (tgt:position:mag > 500) {
        closeDistanceToTarget(tgt, 150).
    }
}