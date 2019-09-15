run once hohmann.
run once math.
run once draw.
run once inclination.
run once rendezvous.
run once docking.
run once mission.
run once optimizers.

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

if ship:status = "PRELAUNCH" {
    runStep(launchToOrbit(121000, true, true, true, true, 5)).
    
    kuniverse:quicksave().

    logStatus("Waiting for next module").
    wait 10.
}

set autoStage to false.

if (ship:obt:body:name <> minmus:name) {

    runStep(transferToSatellite(minmus, 30000)).

    kuniverse:quicksave().
}

local tgt is vessel("Minmus Station").

if tgt:position:mag > 5000 {
    autoRendezvous(tgt).
} else if tgt:position:mag > 1000 {
    closeDistanceToTarget(tgt, 150).
}
