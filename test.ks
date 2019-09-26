run once hohmann.
run once math.
run once draw.
run once inclination.
run once rendezvous.
run once docking.
run once mission.
run once optimizers.
run once vessel.

clearscreen.

until not hasNode {
    remove nextNode.
    wait 0.
}


local autoStage is true.

local lastStage is time:seconds.
on stageFlameout() {
    if (autoStage) {
        if (time:seconds > lastStage + 2) {
            set lastStage to time:seconds.
            stage.
            wait 1.
        }

        preserve.
    }
}
clearscreen.


if ship:status = "PRELAUNCH" {
    runStep(launchToOrbit(121000, true, true, true, true, 5)).
    
    kuniverse:quicksave().

    logStatus("Waiting for next module").
    wait 10.
}

lights on.

clearscreen.

if (ship:obt:body:name <> minmus:name) {
    runStep(transferToSatellite(minmus, 30000)).

    kuniverse:quicksave().
}

if (ship:obt:body:name = minmus:name and ship:status <> "LANDED" and getResourceFillRatio("ore") < 1) {

    if (ship:obt:inclination > 0.1) {
        zeroInclination().
        wait 10.
    }

    logStatus("Attempting to land at minmus 9N, 176W").
    landAt(5, -176, minmus).
    
    wait 10.
}



if (ship:obt:body:name = minmus:name and ship:status = "LANDED" and getResourceFillRatio("ore") < 1) {

    deployDrills().
    extendRadiators().
    wait 10.

    startSurfaceHarvesters().

    wait until getResourceFillRatio("ore") = 1.

    stopSurfaceHarvesters().

    retractRadiators().
    retractDrills().
}


if (ship:obt:body:name = minmus:name and ship:status = "LANDED" and getResourceFillRatio("ore") = 1) {
    on (ship:apoapsis > 100) {
        gear off.
    }

    runStep(launchToOrbit(30000, true, true, true, true, 5)).
    
    kuniverse:quicksave().
}

set autoStage to false.

ship:partstagged("vesselDock")[0]:controlFrom().

if (ship:obt:body:name = minmus:name and not ship:controlPart:state:contains("Docked")) {

    local tgt is vessel("Minmus Station").

    if tgt:position:mag > 10000 {
        logStatus("Rendezvous with Minmus Station").
        autoRendezvous(tgt).
    } else if tgt:position:mag > 500 {
        
        logStatus("Near Minmus Station, closing distance.").
        closeDistanceToTarget(tgt, 150).
    }

    kuniverse:quicksave().


    local tgtDocks is list().

    logStatus("Locating open dock").
    for d in tgt:partstagged("vesselDock") {
        if not d:state:contains("Docked") {
            tgtDocks:add(d).
        }
    }

    wait 10.
    if tgtDocks:length > 0 {
        logStatus("Auto-docking").
        autoDock(tgtDocks[0], true).
    } else {
        print "!!! NO OPEN DOCKS !!!".
    }
}