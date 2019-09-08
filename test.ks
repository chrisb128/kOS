run once hohmann.
run once math.
run once orbit.
run once inclination.
run once rendezvous.
run once docking.
run once mission.

clearscreen.

if ship:status = "PRELAUNCH" {
    runStep(launchToOrbit(121000, true, true, true, true, 5)).
        
    kuniverse:quicksave().

    logStatus("Waiting for next module").
    wait 10.
}

local tgt is Vessel("Space Station").
set target to tgt.

if (vAng(obtNormal(ship:obt:inclination, ship:obt:lan, body), obtNormal(tgt:obt:inclination, tgt:obt:lan, body)) > 0.1) {

    logStatus("Match inclination with target").

    addMatchInclinationNode(tgt).
    executeNode().
    wait 10.

    if ((abs(ship:obt:apoapsis - tgt:obt:periapsis) / ship:obt:apoapsis) > 0.01) {
        addCircularizeNodeAtPe().
        executeNode().
        wait 10.
    }
}

until not hasNode { remove nextNode. wait 0. }

logStatus("Computing Hohmann Transfer").
addRendezvousTransferNode(tgt).
executeNode().
wait 10.

logStatus("Matching Velocity at Closest Approach").
addMatchVelocityAtClosestApproachNode(tgt).
executeNode().
wait 10.

logStatus("Matching Velocity at Closest Approach Again").
addMatchVelocityAtClosestApproachNode(tgt).
executeNode().

logStatus("Closing distance").
closeDistanceToTarget(tgt, 100).