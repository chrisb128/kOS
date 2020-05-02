run once circle.

global function createFlightPlan {
    parameter cruiseSpeed.
    parameter cruiseAltitude.
    parameter waypoints.
    parameter origin.
    parameter destination.

    return lexicon(
        "cruiseSpeed", cruiseSpeed,
        "cruiseAltitude", cruiseAltitude,
        "waypoints", waypoints,
        "origin", origin,
        "destination", destination
    ).
}

global function createWaypoint {
    parameter speed.
    parameter tgtAlt.
    parameter location.

    local this is lexicon(
        "speed", speed,
        "altitude", tgtAlt,
        "location", location).

    return this.
}

global function nextWaypoint {
    parameter prev.
    parameter head.
    parameter dist.
    parameter speed.
    parameter tgtAlt.

    return createWaypoint(speed, tgtAlt, locationAfterDistanceAtHeading(prev:location, head, dist)).
}

global function getWaypointsBetween {
    parameter start.
    parameter finish.
    parameter separation is 1000.

    local waypointLocations is computeWaypoints(start:location, finish:location, start:altitude, separation).

    local waypoints is list().
    local altitudeChange is finish:altitude - start:altitude.
    local speedChange is finish:speed - start:speed.
    from { local i is 0. }
    until (i >= waypointLocations:length)
    step { set i to i + 1. } do {
        local currentAlt is i * (altitudeChange / waypoints:length) + start:altitude.
        local currentSpeed is i * (speedChange / waypoints:length) + start:speed.

        waypoints:add(
            createWaypoint(currentSpeed, currentAlt, waypointLocations[i])
        ).
    }

    return waypoints.
}
