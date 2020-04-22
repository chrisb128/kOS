run once navigator.
run once energy.
run once runways.
run once attitude.
run once airplane.

print "Press any key to start".
//terminal:input:getchar().
clearscreen.

if (ship:maxthrust <= 0) {
    stage.
}

local startPt is createWaypoint(180, 3000, locationAfterDistanceAtHeading(kscWest:end, 90, 20000)).
local legAxis is locationAfterDistanceAtHeading(startPt:location, 90, 20000).
local turnNorth is createWaypoint(180, 3000, locationAfterDistanceAtHeading(legAxis, 0, 30000)).
local turnBack is createWaypoint(180, 3000, locationAfterDistanceAtHeading(legAxis, 90, 10000)).

local plan is createFlightPlan(180, 3000,
    list(
        startPt,
        turnNorth,
        turnBack
    ),
    kscWest,
    kscEast
).

local pilot is initAutopilot(plan).
pilot:initLogs().

lock throttle to pilot:throttle.

set pilot:nav:mode to "approach".

until false {
    pilot:drive().
    wait 0.
}
