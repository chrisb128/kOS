// imports
set config:ipu to 2000.
run once logging.
run once math.
run once executenode.   
run once circularize.
run once hohmann.
run once inclination.
run once hoverslam.
run once warp.
run once science.
run once time.
run once orbit.
run once mission.

declare targetBody is minmus.
declare parentBody is targetBody:orbit:body.


local function clearFields {
    clearscreen.
    logMission("== going to minmus == v4").
}

clearFields().

if ship:status = "PRELAUNCH" {
    runStep(launchToOrbit(90000, true, 10, true, true, true)).
    
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

    matchInclination(lexicon("targetBody", targetBody)).

    logStatus("Waiting for next module").
    wait 10.
}

clearFields().

if ship:orbit:body:name = parentBody:name {
    
    transferToSatellite(lexicon("targetBody", targetBody, "targetAp", 30000, "autoWarpToSoi", true)).

    kuniverse:quicksave().
    
    logStatus("Waiting for next module").
    wait 10.
}

clearFields().

if ship:orbit:body:name = targetBody:name and ship:status <> "LANDED" {

    logStatus("Waiting to deorbit on sunny side").
    if ((ship:position - sun:position):mag < (targetBody:position - sun:position):mag) {
        set kuniverse:timewarp:warp to 5.
        wait until ((ship:position - sun:position):mag > (targetBody:position - sun:position):mag).
    }

    set kuniverse:timewarp:warp to 4.
    wait until (ship:position - sun:position):mag < (targetBody:position - sun:position):mag.
    set kuniverse:timewarp:warp to 0.

    landSomewhere().

    kuniverse:quicksave().
    logStatus("Waiting for next module").
    wait 10.
}

if ship:status = "LANDED" and ship:body:name = targetBody:name {

    // check if science already run?
    runAllExperiments().
    wait 10.
        
    // check if science already collected?
    collectAllScience().
    wait 10.

    on (ship:bounds:bottomaltradar > 100) {
        set gear to false.
    }
    
    local returnEngine is ship:partstagged("returnEngine")[0].
    until (returnEngine:ignition) {
        wait 0.5.
        stage.
    }

    runStep(launchToOrbit(30000, false, 0, false, false, false, 0)).

    if (abs(ship:obt:inclination) > 1) {
        zeroInclination().
        wait 1.
    }

    logStatus("Waiting for next module").
    wait 10.
}

if ship:orbit:body:name = targetBody:name {
    returnFromSatellite(90000).

    kuniverse:quicksave().
    
    logStatus("Waiting for next module").
    wait 10.
}

clearFields().

if ship:orbit:body:name = kerbin:name {

    if (ship:periapsis > 110000 or ship:apoapsis > 110000 or ship:apoapsis < 0) {

        if (ship:periapsis > 110000) {
            logStatus("Recapturing around Kerbin").
            addCircularizeNodeAtPe().
            executeNode().
            
            logStatus("Moving to 90km Orbit").
            logInfo("- Changing Periapsis to 90km").
            local dV1 is -hohmannDV2(kerbin:mu, 90000 + kerbin:radius, ship:orbit:semimajoraxis).
            
            add node(eta:apoapsis + time:seconds, 0, 0, dV1).
            executeNode().
            wait 1.
        }
        
        logInfo("- Circularizing at Periapsis").
        addCircularizeNodeAtPe().
        executeNode().
    }
    
    if (abs(ship:obt:inclination) > 1) {
        zeroInclination().
    }
    
    logStatus("Waiting to drop periapsis on sunny side").
    until (ship:position - sun:position):mag > (kerbin:position - sun:position):mag + kerbin:radius and vDot(ship:prograde:forevector, ship:position - sun:position) < 0 {
        logInfo("Ship2Sun - Kerbin2Sun: " + round((ship:position - sun:position):mag - ((kerbin:position - sun:position):mag + kerbin:radius), 0), 1).
        logInfo("ship:prograde * ship:position: " +  vDot(ship:prograde:forevector, (ship:position - sun:position)), 3).
    }

    logStatus("Dropping Periapsis to 20km for reentry").
    local reentryDv is -hohmannDV2(kerbin:mu, 20000 + kerbin:radius, ship:orbit:semimajoraxis).
        
    local deorbitBurnTime is maneuverTime(reentryDv / 2).
    add node(time:seconds + deorbitBurnTime + 15, 0, 0, reentryDv).
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
