run once circle.
run once airplane.
run once navigator.
run once runways.
run once time.

set config:ipu to 4000.

clearscreen.

brakes on. // brakes start off, turn them on to prevent the plane from rolling on the tarmac before we're ready

local start is createWaypoint(200, 1000, locationAfterDistanceAtHeading(kscWest:end, 90, 5000)).
local initialClimb is createWaypoint(300, 5000, locationAfterDistanceAtHeading(start:location, 90, 10000)).
local levelOut is createWaypoint(300, 9000, locationAfterDistanceAtHeading(initialClimb:location, 90, 40000)).
local speedUp is createWaypoint(1200, 9000, locationAfterDistanceAtHeading(levelOut:location, 90, 250000)).

local plan is createFlightPlan(200, 200,
    list(
        start,
        initialClimb,
        levelOut,
        speedUp
    ),
    kscWest,
    dessertNorth,
    200,
    1,
    300
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

    logInfo("Current Pos: " + formatLatLng(ship:geoposition), 25).
    logInfo("Target  Pos: " + formatLatLng(nav:target), 26).
    logInfo("Target Dist: " + distanceTo(nav:target), 27).

    autopilotSetControls(nav:autopilot, nav:heading:getCurrentValue(), nav:altitude:getCurrentValue(), nav:speed:getCurrentValue()).
    wait 0.
}

logMission("FINISHED").
