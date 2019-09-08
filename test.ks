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

rcs on.

local targetDock is tgt:partstagged("vessel dock")[0].
local shipDock is ship:partstagged("vessel dock")[0].

local vecToPort is vecDraw(
    shipDock:nodePosition, 
    targetDock:nodePosition,
    RGB(0.5, 0.5, 0.5), "", 1.0, true, 0.1, true, true
).

set vecToPort:startupdater to { return shipDock:nodePosition. }.
set vecToPort:vecupdater to { return targetDock:nodePosition. }.

local shipDockVec is vecDraw(
    shipDock:nodePosition,
    shipDock:portFacing:forevector,
    RGB(1, 0, 0), "", 3.0, true, 0.1, true, true
).
set shipDockVec:startupdater to { return shipDock:nodePosition. }.
set shipDockVec:vecupdater to { return shipDock:portFacing:forevector. }.

local targetDockVec is vecDraw(
    targetDock:nodePosition,
    targetDock:portFacing:forevector,
    RGB(0, 0, 1), "", 3.0, true, 0.1, true, true
).
set targetDockVec:startupdater to { return targetDock:nodePosition. }.
set targetDockVec:vecupdater to { return targetDock:portFacing:forevector. }.

logInfo("Dock/Ship Ang: " + vAng(targetDock:portFacing:forevector, shipDock:portFacing:forevector), 3).