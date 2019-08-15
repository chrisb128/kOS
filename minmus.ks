// imports
set config:ipu to 2000.
run once logging.
run once math.
run once executenode.
run once launch.
run once circularize.
run once hohmann.
run once inclination.
run once hoverslam.
run once warp.
run once science.

declare targetBody is minmus.
declare parentBody is targetBody:orbit:body.


local function clearFields {
    clearscreen.
    logMission("== going to minmus == v3").
}

local function countdown {
    local parameter count is 10.
    from {local c is count.} until c = 0 step {set c to c - 1.} do {
        logInfo("..." + c).
        wait 1.
    }
}

clearFields().

if ship:status = "PRELAUNCH" {

    logStatus("Counting down").
    countdown(10).

    on stageFlameout() {
        stage.
        wait 1.
    }

    launch(90000).

    logStatus("Out of atmosphere").
    wait 5.
    logInfo("Deploying fairings...").
    
    for fairing in ship:modulesNamed("ModuleProceduralFairing") {
        fairing:doEvent("deploy").
    }.

    wait 2.

    set ag3 to true.

    wait 5.

    logStatus("Circularizing").
    circularizeAtAp().
    executeNode().
    
    local vacEngine is ship:partsTagged("vacEngine")[0].
    until vacEngine:ignition {
        stage.
        wait 5.
    }

    kuniverse:quicksave().

    set target to targetBody.

    logStatus("Waiting for next module").
    wait 10.
}

clearFields().

if ship:orbit:body:name = parentBody:name {    
    logStatus("Match inclination with target").

    matchInclination(targetBody).    
    executeNode().

    if (abs(ship:obt:apoapsis - ship:obt:periapsis) > 2000) {
        logStatus("Circularizing").
        circularizeAtAp().
        executeNode().
    }

    logStatus("Waiting for next module").
    wait 10.
}

clearFields().

if ship:orbit:body:name = parentBody:name {
    
    logStatus("Waiting to start transfer").

    set target to targetBody.

    logStatus("Clearing all maneuver nodes").
    until not hasnode {
        remove nextnode.
    }
    
    logStatus("Computing Hohmann Transfer").

    local xferR2 is targetBody:obt:semimajoraxis.
    local xferDV is hohmannDV1(parentBody:mu, ship:obt:semimajoraxis, xferR2).
    
    local xferAngle is hohmannTargetAngle(ship:obt:semimajoraxis, xferR2).
    local xferNodeTime is timeToRelativeAngle(targetBody, ship, parentBody, xferAngle).
    add node(xferNodeTime, 0, 0, xferDV).

    logInfo("Target Angle: " + round(xferAngle, 0), 1).

    local currentAngle is angleBetween(targetBody:position - parentBody:position, ship:position - parentBody:position).
    logInfo("Current Angle: " + round(currentAngle, 0), 3).
    logInfo("Time to target angle: T-" + round(xferNodeTime - time:seconds, 0), 4).
    logInfo("Time to node:         T-" + round(xferNodeTime - time:seconds, 0), 5).

    logStatus("Warping to node time").

    local targetTime is xferNodeTime - (maneuverTime(xferDV)/2) - 120.
    until time:seconds > targetTime {
        autoWarp(targetTime).

        set timeToAng to timeToRelativeAngle(targetBody, ship, parentBody, xferAngle).
        local currentAngle is angleBetween(targetBody:position - parentBody:position, ship:position - parentBody:position).
        logInfo("Current Angle: " + round(currentAngle, 0), 3).
        logInfo("Time to target angle: T-" + round(timeToAng - time:seconds, 0), 4).
        logInfo("Time to node:         T-" + round(xferNodeTime - time:seconds, 0), 5).
    }.

    logStatus("Executing Transfer").
    executeNode().
    wait 10.

    if ship:orbit:hasnextpatch {
        logStatus("Warping to SOI").
        
        until (eta:transition < 0) {
            autoWarp(eta:transition + time:seconds).
        }

        kuniverse:quicksave().
        
        logStatus("Waiting for next module").
        wait 10.

    } else {
        logStatus("!!!!! No encounter found !!!!!").
        wait 30.
    }
}

clearFields().

if ship:orbit:body:name = targetBody:name {
    local targetPe is 30000.
    
    if ship:apoapsis < 0 {

        logStatus("Capturing around target body").
        circularizeAtPe().
        executeNode().

        // captured retrograde        
        if (ship:obt:inclination > 90) {            
            logStatus("Captured retrograde, reversing direction").

            add node(eta:periapsis + time:seconds, 0, 0, -2 * ship:orbit:velocity:orbit:mag).
            executeNode().
            wait 10.
        }
        
        kuniverse:quicksave().
    }

    if (abs(ship:obt:inclination) > 1) {
        logStatus("Zeroing inclination").
        zeroInclination().
        executeNode().
    }
    
    if (abs(ship:apoapsis - ship:periapsis) > 2000) {
        logStatus("Moving to 30km Orbit").
        logInfo("- Changing Periapsis to 30km").
        local dV1 is hohmannDV1(targetBody:mu, ship:obt:semimajoraxis, targetPe + targetBody:radius).
        
        add node(eta:apoapsis + time:seconds, 0, 0, dV1).
        executeNode().
        
        logInfo("- Circularizing at Periapsis").
        circularizeAtPe().
        executeNode().
        
        kuniverse:quicksave().
    }
    
    logStatus("Waiting for next module").
}

clearFields().

if ship:orbit:body:name = targetBody:name {

    logStatus("Waiting to deorbit on sunny side").
    if ((ship:position - sun:position):mag < (targetBody:position - sun:position):mag) {
        set kuniverse:timewarp:warp to 3.
        wait until ((ship:position - sun:position):mag > (targetBody:position - sun:position):mag).
    }

    set kuniverse:timewarp:warp to 3.
    wait until (ship:position - sun:position):mag < (targetBody:position - sun:position):mag.
    set kuniverse:timewarp:warp to 0.

    logStatus("Deorbiting").
    lock steering to ship:retrograde.
    // drop periapsis to surface
    local deorbitDV is hohmannDV1(targetBody:mu, ship:obt:semimajoraxis, targetBody:radius - 1000).
    local burnTime is maneuverTime(deorbitDV) / 2.
    add node(time:seconds + burnTime + 10, 0, 0, deorbitDV).
    unlock steering.
    executeNode().

    until (ship:bounds:bottomaltradar < 5000) {
        set kuniverse:timewarp:warp to 3.
    }

    set kuniverse:timewarp:warp to 0.

    logStatus("Killing horizontal velocity").
    lock steering to ship:srfretrograde.
    // kill all horizontal velocity
    set burnTime to maneuverTime(deorbitDV) / 2.
    add node(time:seconds + burnTime + 10, 0, 0, -ship:groundSpeed).
    executeNode().

    on (alt:radar < 1000) {
        set gear to true.
    }

    logStatus("Landing.").
    
    hoverslam().
    softdrop().

    lock throttle to 0.

    local steerLock is heading(90, 90).
    lock steering to steerLock.

    logStatus("Waiting for stability...").

    wait until ship:status = "LANDED" and abs(ship:verticalspeed) < 0.1 and abs(ship:groundSpeed) < 0.1.
    logStatus("Landed on the target!").

    kuniverse:quicksave().

    runAllExperiments().
    wait 10.
    
    collectAllScience().
    wait 10.


    logStatus("Launching from Surface").
    countdown(10).
    
    wait 0.5.
    stage.

    on (ship:bounds:bottomaltradar > 100) {
        set gear to false.
    }

    launch(30000).

    logStatus("Circularize at Apoapsis").
    circularizeAtAp().
    executeNode().
    
    wait 10.

    if (abs(ship:obt:inclination) > 1) {
        logStatus("Zeroing inclination").
        zeroInclination().
        executeNode().
    }

    logStatus("Waiting for next module").
    wait 10.
}

if ship:orbit:body:name = targetBody:name {
    logStatus("Computing exit maneuver").
    
    lock steering to ship:prograde.
    local exitDV is hohmannDV1(targetBody:mu, ship:obt:semimajoraxis, targetBody:soiradius * 1.1).
    logInfo("Exit dV: " + exitDV).

    logStatus("Waiting for proper time").
    
    until vAng(ship:position - targetBody:position, targetBody:orbit:velocity:orbit) < 10 {
        logInfo("vAng ship pos/mun vel: " + vAng(ship:position - targetBody:position, targetBody:orbit:velocity:orbit), 1).
        set kuniverse:timewarp:warp to round(vAng(ship:position - targetBody:position, targetBody:orbit:velocity:orbit) / 20, 0).
    }
    set kuniverse:timewarp:warp to 0.

    local burnTime is maneuverTime(exitDV) / 2.
    add node(time:seconds + burnTime + 10, 0, 0, exitDV).
    unlock steering.
    executeNode().

    if ship:orbit:hasnextpatch {
        
        logStatus("Dropping Periapsis").
        lock steering to ship:prograde.
        local throttleLock is 0.
        lock throttle to throttleLock.

        local targetPe is 90000.

        until vAng(ship:position - targetBody:position, targetBody:orbit:velocity:orbit) > 90 {
            logInfo("vAng ship pos/mun vel: " + vAng(ship:position - targetBody:position, targetBody:orbit:velocity:orbit), 1).
            set kuniverse:timewarp:warp to 3.
        }.
        set kuniverse:timewarp:warp to 0.

        until ship:orbit:nextpatch:periapsis < targetPe {
            
            set throttleLock to min((ship:orbit:nextpatch:periapsis - targetPe) / targetPe, 1).

            logInfo("Kerbin Pe: " + ship:orbit:nextpatch:periapsis).
        }

        lock throttle to 0.
        unlock steering.
        unlock throttle.

        logStatus("Warping to SOI").        
        
        until (eta:transition < 0) {
            autoWarp(eta:transition + time:seconds).
        }

        kuniverse:quicksave().
        
        logStatus("Waiting for next module").
        wait 10.
    } else {
        logStatus("!!!!! Didn't exit SOI !!!!!").
        wait 30.
    }
}

clearFields().

if ship:orbit:body:name = kerbin:name {

    if (ship:periapsis > 110000 or ship:apoapsis > 110000 or ship:apoapsis < 0) {

        if (ship:periapsis > 110000) {
            logStatus("Recapturing around Kerbin").
            circularizeAtPe().
            executeNode().
            
            logStatus("Moving to 90km Orbit").
            logInfo("- Changing Periapsis to 90km").
            local xferR1 is ship:orbit:semimajoraxis.
            local xferR2 is 90000 + kerbin:radius.
            local dV1 is hohmannDV1(kerbin:mu, xferR1, xferR2).
            
            add node(eta:apoapsis + time:seconds, 0, 0, dV1).
            executeNode().
        }
        
        logInfo("- Circularizing at Periapsis").
        circularizeAtPe().
        executeNode().
    }
    
    logStatus("Waiting to drop periapsis on sunny side").
    until (ship:position - sun:position):mag > (kerbin:position - sun:position):mag + kerbin:radius and vDot(ship:prograde:forevector, ship:position - sun:position) < 0 {
        logInfo("Ship2Sun - Kerbin2Sun: " + round((ship:position - sun:position):mag - ((kerbin:position - sun:position):mag + kerbin:radius), 0), 1).
        logInfo("ship:prograde * ship:position: " +  vDot(ship:prograde:forevector, (ship:position - sun:position)), 3).
    }

    logStatus("Dropping Periapsis to 20km for reentry").
    local reentryDv is hohmannDV1(kerbin:mu, ship:orbit:semimajoraxis, 20000 + kerbin:radius).
        
    local deorbitBurnTime is maneuverTime(reentryDv).
    add node(time:seconds + deorbitBurnTime / 2 + 15, 0, 0, reentryDv).
    executeNode().

    logStatus("Warping to atmosphere").

    until ship:altitude < kerbin:atm:height {
        local hDiff is ship:altitude - kerbin:atm:height.
        set kuniverse:timewarp:warp to round(min(hDiff^2.0 / 40000.0, 7), 0).
    }
    
    set kuniverse:timewarp:warp to 0.

    logStatus("Preparing for re-entry").

    stage.

    local steerLock is ship:retrograde.
    lock steering to steerLock.

    on (ship:altitude < 30000) {
        set steerLock to ship:srfretrograde.
    }.

    on (alt:radar < 5000) {
        stage.
    }.

    on (ship:velocity:surface:mag < 20) {
        unlock steering.
    }

    until ship:status = "SPLASHED DOWN" or ship:status = "LANDED" {
        set steerLock to ship:srfretrograde.
    }
}

clearFields().

logStatus("MISSION COMPLETE").
