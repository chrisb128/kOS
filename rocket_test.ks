run once hohmann.
run once math.
run once draw.
run once inclination.
run once rendezvous.
run once docking.
run once mission.
run once optimizers.
run once vessel.
run once resources.

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

ship:partstagged("vesselDock")[0]:controlFrom().

if ship:status = "PRELAUNCH" {
    runStep(launchToOrbit(125000, true, true, true, true, 5)).

    kuniverse:quicksave().

    logStatus("Waiting for next module").
    wait 10.
}

lights on.

clearscreen.

if (ship:obt:body:name <> minmus:name) {
    runStep(transferToSatellite(minmus, 30000)).
}

// if (ship:obt:body:name = minmus:name and ship:status <> "LANDED" and getResourceFillRatio("ore", "minerOreTank") < 1) and not ship:controlPart:state:contains("Docked") {
//     if (abs(30000 - ship:obt:apoapsis) / 30000) > 0.05 {

//         local station is vessel("Minmus Station").
//         if (station:position:mag - station:bounds:extents < 100) {

//             logStatus("Backing up").

//             rcs on.

//             set ship:control:fore to -0.5.
//             wait until (ship:velocity:orbit - station:velocity:orbit):mag > 0.5.
//             set ship:control:fore to 0.

//             wait until station:position:mag - station:bounds:extents > 100.

//             set ship:control:fore to 0.2.
//             wait until (ship:velocity:orbit - station:velocity:orbit):mag < 0.01.
//             set ship:control:fore to 0.

//             rcs off.
//         }

//         logStatus("Dropping periapsis").
//         addSetPeriapsisNode(30000, time:seconds + 180).
//         wait 10.

//         executeNode().


//         logStatus("Circularizing").
//         addCircularizeNodeAtPe().
//         executeNode().
//     }


//     if (ship:obt:inclination > 0.1) {
//         zeroInclination().
//         wait 10.
//     }

//     logStatus("Attempting to land at minmus 9N, 176W").
//     landAt(5, -176, minmus).

//     wait 10.
// }

// if (ship:obt:body:name = minmus:name and ship:status = "LANDED") {

//     deployDrills().
//     extendRadiators().
//     wait 10.

//     startSurfaceHarvesters().

//     wait until getResourceFillRatio("ore", "minerOreTank") = 1.

//     stopSurfaceHarvesters().

//     retractRadiators().
//     retractDrills().
// }


// if (ship:obt:body:name = minmus:name and ship:status = "LANDED" and getResourceFillRatio("ore", "minerOreTank") = 1) {
//     on (ship:apoapsis > 100) {
//         gear off.
//     }

//     runStep(launchToOrbit(30000, true, true, true, true, 5)).

//     kuniverse:quicksave().
// }

set autoStage to false.


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

    kUniverse:pause().
    ////
    ////

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

// logStatus("Transferring Ore").
// wait 5.

// if (getResourceFillRatio("ore", "minerOreTank") > 0) {

//     set oreTransfer to transferAll("ore", ship:partsTagged("minerOreTank"), ship:partsTagged("stationOreTank")).
//     set oreTransfer:active to true.
//     wait 0.

//     wait until oreTransfer:status = "Transferring" or oreTransfer:status = "Failed".

//     until oreTransfer:status <> "Transferring" {
//         if (oreTransfer:status = "Failed") {
//             logInfo("Error transferring ore: " + oreTransfer:message).
//         } else {
//             logInfo("Transferred Ore: " + round(oreTransfer:transferred)).
//         }

//         wait 0.
//     }
// }

// logInfo("Transfer complete, converting to Liquid Fuel and Oxidizer.", 2).

// wait 5.

// startIsru("lf+ox").

// until getResourceFillRatio("liquidFuel", "minerFuelTank") > .9999999 {
//     logInfo("Fuel tank fill %: " + round(100*getResourceFillRatio("liquidFuel", "minerFuelTank")), 2).
//     wait 1.
// }

// stopIsru("lf+ox").

// logInfo("Refuel complete.  Undocking.", 2).

// wait 10.

// ship:controlPart:unDock().
// shutdown.
