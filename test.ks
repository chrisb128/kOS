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

ship:partstagged("vessel dock")[0]:controlFrom().

if tgt:position:mag > 500 {
    autoRendezvous(tgt).
}

autoDock(tgt:partstagged("vessel dock")[0]).