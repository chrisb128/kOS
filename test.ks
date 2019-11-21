run once circle.
run once airplane.
run once navigator.
run once runways.
run once time.

set config:ipu to 2000.

clearscreen.

brakes on. // brakes start off, turn them on to prevent the plane from rolling on the tarmac before we're ready

local plan is createFlightPlan(150, 1500,
    list(
        createWaypoint(150, 1500, dessertNorth:approach)
    ),
    dessertNorth,
    150,
    10,
    600
).

countdown(3).


until ship:maxThrust > 0 {
    stage.
}

local nav is initNavigator(plan).
set nav:mode to "ascend".

until false {

    navigatorUpdateFlightMode(nav).
    if (nav:mode = "idle") {
        break.
    }
    navigatorSetWaypoint(nav).
    navigatorSetAutopilotParams(nav).
    navigatorSetTargets(nav).

    navigatorSetShipControls(nav).

    logMission("Mode: " + nav:mode).

    logInfo("Current Pos: " + formatLatLng(ship:geoposition), 20).
    logInfo("Target  Pos: " + formatLatLng(nav:target), 21).
    logInfo("Target Dist: " + distanceTo(nav:target), 22).

    autopilotSetControls(nav:autopilot, nav:speed, nav:altitude, nav:heading).
    wait 0.
}

logMission("FINISHED").
