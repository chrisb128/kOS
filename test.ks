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
sas off.

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

unlock steering.
local dockAxis is V(0,0,0)-targetDock:portFacing:forevector.
lock steering to lookDirUp(dockAxis, ship:body:position).

local dockAxisVec is vecDraw(
    shipDock:nodePosition,
    dockAxis,
    RGB(0, 0, 1), "", 3.0, true, 0.1, true, true
).
set dockAxisVec:startupdater to { return shipDock:nodePosition. }.
set dockAxisVec:vecupdater to { return dockAxis. }.

wait until vAng(ship:facing:forevector, dockAxis) < 0.1.
logInfo("Steering locked").

wait 600.